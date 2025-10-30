# 🧠 Database Security Project

## 📋 Overview
This project demonstrates **Database Security concepts in SQL Server (T-SQL)** including:
- User roles and privileges  
- Access control using views  
- Secure data exposure (public vs. admin access)  
- Functional dependency and inference control  
- Data anonymization techniques  

The database used: **db_Security**

---

## 🏗️ Database Structure

### 1. `Employees` Table
Stores basic employee data.

| Column | Type | Description |
|--------|------|-------------|
| EmpID | INT (PK) | Employee ID |
| FullName | NVARCHAR(100) | Employee full name |
| Salary | INT | Employee salary |
| Dep | NVARCHAR(50) | Department name |
| Title | NVARCHAR(50) | Job title |

---

### 2. `AdminMap` Table
Maps each employee to a **unique public identifier (GUID)** for anonymization.

| Column | Type | Description |
|--------|------|-------------|
| PublicID | UNIQUEIDENTIFIER (PK) | Public anonymous ID |
| EmpID | INT (Unique) | Employee reference |

---

## 🔐 User Accounts and Roles

### 👥 Logins & Users
| Login | User | Role |
|--------|-------|------|
| User_Public | general | Public_Role |
| User_Admin | admin1 | Admin_Role |
| reader_login | reader | read_onlyX |
| writer_login | writer | insert_onlyX |
| powerBebo_login | powerBebo | power_user |

---

### 🧩 Roles and Permissions

#### **Public_Role**
- ❌ Denied: SELECT on base tables (`Employees`, `AdminMap`)  
- ✅ Granted: SELECT on views (`vPublicNames`, `vPublicSalaries`, `vAvgSalary_ByDept_K3`)

#### **Admin_Role**
- ✅ Full privileges (SELECT, INSERT, UPDATE, DELETE, ALTER) on base tables

#### **read_onlyX**
- ✅ SELECT on `Employees`

#### **insert_onlyX**
- ✅ INSERT and DELETE on `Employees`

#### **power_user**
- ✅ Inherits from both read_onlyX and insert_onlyX  
- ✅ Full control (SELECT, INSERT, DELETE)

---

## 👁️ Views (Data Masking / Access Control)

### `vPublicNames`
Exposes only **PublicID** and **FullName** (no sensitive info).

```sql
SELECT am.PublicID, e.FullName
FROM dbo.Employees e
JOIN dbo.AdminMap am ON e.EmpID = am.EmpID;
