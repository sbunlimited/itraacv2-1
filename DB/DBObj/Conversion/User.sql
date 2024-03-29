USE iTRAAC
go

/*************** tblUsers */
ALTER TABLE tblUsers ADD CreateDate DATETIME not null DEFAULT(GETDATE())

ALTER TABLE tblUsers ADD Active BIT NOT NULL DEFAULT(1) -- defaulting this to 1 for V1's sake
ALTER TABLE tblUsers ALTER COLUMN DSNPhone VARCHAR(8)

-- ***** run User_cleanup_dupes.sql first in order to create the unique key
-- let's do some kind of cleaup on this *after* we finish migrating to sql 2008 :)
--CREATE UNIQUE NONCLUSTERED INDEX [User Name] ON tblUsers (FName, LName)

ALTER TABLE tblUsers DROP CONSTRAINT DF_tblUsers_RowGUID
ALTER TABLE tblUsers ADD DEFAULT (NewSequentialID()) FOR RowGUID
ALTER TABLE tblUsers ALTER COLUMN [Password] VARCHAR(255) NULL
ALTER TABLE tblUsers ADD DEFAULT (1) FOR UserLevel
ALTER TABLE tblUsers ADD DEFAULT (0) FOR StatusFlags

------ _ -------------------------------- _ ---------- _ ----- _ ----------------------------------- _ -----
--    / \      ____   _       _____      / \          / /     | |      _   _  _____           __    | |  
--   / ^ \    / __ \ | |     |  __ \    / ^ \        / /      | |     | \ | ||  ___|\        / /    | |  
--  /_/ \_\  | |  | || |     | |  | |  /_/ \_\      / /     __| |__   |  \| || |__ \ \  /\  / /   __| |__
--    | |    | |  | || |     | |  | |    | |       / /      \ \ / /   |     ||  __| \ \/  \/ /    \ \ / /
--    | |    | |__| || |____ | |__| |    | |      / /        \ V /    | |\  || |____ \  /\  /      \ V / 
--    |_|     \____/ |______||_____/     |_|     /_/          \_/     |_| \_||______| \/  \/        \_/  
------------------------------------------------------------------------------------------------------------

