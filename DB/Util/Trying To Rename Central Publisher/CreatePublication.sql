-- brent: see "Rename SQL Server.sql" for the commands to change to the standardized sql server name "iTRAAC_Central" vs whatever the actual machine name happens to be
-- this buys us the flexibility to migrate to another central server w/o having to reconnect all of the subscribers (which requires a 2GB data push over slow/unreliable net links, among other things)

/****** Scripting replication configuration. Script Date: 1/21/2012 1:22:54 PM ******/
/****** Please Note: For security reasons, all password parameters were scripted with either NULL or an empty string. ******/

/****** Installing the server as a Distributor. Script Date: 1/21/2012 1:22:54 PM ******/
use master
--orig from script: exec sp_adddistributor @distributor = N'IMCMEUROA4VDB03', @password = N''
exec sp_adddistributor @distributor = N'iTRAAC_Central', @password = N'' -- i don't see the password actually mattering anywhere yet, but the sproc requires it... i'm wondering if we're supposed to provide 'local' as the server name... i didn't try that yet and it's working this way so far
GO
exec sp_adddistributiondb @database = N'distribution', @data_folder = N'E:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\Data', @log_folder = N'E:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\Data', @log_file_size = 2, @min_distretention = 0, @max_distretention = 72, @history_retention = 48, @security_mode = 1
GO

use [distribution] 
if (not exists (select * from sysobjects where name = 'UIProperties' and type = 'U ')) 
	create table UIProperties(id int) 
if (exists (select * from ::fn_listextendedproperty('SnapshotFolder', 'user', 'dbo', 'table', 'UIProperties', null, null))) 
	EXEC sp_updateextendedproperty N'SnapshotFolder', N'E:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\ReplData', 'user', dbo, 'table', 'UIProperties' 
else 
	EXEC sp_addextendedproperty N'SnapshotFolder', N'E:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\ReplData', 'user', dbo, 'table', 'UIProperties'
GO

--orig from script: exec sp_adddistpublisher @publisher = N'iTRAAC_Central', @distribution_db = N'distribution', @security_mode = 0, @login = N'sa', @password = N'', @working_directory = N'E:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\ReplData', @trusted = N'false', @thirdparty_flag = 0, @publisher_type = N'MSSQLSERVER'
-- changed @security_mode to 1
exec sp_adddistpublisher @publisher = N'iTRAAC_Central', @distribution_db = N'distribution', @security_mode = 1, @working_directory = N'E:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\ReplData', @thirdparty_flag = 0, @publisher_type = N'MSSQLSERVER'
GO

use [repltest]
exec sp_replicationdboption @dbname = N'repltest', @optname = N'merge publish', @value = N'true'
GO
-- Adding the merge publication
use [repltest]
exec sp_addmergepublication @publication = N'repltest', @description = N'Merge publication of database ''repltest'' from Publisher ''iTRAAC_Central''.', @sync_mode = N'native', @retention = 14, @allow_push = N'true', @allow_pull = N'true', @allow_anonymous = N'true', @enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'true', @compress_snapshot = N'false', @ftp_port = 21, @allow_subscription_copy = N'false', @add_to_active_directory = N'false', @dynamic_filters = N'false', @conflict_retention = 14, @keep_partition_changes = N'false', @allow_synctoalternate = N'false', @max_concurrent_merge = 0, @max_concurrent_dynamic_snapshots = 0, @use_partition_groups = null, @publication_compatibility_level = N'100RTM', @replicate_ddl = 1, @allow_subscriber_initiated_snapshot = N'false', @allow_web_synchronization = N'false', @allow_partition_realignment = N'true', @retention_period_unit = N'days', @conflict_logging = N'both', @automatic_reinitialization_policy = 0
GO

-- orig: exec sp_addpublication_snapshot @publication = N'repltest', @frequency_type = 4, @frequency_interval = 14, @frequency_relative_interval = 1, @frequency_recurrence_factor = 0, @frequency_subday = 1, @frequency_subday_interval = 5, @active_start_time_of_day = 500, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @job_login = null, @job_password = null, @publisher_security_mode = 0, @publisher_login = N'sqlreplication', @publisher_password = N''
-- changed publisher_security_mode to 1
exec sp_addpublication_snapshot @publication = N'repltest', @frequency_type = 4, @frequency_interval = 14, @frequency_relative_interval = 1, @frequency_recurrence_factor = 0, @frequency_subday = 1, @frequency_subday_interval = 5, @active_start_time_of_day = 500, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @job_login = null, @job_password = null, @publisher_security_mode = 1 --, @publisher_login = N'sqlreplication', @publisher_password = N''


use [repltest]
exec sp_addmergearticle @publication = N'repltest', @article = N'Table_1', @source_owner = N'dbo', @source_object = N'Table_1', @type = N'table', @description = null, @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000010C034FD1, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, @column_tracking = N'false', @subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 1, @allow_interactive_resolver = N'false', @fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 0, @delete_tracking = N'true', @compensate_for_errors = N'false', @stream_blob_columns = N'false', @partition_options = 0
-- Warning: To allow replication of FILESTREAM data to perform optimally and reduce memory utilization, the 'stream_blob_columns' property has been set to 'true'.  To force FILESTREAM table articles to not use blob streaming, use sp_changemergearticle to set 'stream_blob_columns' to 'false'.
GO







EXEC sp_addmergesubscription 
  @publication = 'repltest', 
  @subscriber = 'mwr-tro-hd\mssql2008', 
  @subscriber_db = 'repltest', 
  @subscription_type = 'push',
  @subscriber_security_mode = 0,
  @subscriber_login =  'sa',
  @subscriber_password = 'annoying104'    
