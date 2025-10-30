IF DB_ID('db_Security') IS NOT NULL
    DROP DATABASE db_Security;
GO

CREATE DATABASE db_Security;
GO

USE db_Security;
GO

CREATE TABLE dbo.Employees (
	EmpID INT PRIMARY KEY,
	FullName NVARCHAR(100),
	Salary INT,
	Dep NVARCHAR(50),
	Title NVARCHAR(50)
);

INSERT INTO dbo.Employees (EmpID, FullName, Salary, Dep, Title)
VALUES
(1, 'Ali', 120000, 'Sales', 'Manager'),
(2, 'Asser', 110000, 'Sales', 'Senior'),
(3, 'Mona', 100000, 'HR', 'Manager'),
(4, 'Fatma', 90000, 'HR', 'Senior'),
(5, 'Gehad', 80000, 'IT', 'Eng'),
(6, 'Ahmed', 70000, 'IT', 'Junior');
GO

CREATE TABLE dbo.AdminMap (
	PublicID UNIQUEIDENTIFIER PRIMARY KEY,
	EmpID INT UNIQUE
);
INSERT INTO dbo.AdminMap (PublicID, EmpID)
VALUES
(NEWID(), 1),
(NEWID(), 2),
(NEWID(), 3),
(NEWID(), 4),
(NEWID(), 5),
(NEWID(), 6);
GO

IF SUSER_ID('User_Public') IS NOT NULL
	DROP LOGIN User_Public;
IF SUSER_ID('User_Admin') IS NOT NULL
	DROP LOGIN User_Admin;
GO

CREATE LOGIN User_Public WITH PASSWORD = 'public';
CREATE LOGIN User_Admin WITH PASSWORD = 'admin';
GO

DROP USER IF EXISTS general;
DROP USER IF EXISTS admin1;
GO

CREATE USER general FOR LOGIN User_Public;
CREATE USER admin1 FOR LOGIN User_Admin;
GO

DROP ROLE IF EXISTS Public_Role;
DROP ROLE IF EXISTS Admin_Role;
GO

CREATE ROLE Public_Role;
CREATE ROLE Admin_Role;
GO

ALTER ROLE Public_Role ADD MEMBER general;
ALTER ROLE Admin_Role ADD MEMBER admin1;
GO

DENY SELECT ON dbo.Employees TO Public_Role;
DENY SELECT ON dbo.AdminMap TO Public_Role;
GO

GRANT SELECT, INSERT, UPDATE, ALTER, DELETE ON dbo.Employees TO Admin_Role;
GRANT SELECT, INSERT, UPDATE, ALTER, DELETE ON dbo.AdminMap TO Admin_Role;
GO

CREATE VIEW dbo.vPublicNames AS 
SELECT am.PublicID, e.FullName
FROM dbo.Employees e
JOIN dbo.AdminMap am ON e.EmpID = am.EmpID;
GO

CREATE VIEW dbo.vPublicSalaries AS
SELECT am.PublicID, e.Salary
FROM dbo.Employees e
JOIN dbo.AdminMap am ON e.EmpID = am.EmpID;
GO

GRANT SELECT ON dbo.vPublicNames TO Public_Role;
GRANT SELECT ON dbo.vPublicSalaries TO Public_Role;
GO

EXEC AS LOGIN = 'User_Admin';
	SELECT  * FROM dbo.Employees;
	SELECT  * FROM dbo.AdminMap;
REVERT;

EXEC AS LOGIN = 'User_Public';
	SELECT * FROM dbo.vPublicNames;
	SELECT * FROM dbo.vPublicSalaries;
REVERT;
GO

DROP ROLE IF EXISTS read_onlyX;
DROP ROLE IF EXISTS insert_onlyX;
DROP ROLE IF EXISTS power_user;
GO

CREATE ROLE read_onlyX;
CREATE ROLE insert_onlyX;
CREATE ROLE power_user;
GO

IF SUSER_ID('reader_login') IS NOT NULL
	DROP LOGIN reader_login;
IF SUSER_ID('writer_login') IS NOT NULL
	DROP LOGIN writer_login;
IF SUSER_ID('powerBebo_login') IS NOT NULL
	DROP LOGIN powerBebo_login;
GO

CREATE LOGIN reader_login WITH PASSWORD = 'reader';
CREATE LOGIN writer_login WITH PASSWORD = 'writer';
CREATE LOGIN powerBebo_login WITH PASSWORD = 'bebo';
GO

CREATE USER reader FOR LOGIN reader_login;
CREATE USER writer FOR LOGIN writer_login;
CREATE USER powerBebo FOR LOGIN powerBebo_login;
GO

ALTER ROLE read_onlyX ADD MEMBER reader;
ALTER ROLE insert_onlyX ADD MEMBER writer;
ALTER ROLE read_onlyX ADD MEMBER powerBebo;
ALTER ROLE insert_onlyX ADD MEMBER powerBebo;
ALTER ROLE power_user ADD MEMBER powerBebo;
GO

GRANT SELECT ON dbo.Employees TO read_onlyX;
GRANT INSERT, DELETE ON dbo.Employees TO insert_onlyX;	
GO

EXEC AS LOGIN = 'reader_login';
	SELECT * FROM dbo.Employees;
REVERT;
GO

EXEC AS LOGIN = 'writer_login';
	INSERT dbo.Employees VALUES (33, 'Bebo', 1000000, 'Owner', 'Owner');
REVERT;
GO

EXEC AS LOGIN = 'powerBebo_login';
	SELECT * FROM dbo.Employees;
	INSERT dbo.Employees VALUES (44, 'Mohamed', 1000000, 'Owner', 'Owner');
	DELETE FROM dbo.Employees WHERE EmpID = 44;
REVERT;
GO

EXEC AS LOGIN = 'User_Public';
	SELECT ROW_NUMBER() OVER (ORDER BY PublicID) AS rn, PublicID, FullName
	FROM dbo.vPublicNames ORDER BY PublicID;

	SELECT ROW_NUMBER() OVER (ORDER BY PublicID) AS rn, PublicID, Salary
	FROM dbo.vPublicSalaries ORDER BY PublicID;
REVERT;
GO

UPDATE dbo.AdminMap SET PublicID = NEWID();
GO

EXEC AS LOGIN = 'User_Public';
	SELECT ROW_NUMBER() OVER (ORDER BY PublicID) AS rn, PublicID, FullName
	FROM dbo.vPublicNames;
	SELECT ROW_NUMBER() OVER (ORDER  BY PublicID) AS rn, PublicID, Salary
	FROM dbo.vPublicSalaries;
REVERT;
GO

CREATE OR ALTER VIEW dbo.vAvgSalary_ByDept_K3
AS
SELECT Dep,
       COUNT(*) AS cnt,
       CASE WHEN COUNT(*) >= 3 THEN AVG(CAST(Salary AS FLOAT))
            ELSE NULL END AS avgSalary_protected
FROM dbo.Employees
GROUP BY Dep;
GO

REVOKE SELECT ON dbo.vPublicSalaries FROM public_role;
GRANT SELECT ON dbo.vAvgSalary_ByDept_K3 TO public_role;
GO

EXECUTE AS LOGIN = 'user_public';
    SELECT * FROM dbo.vAvgSalary_ByDept_K3;
REVERT;
GO

/*
FD1: EmpID → Dept
FD2: Title → Grade
FD3: Dept, Grade → Bonus

Closure of {Dept, Title}:
{Dept, Title} + FD2 → add Grade
{Dept, Grade, Title} + FD3 → add Bonus
⟹ Q⁺ = {Dept, Title, Grade, Bonus}
⟹ Bonus ∈ Q⁺  ⇒ ممكن استنتاج البونص عشان كده لازم رفض أو تعديل الاستعلام
*/

CREATE TABLE dbo.TitleGrade (
    Title  VARCHAR(30) PRIMARY KEY,
    Grade  VARCHAR(10) NOT NULL
);
GO

INSERT INTO dbo.TitleGrade VALUES
('Professor','Lead'),
('Associate Professor','Senior'),
('Assistant Professor','Junior'),
('Engineer I','Junior'),
('Engineer II','Senior'),
('Engineer Lead','Lead');
GO

CREATE TABLE dbo.BonusMatrix (
    Dept  VARCHAR(20) NOT NULL,
    Grade VARCHAR(10) NOT NULL,
    Bonus INT NOT NULL,
    CONSTRAINT PK_BonusMatrix PRIMARY KEY (Dept, Grade)
);
GO

INSERT INTO dbo.BonusMatrix VALUES
('CS','Junior', 8000), ('CS','Senior',12000), ('CS','Lead',15000),
('IT','Junior', 6000), ('IT','Senior',10000), ('IT','Lead',13000);
GO

CREATE TABLE dbo.Employee (
    EmpID  INT PRIMARY KEY,
    Dept   VARCHAR(20) NOT NULL,
    Title  VARCHAR(30) NOT NULL,
    Bonus  INT NOT NULL
);
GO

INSERT INTO dbo.Employee VALUES
(1,'CS','Professor',15000),
(2,'CS','Associate Professor',12000),
(3,'CS','Assistant Professor',8000),
(4,'IT','Engineer I',6000),
(5,'IT','Engineer II',10000),
(6,'IT','Engineer Lead',13000);
GO

-- title and dept
SELECT EmpID, Dept, Title FROM dbo.Employee;
GO

-- combine the 2 tables TitleGrade و BonusMatrix show the importance of closure
SELECT e.EmpID, e.Dept, e.Title, tg.Grade, bm.Bonus
FROM dbo.Employee e
JOIN dbo.TitleGrade tg ON e.Title = tg.Title
JOIN dbo.BonusMatrix bm ON e.Dept = bm.Dept AND tg.Grade = bm.Grade;
GO

CREATE VIEW dbo.v_safe AS
SELECT Dept, COUNT(*) AS n_employees
FROM dbo.Employee
GROUP BY Dept;
GO

-- students show data
SELECT * FROM dbo.v_safe;
GO