CREATE TABLE itraacv2.dbo.ClientPreviousSponsor (ClientGUID UNIQUEIDENTIFIER NOT NULL, SponsorGUID UNIQUEIDENTIFIER NOT NULL, CreateDate DATETIME NOT NULL DEFAULT(GETDATE()))