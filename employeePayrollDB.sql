USE master;

CREATE DATABASE employeePayrollDB;

USE employeePayrollDB;
GO

-- Users Table
CREATE TABLE Users (
    user_id INT PRIMARY KEY IDENTITY(1,1),
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL,
);
GO

-- Employee Type Table
CREATE TABLE EmployeeType (
    employee_type_id INT PRIMARY KEY IDENTITY(1,1),
    type_name VARCHAR(50) NOT NULL UNIQUE
);
GO

-- Departments Table
CREATE TABLE Departments (
    department_id INT PRIMARY KEY IDENTITY(1,1),
    department_name VARCHAR(50) NOT NULL UNIQUE
);
GO

-- Salary Structure Table
CREATE TABLE SalaryStructure (
    structure_id INT PRIMARY KEY IDENTITY(1,1),
    department_id INT NOT NULL,
    base_salary DECIMAL(10,2) NOT NULL,
    allowed_leaves INT NOT NULL,
    FOREIGN KEY (department_id) REFERENCES Departments(department_id)
);
GO

--Grades Table
CREATE TABLE Grades (
	grade_id INT PRIMARY KEY IDENTITY(1,1),
	grade VARCHAR(20) NOT NULL
);
GO

-- Employees Table
CREATE TABLE Employees (
    employee_id INT PRIMARY KEY IDENTITY(1,1),
    user_id INT NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(15) NOT NULL UNIQUE,
	email VARCHAR(30) NOT NULL UNIQUE,
	gender VARCHAR(10) NOT NULL,
    address VARCHAR(255) NOT NULL,
	cnic_num VARCHAR(20) NOT NULL UNIQUE,
    employee_type_id INT NOT NULL,
    department_id INT NOT NULL,
	grade_id INT NOT NULL,
    hire_date DATE NOT NULL,
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (employee_type_id) REFERENCES EmployeeType(employee_type_id),
    FOREIGN KEY (department_id) REFERENCES Departments(department_id),
	FOREIGN KEY (grade_id) REFERENCES Grades(grade_id)
);
GO

-- Attendance Table
CREATE TABLE Attendance (
    attendance_id INT PRIMARY KEY IDENTITY(1,1),
    employee_id INT NOT NULL,
    date DATE NOT NULL,
    check_in TIME,
    check_out TIME,
    FOREIGN KEY (employee_id) REFERENCES Employees(employee_id)
);
GO

-- Leave Status Table
CREATE TABLE LeaveStatus (
	status_id INT PRIMARY KEY IDENTITY(1,1),
	status VARCHAR(50) NOT NULL
);
GO

-- Leaves Table
CREATE TABLE Leaves (
    leave_id INT PRIMARY KEY IDENTITY(1,1),
    employee_id INT NOT NULL,
    leave_date DATE NOT NULL,
    leave_reason VARCHAR(255),
    status_id INT NOT NULL,
    FOREIGN KEY (employee_id) REFERENCES Employees(employee_id),
	FOREIGN KEY (status_id) REFERENCES LeaveStatus(status_id)
);
GO

-- Payroll Table
CREATE TABLE Payroll (
    payroll_id INT PRIMARY KEY IDENTITY(1,1),
    employee_id INT NOT NULL,
    month VARCHAR(20) NOT NULL,
    year INT NOT NULL,
    base_salary DECIMAL(10, 2) NOT NULL,
    deductions DECIMAL(10, 2) DEFAULT 0,
    bonus DECIMAL(10, 2) DEFAULT 0,
    net_salary AS (base_salary - deductions + bonus) PERSISTED,
    FOREIGN KEY (employee_id) REFERENCES Employees(employee_id)
);
GO

-- Global Settings Table
CREATE TABLE GlobalSettings (
    setting_key VARCHAR(50) PRIMARY KEY,
    setting_value VARCHAR(100) NOT NULL
);
GO

INSERT INTO Users (username, password, role) VALUES
('admin1', 'adminpass', 'admin'),
('user1', 'userpass', 'user');
GO

INSERT INTO EmployeeType VALUES
('Full-Time'),
('Contract-Based');
GO

INSERT INTO Departments VALUES
('IT'),
('Sales'),
('HR'),
('Operations'),
('Finance');
GO

INSERT INTO Grades VALUES
(10),
(12),
(14),
(16),
(17),
(18),
(19),
(20);
GO

CREATE PROCEDURE InsertEmployee
    @user_id INT,
    @name VARCHAR(100),
    @phone VARCHAR(15),
    @email VARCHAR(100),
    @gender VARCHAR(10),
    @address VARCHAR(255),
    @cnic_num VARCHAR(20),
    @employee_type_id INT,
    @department_id INT,
    @grade_id INT,
    @hire_date DATE
AS
BEGIN
    IF EXISTS (SELECT 1 FROM Employees WHERE cnic_num = @cnic_num)
    BEGIN
        RAISERROR ('CNIC already exists.', 16, 1);
        RETURN;
    END

    INSERT INTO Employees (
        user_id, name, phone, email, gender, address,
        cnic_num, employee_type_id, department_id, grade_id, hire_date
    )
    VALUES (
        @user_id, @name, @phone, @email, @gender, @address,
        @cnic_num, @employee_type_id, @department_id, @grade_id, @hire_date
    );
END;
GO

CREATE PROCEDURE ViewAllEmployees
AS
BEGIN
    SELECT 
        e.employee_id,
        u.username,
        e.name,
        e.phone,
        e.email,
        e.gender,
        e.address,
        e.cnic_num,
        et.type_name AS employee_type,
        d.department_name,
        g.grade,
        e.hire_date
    FROM Employees e
    INNER JOIN Users u ON e.user_id = u.user_id
    INNER JOIN EmployeeType et ON e.employee_type_id = et.employee_type_id
    INNER JOIN Departments d ON e.department_id = d.department_id
    INNER JOIN Grades g ON e.grade_id = g.grade_id;
END;
GO

CREATE PROCEDURE DeleteEmployeeByID
    @employee_id INT
AS
BEGIN
    DECLARE @user_id INT;

    SELECT @user_id = user_id FROM Employees WHERE employee_id = @employee_id;

    DELETE FROM Employees WHERE employee_id = @employee_id;

    IF @user_id IS NOT NULL
    BEGIN
        DELETE FROM Users WHERE user_id = @user_id;
    END
END;
GO

CREATE PROCEDURE SearchEmployeeByID
    @employee_id INT
AS
BEGIN
    SELECT 
        e.employee_id,
        u.username,
        e.name,
        e.phone,
        e.email,
        e.gender,
        e.address,
        e.cnic_num,
        et.type_name AS employee_type,
        d.department_name,
        g.grade,
        e.hire_date
    FROM Employees e
    INNER JOIN Users u ON e.user_id = u.user_id
    INNER JOIN EmployeeType et ON e.employee_type_id = et.employee_type_id
    INNER JOIN Departments d ON e.department_id = d.department_id
    INNER JOIN Grades g ON e.grade_id = g.grade_id
    WHERE e.employee_id = @employee_id;
END;
GO


SELECT * FROM Users;
SELECT * FROM Employees;