Use RefinedStackDB;

CREATE TABLE Clients (
    ClientID INT IDENTITY(1,1) PRIMARY KEY,
    FullName NVARCHAR(255) NOT NULL,
    Email NVARCHAR(255) UNIQUE NOT NULL,
    PasswordHash NVARCHAR(512) NOT NULL, -- Hashed password
    EncryptedPaymentInfo VARBINARY(MAX), -- Encrypted data
    CreatedAt DATETIME DEFAULT GETDATE()
);

CREATE TABLE Products (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(255) NOT NULL,
    Description TEXT,
    Status VARCHAR(50) CHECK (Status IN ('Development', 'Testing', 'Deployed')),
    ClientID INT FOREIGN KEY REFERENCES Clients(ClientID) ON DELETE CASCADE,
    CreatedAt DATETIME DEFAULT GETDATE()
);

CREATE TABLE AccessLogs (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    ClientID INT FOREIGN KEY REFERENCES Clients(ClientID) ON DELETE CASCADE,
    Action NVARCHAR(255) NOT NULL,
    Timestamp DATETIME DEFAULT GETDATE(),
    IPAddress NVARCHAR(50) NOT NULL
);

CREATE TABLE Roles (
    RoleID INT IDENTITY(1,1) PRIMARY KEY,
    RoleName NVARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE ClientRoles (
    ClientID INT FOREIGN KEY REFERENCES Clients(ClientID) ON DELETE CASCADE,
    RoleID INT FOREIGN KEY REFERENCES Roles(RoleID) ON DELETE CASCADE,
    PRIMARY KEY (ClientID, RoleID)
);

CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'StrongPassword123!';
CREATE CERTIFICATE RefinedStackCert WITH SUBJECT = 'ClientDataProtection';
CREATE SYMMETRIC KEY RefinedStackKey  
WITH ALGORITHM = AES_256  
ENCRYPTION BY CERTIFICATE RefinedStackCert;

OPEN SYMMETRIC KEY RefinedStackKey DECRYPTION BY CERTIFICATE RefinedStackCert;
UPDATE Clients 
SET EncryptedPaymentInfo = EncryptByKey(Key_GUID('RefinedStackKey'), 'SensitivePaymentData');
CLOSE SYMMETRIC KEY RefinedStackKey;

OPEN SYMMETRIC KEY RefinedStackKey DECRYPTION BY CERTIFICATE RefinedStackCert;
SELECT FullName, Email, 
       CONVERT(NVARCHAR, DecryptByKey(EncryptedPaymentInfo)) AS DecryptedPaymentInfo
FROM Clients;
CLOSE SYMMETRIC KEY RefinedStackKey;

CREATE ROLE SecurityAdmin;

GRANT SELECT, INSERT, UPDATE, DELETE ON Clients TO SecurityAdmin;

CREATE LOGIN SecureUser WITH PASSWORD = 'SecurePass123!';
CREATE USER SecureUser FOR LOGIN SecureUser;
ALTER ROLE SecurityAdmin ADD MEMBER SecureUser;

SELECT SERVERPROPERTY('Edition');

USE RefinedStackDB;
GO

CREATE TABLE FailedLoginAttempts (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    LoginTime DATETIME DEFAULT GETDATE(),
    HostName NVARCHAR(255),
    LoginName NVARCHAR(255),
    ClientIPAddress NVARCHAR(255)
);
GO

INSERT INTO FailedLoginAttempts (HostName, LoginName, ClientIPAddress)
SELECT 
    HOST_NAME(), 
    SUSER_NAME(), 
    (SELECT client_net_address FROM sys.dm_exec_connections WHERE session_id = @@SPID);

	INSERT INTO Clients (FullName, Email, PasswordHash)
VALUES 
('Alice Johnson', 'alice@example.com', HASHBYTES('SHA2_256', 'AlicePassword123')),
('Bob Smith', 'bob@example.com', HASHBYTES('SHA2_256', 'BobSecurePass456')),
('Charlie Brown', 'charlie@example.com', HASHBYTES('SHA2_256', 'CharlieSecret789'));

INSERT INTO Products (Name, Description, Status, ClientID)
VALUES 
('Product A', 'AI-powered analytics tool', 'Development', 1),
('Product B', 'Cloud storage solution', 'Testing', 2),
('Product C', 'E-commerce platform', 'Deployed', 3);

OPEN SYMMETRIC KEY RefinedStackKey DECRYPTION BY CERTIFICATE RefinedStackCert;

UPDATE Clients 
SET EncryptedPaymentInfo = EncryptByKey(Key_GUID('RefinedStackKey'), CONVERT(VARBINARY, 'CreditCard1234'))
WHERE Email = 'alice@example.com';

CLOSE SYMMETRIC KEY RefinedStackKey;

SELECT ClientID, FullName, Email, PasswordHash, EncryptedPaymentInfo FROM Clients;

OPEN SYMMETRIC KEY RefinedStackKey DECRYPTION BY CERTIFICATE RefinedStackCert;

SELECT FullName, Email, 
       CONVERT(NVARCHAR, DecryptByKey(EncryptedPaymentInfo)) AS DecryptedPaymentInfo
FROM Clients;

CLOSE SYMMETRIC KEY RefinedStackKey;

CREATE EVENT NOTIFICATION LoginFailedAlert
ON SERVER
FOR AUDIT_LOGIN_FAILED
TO SERVICE 'LoginMonitorService', 'current database';

EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'Database Mail XPs', 1;
RECONFIGURE;

EXEC msdb.dbo.sysmail_add_account_sp
    @account_name = 'AdminAlertAccount',
    @email_address = 'admin@example.com',
    @mailserver_name = 'smtp.example.com'; -- Replace with your SMTP server

	EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'Database Mail XPs', 1;
RECONFIGURE;

EXEC msdb.dbo.sysmail_help_profile_sp;

EXEC msdb.dbo.sysmail_add_profile_sp 
    @profile_name = 'AdminAlertAccount', 
    @description = 'Mail profile for alerting admins';

	SELECT name FROM msdb.dbo.sysmail_profile;

	SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Clients';

USE RefinedStackDB; -- Make sure you're using the correct database
GO

IF EXISTS (SELECT 1 FROM sys.triggers WHERE name = 'trg_AlertOnDelete')
    DROP TRIGGER trg_AlertOnDelete;
GO

CREATE TRIGGER trg_AlertOnDelete
ON dbo.Clients -- Ensure the correct schema (dbo) is used
AFTER DELETE
AS
BEGIN
    IF EXISTS (SELECT 1 FROM deleted) -- Ensures the trigger only runs when rows are deleted
    BEGIN
        EXEC msdb.dbo.sp_send_dbmail
            @profile_name = 'AdminAlertAccount',
            @recipients = 'admin@example.com',
            @subject = 'ALERT: Data Deletion Detected!',
            @body = 'Warning: A record was deleted from the Clients table.';
    END;
END;
GO

SELECT name FROM sys.triggers WHERE name = 'trg_AlertOnDelete';
DELETE FROM dbo.Clients WHERE ClientID = 1; -- Replace with an existing ID

SELECT COLUMN_NAME 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'AccessLogs';

ALTER TABLE AccessLogs 
ADD ActionTimestamp DATETIME DEFAULT GETDATE();

SELECT * FROM AccessLogs ORDER BY ActionTimestamp DESC;
SELECT * FROM AccessLogs;

SELECT * FROM msdb.dbo.backupset ORDER BY backup_finish_date DESC;

EXEC xp_cmdshell 'dir C:\SQLBackups\';
RESTORE FILELISTONLY FROM DISK = 'C:\SQLBackups\RefinedStackDB_Feb.bak';
SELECT * FROM AccessLogs ORDER BY ActionTimestamp DESC;
SELECT FullName, Email, PasswordHash, EncryptedPaymentInfo FROM Clients;
OPEN SYMMETRIC KEY RefinedStackKey DECRYPTION BY CERTIFICATE RefinedStackCert;

SELECT FullName, Email, 
       CONVERT(NVARCHAR, DecryptByKey(EncryptedPaymentInfo)) AS DecryptedPaymentInfo
FROM Clients;

CLOSE SYMMETRIC KEY RefinedStackKey;


BACKUP DATABASE RefinedStackDB 
TO DISK = 'C:\Users\SWETHA MACHA\Documents\RefinedStackDB.bak' 
WITH FORMAT, INIT, NAME = 'Daily Backup';




























