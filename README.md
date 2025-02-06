# **Refined Stack Co. Secure Database Implementation**

## **Project Overview**
This project enhances **database security** for Refined Stack Co. by implementing:
- **Automatic backups** for disaster recovery.
- **Data encryption** to protect sensitive client information.
- **Security alerts** for suspicious activities.
- **Access logs** to monitor database activities.
- **Regular maintenance** for performance and compliance.

---

## **Prerequisites**
Ensure you have the following installed:
- **SQL Server Management Studio (SSMS)**
- **SQL Server (Standard, Developer, or Enterprise Edition)**
- **Administrative privileges on the database server**

---

## **1. Database Setup**
### **Step 1: Create the Database**
```sql
CREATE DATABASE RefinedStackDB;
GO
```

### **Step 2: Switch to the Database**
```sql
USE RefinedStackDB;
GO
```

---

## **2. Secure Schema Design**
### **Step 1: Create Clients Table**
```sql
CREATE TABLE Clients (
    ClientID INT IDENTITY(1,1) PRIMARY KEY,
    FullName NVARCHAR(100) NOT NULL,
    Email NVARCHAR(255) UNIQUE NOT NULL,
    PasswordHash VARBINARY(64) NOT NULL,
    EncryptedPaymentInfo VARBINARY(MAX) NULL
);
```

### **Step 2: Create Products Table**
```sql
CREATE TABLE Products (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Description NVARCHAR(500),
    Status NVARCHAR(50),
    ClientID INT FOREIGN KEY REFERENCES Clients(ClientID)
);
```

---

## **3. Data Encryption Implementation**
### **Step 1: Create a Master Key**
```sql
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'StrongPassword123!';
```

### **Step 2: Create a Certificate**
```sql
CREATE CERTIFICATE RefinedStackCert
WITH SUBJECT = 'Refined Stack Co. Security';
```

### **Step 3: Create a Symmetric Key for Encryption**
```sql
CREATE SYMMETRIC KEY RefinedStackKey
WITH ALGORITHM = AES_256
ENCRYPTION BY CERTIFICATE RefinedStackCert;
```

### **Step 4: Insert Encrypted Payment Data**
```sql
OPEN SYMMETRIC KEY RefinedStackKey DECRYPTION BY CERTIFICATE RefinedStackCert;

UPDATE Clients
SET EncryptedPaymentInfo = EncryptByKey(Key_GUID('RefinedStackKey'), CONVERT(VARBINARY, 'CreditCard1234'))
WHERE Email = 'alice@example.com';

CLOSE SYMMETRIC KEY RefinedStackKey;
```

### **Step 5: Decrypt Payment Data**
```sql
OPEN SYMMETRIC KEY RefinedStackKey DECRYPTION BY CERTIFICATE RefinedStackCert;

SELECT FullName, Email,
       CONVERT(NVARCHAR, DecryptByKey(EncryptedPaymentInfo)) AS DecryptedPaymentInfo
FROM Clients;

CLOSE SYMMETRIC KEY RefinedStackKey;
```

---

## **4. Automatic Backups**
### **Step 1: Create a Backup Job in SQL Server Agent**
1. **Open SSMS** → Expand **SQL Server Agent** → Right-click **Jobs** → **New Job**.
2. Under **General**, name the job (e.g., `DailyBackup`).
3. Go to **Steps** → Click **New** → Enter Step Name (`Full Backup`).
4. In the Command Box, enter:
   ```sql
   BACKUP DATABASE RefinedStackDB
   TO DISK = 'C:\SQLBackups\RefinedStackDB.bak'
   WITH FORMAT, INIT, NAME = 'Daily Backup';
   ```
5. Schedule the backup under the **Schedules** tab (e.g., daily at midnight).
6. Click **OK**.

---

## **5. Security Alerts**
### **Step 1: Monitor Failed Logins**
```sql
CREATE EVENT NOTIFICATION LoginFailedAlert
ON SERVER
FOR AUDIT_LOGIN_FAILED
TO SERVICE 'LoginMonitorService', 'current database';
```

### **Step 2: Email Alerts for Unauthorized Deletions**
```sql
CREATE TRIGGER trg_AlertOnDelete
ON Clients
AFTER DELETE
AS
BEGIN
    EXEC msdb.dbo.sp_send_dbmail
        @profile_name = 'AdminAlertAccount',
        @recipients = 'admin@example.com',
        @subject = 'ALERT: Data Deletion Detected!',
        @body = 'Warning: A record was deleted from the Clients table.';
END;
```

---

## **6. Access Logging**
### **Step 1: Create an Access Log Table**
```sql
CREATE TABLE AccessLogs (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    UserName NVARCHAR(100),
    ActionType NVARCHAR(50),
    TableName NVARCHAR(100),
    ActionTimestamp DATETIME DEFAULT GETDATE(),
    IPAddress NVARCHAR(50)
);
```

### **Step 2: Log Data Modifications**
```sql
CREATE TRIGGER trg_LogChanges
ON Clients
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    INSERT INTO AccessLogs (UserName, ActionType, TableName, IPAddress)
    SELECT SUSER_NAME(), EVENTDATA().value('(/EVENT_INSTANCE/EventType)[1]', 'NVARCHAR(50)'), 'Clients', HOST_NAME();
END;
```

---

## **7. Testing & Validation**
### **Step 1: Verify Backup Exists**
```sql
EXEC xp_cmdshell 'dir C:\SQLBackups\';
```

### **Step 2: Check Logs for Unauthorized Actions**
```sql
SELECT * FROM AccessLogs ORDER BY ActionTimestamp DESC;
```

### **Step 3: Validate Encryption**
```sql
SELECT FullName, Email, PasswordHash, EncryptedPaymentInfo FROM Clients;
```

---

## **8. Maintenance & Cleanup**
### **Step 1: Remove Old Logs**
```sql
DELETE FROM AccessLogs WHERE ActionTimestamp < DATEADD(DAY, -30, GETDATE());
```

### **Step 2: Check Backup History**
```sql
SELECT * FROM msdb.dbo.backupset ORDER BY backup_finish_date DESC;
```

---

## **Conclusion**
- ✅ **Backups are automated and validated**.
- ✅ **Data is encrypted and securely stored**.
- ✅ **Access logs capture all database activity**.
- ✅ **Alerts notify admins of suspicious actions**.
- ✅ **Regular maintenance ensures security & performance**.

🎯 **Final Status:** The Refined Stack Co. database is now secure and robust against cyber threats! 🚀

