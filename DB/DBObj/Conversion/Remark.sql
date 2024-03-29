USE iTRAAC
go

/*************** tblRemarks */

ALTER TABLE tblRemarks ADD FKRowGUID UNIQUEIDENTIFIER NULL
ALTER TABLE tblRemarks ADD CreateDate DATETIME DEFAULT(GETDATE())
  
ALTER TABLE tblRemarks DROP CONSTRAINT PK_tblRemarks
CREATE UNIQUE INDEX PK_tblRemarks ON tblRemarks (RemarksID)

DROP INDEX tblRemarks.ix_clustered

-- for Sponsor_Remarks proc
CREATE CLUSTERED INDEX ix_FKRowGUID ON tblRemarks (FKRowGUID, TableID)

ALTER TABLE tblRemarks  ADD CONSTRAINT DF_tblRemarks_RowGUID DEFAULT (NEWSEQUENTIALID()) FOR ROWGUID

ALTER TABLE tblRemarks ALTER COLUMN Title VARCHAR(50) NULL

ALTER TABLE tblRemarks ALTER COLUMN Remarks VARCHAR(942) NULL
ALTER TABLE tblRemarks ADD CONSTRAINT Remarks_TypeOrRemarks_Required CHECK (ABS(RemType) > 3 OR Remarks IS NOT NULL)

ALTER TABLE tblRemarks ADD CreateAgentGUID UNIQUEIDENTIFIER 
ALTER TABLE tblRemarks ADD LastAgentGUID UNIQUEIDENTIFIER 
ALTER TABLE tblremarks ALTER COLUMN LastUpdate DATETIME NULL
ALTER TABLE tblRemarks ADD DeleteReason varchar(200)
ALTER TABLE tblRemarks ADD AlertResolved varchar(200)

------ _ -------------------------------- _ ---------- _ ----- _ ----------------------------------- _ -----
--    / \      ____   _       _____      / \          / /     | |      _   _  _____           __    | |  
--   / ^ \    / __ \ | |     |  __ \    / ^ \        / /      | |     | \ | ||  ___|\        / /    | |  
--  /_/ \_\  | |  | || |     | |  | |  /_/ \_\      / /     __| |__   |  \| || |__ \ \  /\  / /   __| |__
--    | |    | |  | || |     | |  | |    | |       / /      \ \ / /   |     ||  __| \ \/  \/ /    \ \ / /
--    | |    | |__| || |____ | |__| |    | |      / /        \ V /    | |\  || |____ \  /\  /      \ V / 
--    |_|     \____/ |______||_____/     |_|     /_/          \_/     |_| \_||______| \/  \/        \_/  
------------------------------------------------------------------------------------------------------------

