USE [iTRAAC]
GO
/****** Object:  StoredProcedure [dbo].[cp_parmsel_Poll_Session]    Script Date: 01/25/2012 11:02:08 ******/

/*
declare @p2 int
set @p2=NULL
declare @p3 int
set @p3=NULL
declare @p4 int
set @p4=NULL
exec cp_parmsel_Poll_Session2 290000177,@p2 output,@p3 output,@p4 output
select @p2, @p3, @p4
*/

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

ALTER PROCEDURE [dbo].[cp_parmsel_Poll_Session]
    
    @SessionID INT,
    @SessionState INT OUTPUT,
    @LoginMode INT OUTPUT,
    @DBStatusFlags INT OUTPUT

AS

SET NOCOUNT ON

DECLARE @LogOut DATETIME

DECLARE @LogoutRequest INT
DECLARE @LoginExclusive INT
DECLARE @IsExclusiveLogin INT
DECLARE @EndBusinessDaySchd DATETIME
DECLARE @NoNewPackageFlag INT 

SET @LogoutRequest = 1
SET @LoginExclusive = 8
SET @IsExclusiveLogin = 268435456

/*
Public Enum DBStatusFlags
    dbfLogoutRequest = 1
    dbfNoNewPackages = 2
    dbfLoginManagerOnly = 4
    dbfLoginExclusive = 8
    dbfLogoutRequestSession = 16
    dbfWarnNoNewPackages = 32
    dbfNewPackageInProgress = 64
    dbfAUTO_LIFT_RESTRICTIONS_NEXTDAY = 4096
    dbfIsExclusiveLogin = 268435456
End Enum
*/

/******************************************
 Work on @SessionState output parameter
******************************************/
-- Grab the logout datetime
SELECT @LogOut=EventDateTime FROM ifnSessions(2) WHERE SessionID=@SessionID

-- If no logout found, check that the login is within 12 hrs
IF @LogOut IS NULL
    SELECT @SessionState=
        CASE WHEN DATEDIFF(hh, EventDateTime, GETDATE()) < 12 THEN 
            1 -- Session OPEN
        ELSE
            2 -- Session EXPIRED
        END
    FROM ifnSessions(1) WHERE SessionID=@SessionID

ELSE
    SELECT @SessionState=0 -- Session CLOSED


/******************************************
 Get the @LoginMode and @DBStatusFlags 
 output parameters
******************************************/
SELECT TOP 1 
    @LoginMode=LoginMode, 
    @DBStatusFlags = StatusFlags, 
    @EndBusinessDaySchd = EndBusinessDaySchd
FROM tblControlLocal



/******************************************
 Determine the status of the NoNewPackage
 flag bit
******************************************/
-- If NoNewPackages BIT is set, remove it if the max package date is not today's date
IF @DBStatusFlags&2=2 BEGIN
    IF (
        SELECT TOP 1 
        CASE 
            WHEN 
                CONVERT(CHAR(10), TFP.PurchaseDate, 20) < 
                CONVERT(CHAR(10), GETDATE(), 20) 
            THEN 1 ELSE 0 
        END
        FROM tblTaxFormPackages TFP
        INNER JOIN tblTaxFormAgents A ON TFP.AgentID = A.AgentID
        INNER JOIN tblControlLocal CL ON A.TaxOfficeID = CL.TaxOfficeID
        ORDER BY TFP.PurchaseDate DESC
        ) = 1 BEGIN
            -- Remove WarnNoNewPackages BIT
            IF @DBStatusFlags&32=32 
                SET @DBStatusFlags=@DBStatusFlags^32
            -- Remove NoNewPackages BIT
            SET @DBStatusFlags=@DBStatusFlags^2
            UPDATE tblControlLocal SET StatusFlags=@DBStatusFlags
    END
END

-- If NoNewPackages BIT is NOT set, is it time to set it?
IF @DBStatusFlags&2=0 BEGIN
    SELECT @NoNewPackageFlag =
        CASE -- Is the current time beyond the scheduled end of business day time?
            WHEN 
                CONVERT(VARCHAR(8), GETDATE(), 108)>=CONVERT(VARCHAR(8), @EndBusinessDaySchd, 108) 
            THEN 
                2 -- New Package creation no longer allowed for the day
            ELSE
                CASE -- Is the current time within N minutes of the scheduled end of business day time?
                    WHEN 
                        CONVERT(VARCHAR(8), GETDATE(), 108)>=CONVERT(VARCHAR(8), DATEADD(mi, -15, @EndBusinessDaySchd), 108) 
                    THEN 
                        32 -- New Package creation OK, but warn that about to expire
                    ELSE
                        0 -- New Package creation OK
                END
        END
    FROM tblControlLocal
    --PRINT CHAR(13)+'@DBStatusFlags: '+CONVERT(VARCHAR(10), @DBStatusFlags)
    --PRINT CHAR(13)+'@NoNewPackageFlag: '+CONVERT(VARCHAR(10), @NoNewPackageFlag)

    IF @NoNewPackageFlag = 2 BEGIN
        IF @DBStatusFlags&2=0 BEGIN
            -- Remove WarnNoNewPackages BIT
            IF @DBStatusFlags&32=32 
          SET @DBStatusFlags=@DBStatusFlags^32
            -- Add NoNewPackages BIT
            SET @DBStatusFlags=@DBStatusFlags|2
            UPDATE tblControlLocal SET StatusFlags=@DBStatusFlags
        END
    
    END ELSE IF @NoNewPackageFlag = 32 BEGIN
        IF @DBStatusFlags&32=0 BEGIN
            -- Add WarnNoNewPackages BIT
            SET @DBStatusFlags=@DBStatusFlags|32
            UPDATE tblControlLocal SET StatusFlags=@DBStatusFlags
        END

    END ELSE IF @NoNewPackageFlag = 0 BEGIN
        IF @DBStatusFlags&32=32 OR @DBStatusFlags&2=2 BEGIN
            -- Remove WarnNoNewPackages BIT
            IF @DBStatusFlags&32=32 
                SET @DBStatusFlags=@DBStatusFlags^32
            -- Remove NoNewPackages BIT
            IF @DBStatusFlags&2=2 
                SET @DBStatusFlags=@DBStatusFlags^2
            UPDATE tblControlLocal SET StatusFlags=@DBStatusFlags
        END
    END
END
-- PRINT CHAR(13)+'@DBStatusFlags: '+CONVERT(VARCHAR(10), @DBStatusFlags)



/******************************************
 Determine the status of the Explicit
 flag bit
******************************************/
SET @DBStatusFlags=@DBStatusFlags|dbo.IsSessionExplicitLogOutReq(@SessionID)

-- If this session was the one that set the logout flag, then
-- remove the logout flag from the return value
IF @DBStatusFlags&@LogoutRequest=@LogoutRequest AND @SessionID=(SELECT LogOutBySessionID FROM tblControlLocal)
    SET @DBStatusFlags=@DBStatusFlags^@LogoutRequest


IF @LoginMode IS NULL SET @LoginMode=-1
IF @DBStatusFlags IS NULL SET @DBStatusFlags=4096--1
IF @SessionState IS NULL SET @SessionState=-1

IF @DBStatusFlags&@LoginExclusive=@LoginExclusive BEGIN
    IF dbo.GetLoginCount(GetDate())=1 SET @DBStatusFlags=@DBStatusFlags|@IsExclusiveLogin
END

--SET @dbstatusflags = 0

RETURN 0
--SELECT @SessionState SessionState, @LoginMode LoginMode, @DBStatusFlags DBStatusFlags, @EndBusinessDay EndBusinessDay

