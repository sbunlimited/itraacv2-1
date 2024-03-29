use iTRAAC
go


/*************** tblTaxFormPackages */
ALTER TABLE tblTaxFormPackages ADD SponsorClientGUID uniqueidentifier NULL --store the sponsor at the time of _SALE_ because the tblClients sponsor StatusFlag actually does vary over time fairly often (e.g. when someone gets divorced and then remarried to a new sponsor)
	                                             --this is really subtle but crucial... "sponsor" is sort of just a flag that can hop around
	                                             --but whoever happens to wear the hat at the time of form sale becomes responsible for *THOSE* forms forever more
	                                             --*even* if they lose their sponsorship status... kinda wild
	                                             
--nixing this concept, duty station is the only thing that's printed and it's well known that would change over time so an auditor couldn't really fault us for that difference
--ALTER TABLE tblTaxFormPackages ADD SponsorGUID UNIQUEIDENTIFIER -- this saves the "Address" originally sold to forevermore, we'll ebb & flow with deactivating Sponsor records when households move and fire up new ones, this pointer will provide a "previous addresses" type list

-- this *should* be the the house member who walked in and physically bought the forms, selected directly from the Members grid on Sponsor tab
-- but since v1 also uses this slot (via ClientID) to decide whether to print dependents on the form it basically degrades to that purpose until we fully cutover (it will happen)
ALTER TABLE tblTaxFormPackages ADD AuthorizedDependentClientGUID uniqueidentifier NULL 

ALTER TABLE tblTaxFormPackages ADD SellUserGUID uniqueidentifier NULL -- SellUserGUID replaces AgentID
ALTER TABLE tblTaxFormPackages ADD ExpirationDate datetime NULL -- explicit ExpirationDate just in case the 2yrs rule ever changes to something else
ALTER TABLE tblTaxFormPackages ADD TaxOfficeID INT NULL -- explicit TaxOfficeID replaces dependency on AgentID, just makes many queries and reports easier

ALTER TABLE tblTaxFormPackages ALTER COLUMN PackageCode VARCHAR(14)
--******* needs "TaxFormPackage - Duplicate PackageCode Fix.sql" first
DROP INDEX tblTaxFormPackages.ix_PackageCode
CREATE UNIQUE INDEX ix_PackageCode ON tblTaxFormPackages (PackageCode ASC)


ALTER TABLE tblTaxFormPackages ADD OriginalSponsorName varchar(100)
ALTER TABLE tblTaxFormPackages ADD OriginalDependentName varchar(100)

drop index tblTaxFormPackages.tblTaxFormPackages51
DROP INDEX tblTaxFormPackages.PK16
drop index tblTaxFormPackages.IX_tblTaxFormPackages
CREATE INDEX ix_PackageID ON tblTaxFormPackages (PackageID, PurchaseDate)
ALTER TABLE tblTaxFormPackages ADD CONSTRAINT pk_RowGUID PRIMARY KEY CLUSTERED (RowGUID)

drop index tblTaxFormPackages.idxPurchaseDate
drop index tblTaxFormPackages.ix_PurchaseDate
CREATE INDEX ix_PurchaseDate ON tblTaxFormPackages (PurchaseDate, TaxOfficeID, PackageCode, RowGUID) -- for obtaining the latest PackageCode in TaxFormPackage_new

ALTER TABLE tblTaxFormPackages ADD CONSTRAINT DF_tblTaxFormPackages_RowGUID DEFAULT (NEWSEQUENTIALID()) FOR ROWGUID

DROP INDEX tblTaxFormPackages.ix_TaxOfficeID
CREATE INDEX ix_TaxOfficeID ON tblTaxFormPackages (TaxOfficeID) INCLUDE (RowGUID)

DROP INDEX tblTaxFormPackages.index_2016726237
--DROP INDEX tblTaxFormPackages.ix_SponsorClientGUID
CREATE INDEX ix_SponsorClientGUID ON tblTaxFormPackages (SponsorClientGUID) INCLUDE (RowGUID)

-- wait on these FK's until after v1 is completely flushed out
-- ALTER TABLE tblTaxForms DROP CONSTRAINT FK_tblTaxForms_tblTaxFormPackages
-- ALTER TABLE [dbo].[tblTaxForms] WITH CHECK ADD CONSTRAINT [FK_tblTaxForms_tblTaxFormPackages] FOREIGN KEY([PackageGUID])
--   REFERENCES [dbo].[tblTaxFormPackages] ([RowGUID])


------ _ -------------------------------- _ ---------- _ ----- _ ----------------------------------- _ -----
--    / \      ____   _       _____      / \          / /     | |      _   _  _____           __    | |  
--   / ^ \    / __ \ | |     |  __ \    / ^ \        / /      | |     | \ | ||  ___|\        / /    | |  
--  /_/ \_\  | |  | || |     | |  | |  /_/ \_\      / /     __| |__   |  \| || |__ \ \  /\  / /   __| |__
--    | |    | |  | || |     | |  | |    | |       / /      \ \ / /   |     ||  __| \ \/  \/ /    \ \ / /
--    | |    | |__| || |____ | |__| |    | |      / /        \ V /    | |\  || |____ \  /\  /      \ V / 
--    |_|     \____/ |______||_____/     |_|     /_/          \_/     |_| \_||______| \/  \/        \_/  
------------------------------------------------------------------------------------------------------------

-- TODO: union tblTaxFormPackages.Remarks to TaxForm_Remarks
--SELECT Remarks, PurchaseDate FROM tblTaxFormPackages WHERE Remarks IS NOT NULL ORDER BY PurchaseDate DESC

