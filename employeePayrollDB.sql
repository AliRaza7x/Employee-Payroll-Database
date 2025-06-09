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

--Leave Type Table
CREATE TABLE LeaveTypes (
    leave_type_id INT PRIMARY KEY IDENTITY(1,1),
    type_name VARCHAR(50) NOT NULL
);
GO

-- Leave Status Table
CREATE TABLE LeaveStatus (
	status_id INT PRIMARY KEY IDENTITY(1,1),
	status VARCHAR(50) NOT NULL
);
GO

--Leave Requests
CREATE TABLE LeaveRequest (
    request_id INT PRIMARY KEY IDENTITY(1,1),
    employee_id INT NOT NULL,
    leave_start_date DATE NOT NULL,
	leave_end_date DATE NOT NULL,
	leave_type_id INT NOT NULL,
    leave_reason VARCHAR(255),
    status_id INT NOT NULL,
    FOREIGN KEY (employee_id) REFERENCES Employees(employee_id),
	FOREIGN KEY (status_id) REFERENCES LeaveStatus(status_id),
	FOREIGN KEY (leave_type_id) REFERENCES LeaveTypes(leave_type_id)
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

ALTER TABLE Leaves
ADD leave_type_id INT;
GO

ALTER TABLE Leaves
ADD leave_end_date DATE NOT NULL;
GO

ALTER TABLE Leaves
ADD CONSTRAINT FK_Leaves_LeaveTypes
FOREIGN KEY (leave_type_id) REFERENCES LeaveTypes(leave_type_id);
GO

ALTER TABLE Leaves
ADD request_id INT;
GO

ALTER TABLE Leaves
ADD CONSTRAINT FK_Leaves_LeaveRequest
FOREIGN KEY (request_id) REFERENCES LeaveRequest(request_id);
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
select * from payroll

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

UPDATE Users
SET role = 'superadmin'
WHERE user_id = 1;

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

INSERT INTO LeaveStatus (status) VALUES 
('Pending'), 
('Approved'), 
('Rejected');
GO


INSERT INTO LeaveTypes (type_name) 
VALUES 
('Paid Leave'), 
('Sick Leave'), 
('Maternity Leave'), 
('Paternity Leave'), 
('Travel Leave'), 
('Casual Leave');
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
select * from Attendance

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

CREATE OR ALTER PROCEDURE InsertLeave
    @employee_id INT,
    @leave_start_date DATE,
	@leave_end_date DATE,
    @leave_reason VARCHAR(255),
    @leave_type_id INT
AS
BEGIN
    DECLARE @status_id INT;
    SELECT @status_id = status_id FROM LeaveStatus WHERE status = 'Pending';

    INSERT INTO LeaveRequest
    VALUES (@employee_id, @leave_start_date, @leave_end_date, @leave_type_id, @leave_reason, @status_id);
END;
GO

CREATE OR ALTER VIEW Absences AS
SELECT 
    e.employee_id, 
    e.name, 
    d.department_name, 
    all_dates.date
FROM Employees e
JOIN Departments d ON e.department_id = d.department_id
CROSS JOIN (
    SELECT DISTINCT date 
    FROM Attendance
    WHERE DATENAME(WEEKDAY, date) NOT IN ('Saturday', 'Sunday')  -- exclude weekends
) AS all_dates
LEFT JOIN Attendance a 
    ON e.employee_id = a.employee_id AND a.date = all_dates.date
WHERE a.attendance_id IS NULL;

SELECT * FROM Users

INSERT INTO Users (username, password, role) VALUES
('admin2', 'adminpass', 'admin');

CREATE OR ALTER PROCEDURE GetEmployeeDetailsByUserId
    @UserId INT
AS
BEGIN
    SELECT 
        e.employee_id,
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
    INNER JOIN EmployeeType et ON e.employee_type_id = et.employee_type_id
    INNER JOIN Departments d ON e.department_id = d.department_id
    INNER JOIN Grades g ON e.grade_id = g.grade_id
    WHERE e.user_id = @UserId;
END;
GO

CREATE OR ALTER PROCEDURE GetAllLeaveRequests
AS
BEGIN
    SELECT 
        lr.request_id,
        lr.employee_id,
        lr.leave_start_date,
        lr.leave_end_date,
        lr.leave_reason,
        lt.type_name AS leave_type,
        ls.status AS leave_status
    FROM 
        LeaveRequest lr
        JOIN LeaveTypes lt ON lr.leave_type_id = lt.leave_type_id
        JOIN LeaveStatus ls ON lr.status_id = ls.status_id;
END;
GO

CREATE OR ALTER PROCEDURE ApproveLeaveRequest
    @request_id INT
AS
BEGIN
    DECLARE @statusApproved INT;
    SELECT @statusApproved = status_id FROM LeaveStatus WHERE status = 'Approved';

    UPDATE LeaveRequest
    SET status_id = @statusApproved
    WHERE request_id = @request_id;

    INSERT INTO Leaves (
        employee_id,
        leave_date,
        leave_end_date,
        leave_reason,
        status_id,
        leave_type_id,
        request_id
    )
    SELECT 
        employee_id,
        leave_start_date,
        leave_end_date,
        leave_reason,
        @statusApproved,
        leave_type_id,
        request_id -- New
    FROM LeaveRequest
    WHERE request_id = @request_id;
END;
GO

CREATE OR ALTER PROCEDURE RejectLeaveRequest
    @request_id INT
AS
BEGIN
    DECLARE @statusRejected INT;
    SELECT @statusRejected = status_id FROM LeaveStatus WHERE status = 'Rejected';

    UPDATE LeaveRequest
    SET status_id = @statusRejected
    WHERE request_id = @request_id;
END;
GO

-- Update ViewAllEmployees to include password
CREATE OR ALTER PROCEDURE ViewAllEmployees
AS
BEGIN
    SELECT 
        e.employee_id,
        u.username,
        u.password,
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

-- Update ViewEmployeesByDepartment to include password
CREATE OR ALTER PROCEDURE ViewEmployeesByDepartment
    @department_id INT
AS
BEGIN
    SELECT 
        e.employee_id,
        u.username,
        u.password,
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
    WHERE e.department_id = @department_id;
END;
GO

-- Update ViewEmployeesByGrade to include password
CREATE OR ALTER PROCEDURE ViewEmployeesByGrade
    @grade_id INT
AS
BEGIN
    SELECT 
        e.employee_id,
        u.username,
        u.password,
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
    WHERE e.grade_id = @grade_id;
END;
GO

-- Update ViewEmployeesByType to include password
CREATE OR ALTER PROCEDURE ViewEmployeesByType
    @employee_type_id INT
AS
BEGIN
    SELECT 
        e.employee_id,
        u.username,
        u.password,
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
    WHERE e.employee_type_id = @employee_type_id;
END;
GO

--had some issues filtering without a dedicated stored procedure
CREATE OR ALTER PROCEDURE ViewFilteredEmployees
    @department_id INT = NULL,
    @grade_id INT = NULL,
    @employee_type_id INT = NULL
AS
BEGIN
    SELECT 
        e.employee_id,
        u.username,
        u.password,
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
    WHERE (@department_id IS NULL OR e.department_id = @department_id)
    AND (@grade_id IS NULL OR e.grade_id = @grade_id)
    AND (@employee_type_id IS NULL OR e.employee_type_id = @employee_type_id);
END;
GO


--omer 26/5/25
-- Get total allowed leaves for an employee based on their department

--run this
CREATE OR ALTER PROCEDURE GetEmployeeAllowedLeaves
    @employee_id INT
AS
BEGIN
    SELECT ss.allowed_leaves
    FROM SalaryStructure ss
    JOIN Employees e ON e.department_id = ss.department_id
    WHERE e.employee_id = @employee_id;
END;
GO

--run this
CREATE OR ALTER PROCEDURE GetEmployeeUsedLeaves
    @EmployeeId INT,
    @Year INT
AS
BEGIN
    SELECT ISNULL(SUM(DATEDIFF(DAY, lr.leave_start_date, lr.leave_end_date) + 1), 0) AS used_leaves
    FROM LeaveRequest lr
    JOIN LeaveStatus ls ON lr.status_id = ls.status_id
    WHERE lr.employee_id = 1
    AND YEAR(lr.leave_start_date) = 2024
    AND ls.status = 'Approved'
END

--run this
-- Get leave history for an employee
CREATE OR ALTER PROCEDURE GetEmployeeLeaveHistory
    @employee_id INT
AS
BEGIN
    SELECT 
        lr.request_id,
        lr.leave_start_date,
        lr.leave_end_date,
        lt.type_name,
        lr.leave_reason,
        ls.status
    FROM LeaveRequest lr
    JOIN LeaveTypes lt ON lr.leave_type_id = lt.leave_type_id
    JOIN LeaveStatus ls ON lr.status_id = ls.status_id
    WHERE lr.employee_id = @employee_id
    ORDER BY lr.leave_start_date DESC;
END;
GO



--sample insert queries to test ViewLeaves
--run this if you dont have much data
-- Insert sample data into SalaryStructure
INSERT INTO SalaryStructure (department_id, base_salary, allowed_leaves) VALUES
(1, 50000.00, 20),  -- IT
(2, 45000.00, 20),  -- Sales
(3, 48000.00, 20),  -- HR
(4, 47000.00, 20),  -- Operations
(5, 52000.00, 20);  -- Finance
GO

-- Insert sample leave requests

INTO LeaveRequest (employee_id, leave_start_date, leave_end_date, leave_type_id, leave_reason, status_id) VALUES
(3, '2024-05-01', '2024-05-03', 1, 'Family vacation', 2),  -- Approved
(3, '2024-06-15', '2024-06-16', 2, 'Not feeling well', 1), -- Pending
(3, '2024-04-10', '2024-04-12', 3, 'Maternity leave', 2);  -- Approved
GO



--omer 28/05/25
--run this

--sample data
-- Approved leave
INSERT INTO LeaveRequest (employee_id, leave_start_date, leave_end_date, leave_type_id, leave_reason, status_id)
VALUES (3, '2025-05-10', '2025-05-12', 1, 'Family vacation', (SELECT status_id FROM LeaveStatus WHERE status = 'Approved'));

-- Pending leave
INSERT INTO LeaveRequest (employee_id, leave_start_date, leave_end_date, leave_type_id, leave_reason, status_id)
VALUES (3, '2025-06-01', '2025-06-02', 2, 'Sick leave', (SELECT status_id FROM LeaveStatus WHERE status = 'Pending'));

-- Rejected leave
INSERT INTO LeaveRequest (employee_id, leave_start_date, leave_end_date, leave_type_id, leave_reason, status_id)
VALUES (4, '2025-07-15', '2025-07-16', 3, 'Personal reason', (SELECT status_id FROM LeaveStatus WHERE status = 'Approved'));

-- Another approved leave
INSERT INTO LeaveRequest (employee_id, leave_start_date, leave_end_date, leave_type_id, leave_reason, status_id)
VALUES (3, '2025-08-05', '2025-08-07', 1, 'Travel', (SELECT status_id FROM LeaveStatus WHERE status = 'Approved'));


SELECT * FROM Employees



--view absences
--run this
CREATE OR ALTER VIEW EmployeeAbsences AS 
SELECT 
    e.employee_id, 
    e.name, 
    d.department_name, 
    a.date, 
    a.status, 
    lt.type_name as leave_type, 
    lr.leave_reason 
FROM Employees e 
JOIN Departments d ON e.department_id = d.department_id 
LEFT JOIN Attendance a ON e.employee_id = a.employee_id 
LEFT JOIN Leaves l ON e.employee_id = l.employee_id AND a.date = l.leave_date 
LEFT JOIN LeaveTypes lt ON l.leave_type_id = lt.leave_type_id 
LEFT JOIN LeaveRequest lr ON l.leave_date = lr.leave_start_date 
WHERE a.status = 'Absent' OR l.leave_date IS NOT NULL;


-- dummy data for absences:
-- First, let's make sure we have some test data in the Attendance table
INSERT INTO Attendance (employee_id, date, status) VALUES
-- Employee 1 absences
(3, '2025-02-05', 'Absent'),
(3, '2025-03-12', 'Absent'),
(3, '2025-05-01', 'Absent'),
(3, '2025-06-10', 'Absent'),
-- Employee 4 absences
(4, '2025-01-15', 'Absent'),
(4, '2025-02-20', 'Absent'),
(4, '2025-04-05', 'Absent'),
(4, '2025-05-15', 'Absent'),
(4, '2025-06-20', 'Absent');

-- Let's also add some regular attendance records to make it more realistic
INSERT INTO Attendance (employee_id, date, check_in, check_out, status) VALUES
-- Employee 1 regular attendance
(3, '2025-02-06', '08:45:00', '17:30:00', 'Present'),
(3, '2025-03-13', '08:50:00', '17:30:00', 'Present'),
(3, '2025-05-02', '08:55:00', '17:30:00', 'Present'),
-- Employee 4 regular attendance
(4, '2025-01-16', '08:40:00', '17:30:00', 'Present'),
(4, '2025-02-21', '08:42:00', '17:30:00', 'Present'),
(4, '2025-04-06', '08:48:00', '17:30:00', 'Present');

-- run this (9 june 2025)

DROP TABLE IF EXISTS Payroll;
GO
-- run this (9 june 2025)
CREATE TABLE Payroll (
    payroll_id INT PRIMARY KEY IDENTITY(1,1),
    employee_id INT NOT NULL,
    pay_month VARCHAR(20) NOT NULL,
    pay_year INT NOT NULL,
    
    base_salary DECIMAL(10, 2) NOT NULL,
    deductions DECIMAL(10, 2) DEFAULT 0,
    absence_deduction DECIMAL(10, 2) DEFAULT 0,
    bonus DECIMAL(10, 2) DEFAULT 0,
    food_allowance DECIMAL(10, 2) DEFAULT 0,
    tax DECIMAL(10, 2) DEFAULT 0,
    overtime_hours INT DEFAULT 0,

    net_salary DECIMAL(10, 2),  -- Calculated in app logic or via trigger/procedure

    FOREIGN KEY (employee_id) REFERENCES Employees(employee_id)
);


-- run this (9 june 2025)
CREATE TABLE GradeBonus (
    grade_id INT,
    bonus_month INT,
    bonus_year INT,
    bonus_amount DECIMAL(10,2),
    PRIMARY KEY (grade_id, bonus_month, bonus_year),
    FOREIGN KEY (grade_id) REFERENCES Grades(grade_id) 
);

-- run this (9 june 2025)
ALTER TABLE Payroll
ADD CONSTRAINT UQ_EmployeeMonthYear UNIQUE (employee_id, pay_month, pay_year);



-- run this (9 june 2025)
CREATE OR ALTER PROCEDURE GetBonusByGrade
    @employee_id INT,
    @bonus_month INT,
    @bonus_year INT,
    @bonus_amount DECIMAL(10,2) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @grade_id INT;
    SELECT @grade_id = grade_id FROM Employees WHERE employee_id = @employee_id;

    IF @grade_id IS NULL
    BEGIN
        SET @bonus_amount = 0;
        RETURN;
    END

    SELECT @bonus_amount = bonus_amount
    FROM GradeBonus
    WHERE grade_id = @grade_id
      AND bonus_month = @bonus_month
      AND bonus_year = @bonus_year;

    IF @bonus_amount IS NULL
        SET @bonus_amount = 0;
END;


-- run this (9 june 2025)
CREATE OR ALTER PROCEDURE dbo.GetBaseSalary
    @employee_id INT,
    @base_salary DECIMAL(10,2) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1 @base_salary = ss.base_salary
    FROM dbo.Employees e
    JOIN dbo.SalaryStructure ss ON e.department_id = ss.department_id
    WHERE e.employee_id = @employee_id;

    IF @base_salary IS NULL
    BEGIN
        SET @base_salary = 0;
    END
END
GO


-- run this (9 june 2025)
CREATE OR ALTER PROCEDURE dbo.GetUnexcusedAbsences
    @employee_id INT,
    @month INT,
    @year INT,
    @absent_days INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @absent_days = COUNT(*)
    FROM dbo.Attendance a
    WHERE a.employee_id = @employee_id
      AND MONTH(a.date) = @month
      AND YEAR(a.date) = @year
      AND a.status = 'Absent'
      AND NOT EXISTS (
          SELECT 1
          FROM dbo.Leaves l
          JOIN dbo.LeaveStatus ls ON ls.status_id = l.status_id
          WHERE l.employee_id = a.employee_id
            AND l.leave_date = a.date
            AND ls.status = 'Approved'
      );

    IF @absent_days IS NULL
        SET @absent_days = 0;
END
GO

-- run this (9 june 2025)
CREATE OR ALTER PROCEDURE dbo.GetOvertimeAndFoodAllowance
    @employee_id INT,
    @month INT,
    @year INT,
    @overtime_hours INT OUTPUT,
    @food_allowance DECIMAL(10,2) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        @overtime_hours = ISNULL(SUM(a.overtime_hours), 0),
        @food_allowance = ISNULL(SUM(CASE 
                                        WHEN CAST(a.check_out AS TIME) >= '22:00:00' 
                                        THEN 1000 
                                        ELSE 0 
                                     END), 0)
    FROM dbo.Attendance a
    WHERE a.employee_id = @employee_id
      AND MONTH(a.date) = @month
      AND YEAR(a.date) = @year;

    -- Redundant null checks, but kept for defensive coding
    IF @overtime_hours IS NULL SET @overtime_hours = 0;
    IF @food_allowance IS NULL SET @food_allowance = 0;
END
GO

-- run this (9 june 2025)
CREATE OR ALTER PROCEDURE dbo.CalculateTax
    @base_salary DECIMAL(10,2),
    @tax DECIMAL(10,2) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF @base_salary < 0
    BEGIN
        SET @tax = 0;
        RETURN;
    END

    IF @base_salary <= 50000
        SET @tax = 0;
    ELSE IF @base_salary <= 100000
        SET @tax = @base_salary * 0.05;
    ELSE IF @base_salary <= 200000
        SET @tax = @base_salary * 0.10;
    ELSE
        SET @tax = @base_salary * 0.15;
END
GO


-- run this (9 june 2025)
CREATE OR ALTER PROCEDURE SetGradeBonus
    @grade INT,
    @bonus_month INT,
    @bonus_year INT,
    @bonus_amount DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @grade_id INT;
    SELECT @grade_id = grade_id FROM Grades WHERE grade = @grade;

    IF @grade_id IS NULL
    BEGIN
        RAISERROR('Grade not found.', 16, 1);
        RETURN;
    END

    IF EXISTS (
        SELECT 1 FROM GradeBonus
        WHERE grade_id = @grade_id AND bonus_month = @bonus_month AND bonus_year = @bonus_year
    )
    BEGIN
        UPDATE GradeBonus
        SET bonus_amount = @bonus_amount
        WHERE grade_id = @grade_id AND bonus_month = @bonus_month AND bonus_year = @bonus_year;
    END
    ELSE
    BEGIN
        INSERT INTO GradeBonus (grade_id, bonus_month, bonus_year, bonus_amount)
        VALUES (@grade_id, @bonus_month, @bonus_year, @bonus_amount);
    END
END;




-- run this (9 june 2025)
CREATE OR ALTER PROCEDURE UpsertPayrollRecord
    @employee_id INT,
    @month VARCHAR(20),
    @year INT,
    @base_salary DECIMAL(10,2),
    @deductions DECIMAL(10,2),
    @bonus DECIMAL(10,2),
    @absence_deduction DECIMAL(10,2),
    @overtime_hours INT,
    @food_allowance DECIMAL(10,2),
    @tax DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1 FROM Payroll
        WHERE employee_id = @employee_id AND pay_month = @month AND pay_year = @year
    )
    BEGIN
        -- Update existing record without net_salary (computed)
        UPDATE Payroll
        SET 
            base_salary = @base_salary,
            deductions = @deductions,
            bonus = @bonus,
            absence_deduction = @absence_deduction,
            overtime_hours = @overtime_hours,
            food_allowance = @food_allowance,
            tax = @tax
        WHERE employee_id = @employee_id AND pay_month = @month AND pay_year = @year;
    END
    ELSE
    BEGIN
        -- Insert new record without net_salary (computed)
        INSERT INTO Payroll (
            employee_id, pay_month, pay_year, base_salary, deductions, bonus, 
            absence_deduction, overtime_hours, food_allowance, tax
        ) VALUES (
            @employee_id, @month, @year, @base_salary, @deductions, @bonus, 
            @absence_deduction, @overtime_hours, @food_allowance, @tax
        );
    END
END
GO

-- run this (9 june 2025)
ALTER PROCEDURE UpdatePayroll
    @emp_id INT,
    @month VARCHAR(2),
    @year INT,
    @base_salary DECIMAL(10, 2),
    @bonus DECIMAL(10, 2),
    @total_deductions DECIMAL(10, 2),
    @tax DECIMAL(10, 2),
    @absence_deduction DECIMAL(10, 2),
    @food_allowance DECIMAL(10, 2),
    @overtime_hours INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @overtime_pay DECIMAL(10, 2);
    SET @overtime_pay = @overtime_hours * 200;  -- assuming 200 per hour overtime rate

    DECLARE @net_salary DECIMAL(10, 2);
    SET @net_salary = @base_salary 
                      + @bonus 
                      + @overtime_pay 
                      + @food_allowance
                      - @absence_deduction
                      - @total_deductions
                      - @tax;

    -- Update or insert into Payroll table
    IF EXISTS (SELECT 1 FROM Payroll WHERE employee_id = @emp_id AND pay_month = @month AND pay_year = @year)
    BEGIN
        UPDATE Payroll
        SET base_salary = @base_salary,
            bonus = @bonus,
            overtime_hours = @overtime_hours,
            food_allowance = @food_allowance,
            absence_deduction = @absence_deduction,
            tax = @tax,
            deductions = @total_deductions,
            net_salary = @net_salary
        WHERE employee_id = @emp_id AND pay_month = @month AND pay_year = @year;
    END
    ELSE
    BEGIN
        INSERT INTO Payroll (
            employee_id, pay_month, pay_year, base_salary, bonus,
            overtime_hours, food_allowance, absence_deduction,
            tax, deductions, net_salary
        )
        VALUES (
            @emp_id, @month, @year, @base_salary, @bonus,
            @overtime_hours, @food_allowance, @absence_deduction,
            @tax, @total_deductions, @net_salary
        );
    END
END;








