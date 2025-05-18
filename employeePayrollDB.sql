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

CREATE PROCEDURE UpdateEmployeeByID
    @employee_id INT,
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
    UPDATE Employees
    SET
        name = @name,
        phone = @phone,
        email = @email,
        gender = @gender,
        address = @address,
        cnic_num = @cnic_num,
        employee_type_id = @employee_type_id,
        department_id = @department_id,
        grade_id = @grade_id,
        hire_date = @hire_date
    WHERE employee_id = @employee_id;
END;
GO

ALTER TABLE Attendance
ADD status VARCHAR(20);
GO

CREATE OR ALTER PROCEDURE CheckInEmployeeByUserId
    @user_id INT
AS
BEGIN
    DECLARE @employee_id INT;
    DECLARE @currentDate DATE = CAST(GETDATE() AS DATE);
    DECLARE @currentTime TIME = CAST(GETDATE() AS TIME);
    DECLARE @existingCheckIn TIME;

    SELECT @employee_id = employee_id 
    FROM Employees 
    WHERE user_id = @user_id;

    IF @employee_id IS NULL
    BEGIN
        RAISERROR('No employee found for the given user ID.', 16, 1);
        RETURN;
    END

    -- Check if already checked in today
    SELECT @existingCheckIn = check_in
    FROM Attendance
    WHERE employee_id = @employee_id AND date = @currentDate;

    IF @existingCheckIn IS NOT NULL
    BEGIN
        RAISERROR('Employee already checked in today.', 16, 1);
        RETURN;
    END

    -- Define valid check-in window
    DECLARE @startTime TIME = '08:30:00';
    DECLARE @presentCutoff TIME = '09:00:00';
    DECLARE @lateCutoff TIME = '09:30:00';

    -- Validate check-in time window
    IF @currentTime < @startTime OR @currentTime > @lateCutoff
    BEGIN
        RAISERROR('Check-in is allowed only between 08:30 and 09:30 AM.', 16, 1);
        RETURN;
    END

    -- Determine attendance status
    DECLARE @status VARCHAR(20);
    IF @currentTime <= @presentCutoff
        SET @status = 'Present';
    ELSE IF @currentTime <= @lateCutoff
        SET @status = 'Late';
    ELSE
        SET @status = 'Absent';

    INSERT INTO Attendance (employee_id, date, check_in, status)
    VALUES (@employee_id, @currentDate, @currentTime, @status);
END;
GO

ALTER TABLE Attendance
ADD overtime_hours INT DEFAULT 0;


CREATE OR ALTER PROCEDURE CheckOutEmployeeByUserId
    @user_id INT
AS
BEGIN
    DECLARE @employee_id INT;
    DECLARE @currentDate DATE = CAST(GETDATE() AS DATE);
    DECLARE @currentTime TIME = CAST(GETDATE() AS TIME);
    DECLARE @existingCheckIn TIME;
    DECLARE @existingCheckOut TIME;

    SELECT @employee_id = employee_id FROM Employees WHERE user_id = @user_id;

    IF @employee_id IS NULL
    BEGIN
        RAISERROR('No employee found for the given user ID.', 16, 1);
        RETURN;
    END

    SELECT @existingCheckIn = check_in, @existingCheckOut = check_out
    FROM Attendance
    WHERE employee_id = @employee_id AND date = @currentDate;

    IF @existingCheckIn IS NULL
    BEGIN
        RAISERROR('Check-in required before check-out.', 16, 1);
        RETURN;
    END

    IF @existingCheckOut IS NOT NULL
    BEGIN
        RAISERROR('Check-out already done for today.', 16, 1);
        RETURN;
    END

    -- Calculate overtime
    DECLARE @overtime_hours INT = 0;
    IF @currentTime >= '18:00:00'
    BEGIN
        SET @overtime_hours = DATEDIFF(HOUR, '18:00:00', 
                            CASE WHEN @currentTime > '22:00:00' THEN '22:00:00' ELSE @currentTime END);
    END

    UPDATE Attendance
    SET check_out = @currentTime, overtime_hours = @overtime_hours
    WHERE employee_id = @employee_id AND date = @currentDate;
END;
GO

CREATE PROCEDURE MarkAbsentees
AS
BEGIN
    DECLARE @today DATE = CAST(GETDATE() AS DATE);

    -- Insert an 'Absent' record for each employee who didn't check in today
    INSERT INTO Attendance (employee_id, date, status)
    SELECT e.employee_id, @today, 'Absent'
    FROM Employees e
    WHERE NOT EXISTS (
        SELECT 1 FROM Attendance a
        WHERE a.employee_id = e.employee_id AND a.date = @today
    );
END;
GO

CREATE or alter  PROCEDURE AutoCheckoutEmployees 
AS
BEGIN
    DECLARE @yesterday DATE = DATEADD(DAY, -1, CAST(GETDATE() AS DATE));
    DECLARE @defaultOutTime TIME = '17:30:00'; -- Default 5:30 PM

    -- Only run if yesterday is NOT Saturday or Sunday
    IF DATENAME(WEEKDAY, @yesterday) NOT IN ('Saturday', 'Sunday')
    BEGIN
        -- Update only if employee checked in but forgot to check out
        UPDATE Attendance
        SET check_out = @defaultOutTime
        WHERE 
            date = @yesterday
            AND check_in IS NOT NULL
            AND (check_out IS NULL OR check_out = '');
    END
END;
GO


SELECT * FROM Users;
SELECT * FROM Employees;
Select * FROM Attendance;
