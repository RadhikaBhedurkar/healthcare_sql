-- Use a dedicated database

CREATE DATABASE IF NOT EXISTS hms;

USE hms;


-- Departments

CREATE TABLE department (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  location VARCHAR(100),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- Users / Staff (doctors, nurses, receptionists, admin)

CREATE TABLE staff (
  id INT AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(50) NOT NULL,
  last_name VARCHAR(50) NOT NULL,
  role ENUM('doctor','nurse','receptionist','admin','lab_tech') NOT NULL,
  email VARCHAR(100) UNIQUE,
  phone VARCHAR(20),
  department_id INT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (department_id) REFERENCES department(id) ON DELETE SET NULL
);


-- Doctor details (optional extra info)

CREATE TABLE doctor (
  id INT PRIMARY KEY, -- references staff.id
  speciality VARCHAR(100),
  license_number VARCHAR(50) UNIQUE,
  consulting_fee DECIMAL(10,2) DEFAULT 0,
  FOREIGN KEY (id) REFERENCES staff(id) ON DELETE CASCADE
);


-- Patients

CREATE TABLE patient (
  id INT AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(80) NOT NULL,
  last_name VARCHAR(80) NOT NULL,
  dob DATE,
  gender ENUM('M','F','Other'),
  phone VARCHAR(20),
  email VARCHAR(100),
  address TEXT,
  blood_group VARCHAR(5),
  emergency_contact_name VARCHAR(100),
  emergency_contact_phone VARCHAR(20),
  insurance_provider VARCHAR(100),
  insurance_number VARCHAR(100),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- Rooms (for admissions)

CREATE TABLE room (
  id INT AUTO_INCREMENT PRIMARY KEY,
  room_no VARCHAR(20) UNIQUE,
  type ENUM('single','double','icu','ward') DEFAULT 'ward',
  status ENUM('available','occupied','maintenance') DEFAULT 'available'
);


-- Appointments

CREATE TABLE appointment (
  id INT AUTO_INCREMENT PRIMARY KEY,
  patient_id INT NOT NULL,
  doctor_id INT NOT NULL,
  department_id INT,
  scheduled_start DATETIME NOT NULL,
  scheduled_end DATETIME NOT NULL,
  status ENUM('scheduled','checked_in','completed','cancelled','no_show') DEFAULT 'scheduled',
  reason VARCHAR(255),
  created_by INT, -- staff who made the appointment
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (patient_id) REFERENCES patient(id) ON DELETE CASCADE,
  FOREIGN KEY (doctor_id) REFERENCES staff(id) ON DELETE CASCADE,
  FOREIGN KEY (department_id) REFERENCES department(id) ON DELETE SET NULL,
  FOREIGN KEY (created_by) REFERENCES staff(id) ON DELETE SET NULL,
  INDEX (doctor_id, scheduled_start),
  INDEX (patient_id, scheduled_start)
);


-- Visits (when patient actually comes in)

CREATE TABLE visit (
  id INT AUTO_INCREMENT PRIMARY KEY,
  appointment_id INT,
  patient_id INT NOT NULL,
  doctor_id INT,
  visit_start DATETIME DEFAULT CURRENT_TIMESTAMP,
  visit_end DATETIME,
  visit_type ENUM('outpatient','inpatient','telemedicine') DEFAULT 'outpatient',
  notes TEXT,
  room_id INT,
  FOREIGN KEY (appointment_id) REFERENCES appointment(id) ON DELETE SET NULL,
  FOREIGN KEY (patient_id) REFERENCES patient(id) ON DELETE CASCADE,
  FOREIGN KEY (doctor_id) REFERENCES staff(id) ON DELETE SET NULL,
  FOREIGN KEY (room_id) REFERENCES room(id) ON DELETE SET NULL,
  INDEX (patient_id),
  INDEX (doctor_id)
);


-- Medication catalog

CREATE TABLE medication (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  brand VARCHAR(100),
  unit VARCHAR(20),
  stock INT DEFAULT 0,
  reorder_level INT DEFAULT 10
);


-- Prescriptions

CREATE TABLE prescription (
  id INT AUTO_INCREMENT PRIMARY KEY,
  visit_id INT NOT NULL,
  patient_id INT NOT NULL,
  doctor_id INT,
  prescribed_on DATETIME DEFAULT CURRENT_TIMESTAMP,
  notes TEXT,
  FOREIGN KEY (visit_id) REFERENCES visit(id) ON DELETE CASCADE,
  FOREIGN KEY (patient_id) REFERENCES patient(id) ON DELETE CASCADE,
  FOREIGN KEY (doctor_id) REFERENCES staff(id) ON DELETE SET NULL
);


-- Prescription items

CREATE TABLE prescription_item (
  id INT AUTO_INCREMENT PRIMARY KEY,
  prescription_id INT NOT NULL,
  medication_id INT NOT NULL,
  dose VARCHAR(100),
  frequency VARCHAR(100),
  duration_days INT,
  instructions TEXT,
  FOREIGN KEY (prescription_id) REFERENCES prescription(id) ON DELETE CASCADE,
  FOREIGN KEY (medication_id) REFERENCES medication(id) ON DELETE RESTRICT
);


-- Lab test catalog

CREATE TABLE lab_test (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  code VARCHAR(50) UNIQUE,
  price DECIMAL(10,2) DEFAULT 0
);


-- Lab orders / results

CREATE TABLE lab_order (
  id INT AUTO_INCREMENT PRIMARY KEY,
  visit_id INT,
  patient_id INT NOT NULL,
  ordered_by INT, -- staff id
  ordered_on DATETIME DEFAULT CURRENT_TIMESTAMP,
  status ENUM('ordered','sample_collected','completed','cancelled') DEFAULT 'ordered',
  total_amount DECIMAL(10,2) DEFAULT 0,
  FOREIGN KEY (visit_id) REFERENCES visit(id) ON DELETE SET NULL,
  FOREIGN KEY (patient_id) REFERENCES patient(id) ON DELETE CASCADE,
  FOREIGN KEY (ordered_by) REFERENCES staff(id) ON DELETE SET NULL
);

CREATE TABLE lab_order_item (
  id INT AUTO_INCREMENT PRIMARY KEY,
  lab_order_id INT NOT NULL,
  lab_test_id INT NOT NULL,
  result_value VARCHAR(200),
  unit VARCHAR(50),
  normal_range VARCHAR(100),
  status ENUM('pending','done') DEFAULT 'pending',
  FOREIGN KEY (lab_order_id) REFERENCES lab_order(id) ON DELETE CASCADE,
  FOREIGN KEY (lab_test_id) REFERENCES lab_test(id) ON DELETE RESTRICT
);


-- Billing / invoices

CREATE TABLE invoice (
  id INT AUTO_INCREMENT PRIMARY KEY,
  patient_id INT NOT NULL,
  visit_id INT,
  invoice_date DATETIME DEFAULT CURRENT_TIMESTAMP,
  total_amount DECIMAL(12,2) DEFAULT 0,
  paid_amount DECIMAL(12,2) DEFAULT 0,
  status ENUM('unpaid','partial','paid','cancelled') DEFAULT 'unpaid',
  remarks TEXT,
  FOREIGN KEY (patient_id) REFERENCES patient(id) ON DELETE CASCADE,
  FOREIGN KEY (visit_id) REFERENCES visit(id) ON DELETE SET NULL,
  INDEX (patient_id)
);


-- Payment transactions

CREATE TABLE payment (
  id INT AUTO_INCREMENT PRIMARY KEY,
  invoice_id INT NOT NULL,
  amount DECIMAL(12,2) NOT NULL,
  payment_mode ENUM('cash','card','insurance','online') DEFAULT 'cash',
  paid_on DATETIME DEFAULT CURRENT_TIMESTAMP,
  reference VARCHAR(200),
  processed_by INT,
  FOREIGN KEY (invoice_id) REFERENCES invoice(id) ON DELETE CASCADE,
  FOREIGN KEY (processed_by) REFERENCES staff(id) ON DELETE SET NULL
);


--  DEPARTMENTS

INSERT INTO department (name, location) VALUES
('General Medicine','Building A'),
('Cardiology','Building B'),
('Orthopedics','Building C'),
('Pediatrics','Building D'),
('Pathology','Lab Wing');


--  STAFF (Doctors + Others)

INSERT INTO staff (first_name, last_name, role, email, phone, department_id) VALUES
('Alice','Sharma','doctor','alice@hms.test','+911111111111',1),
('Rahul','Verma','doctor','rahul@hms.test','+912222222222',2),
('Meena','Iyer','doctor','meena@hms.test','+913333333333',3),
('Sanjay','Kapoor','doctor','sanjay@hms.test','+914444444444',4),
('Neha','Patel','lab_tech','neha@hms.test','+915555555555',5),
('Ravi','Kumar','receptionist','ravi@hms.test','+916666666666',NULL),
('Priya','Singh','admin','priya@hms.test','+917777777777',NULL);


--  DOCTOR DETAILS

INSERT INTO doctor (id, speciality, license_number, consulting_fee) VALUES
(1,'General Physician','LIC1001',300.00),
(2,'Cardiologist','LIC1002',500.00),
(3,'Orthopedic Surgeon','LIC1003',600.00),
(4,'Pediatrician','LIC1004',400.00);


--  PATIENTS

INSERT INTO patient (first_name, last_name, dob, gender, phone, email, address, blood_group, insurance_provider, insurance_number) VALUES
('Sunita','Desai','1985-07-12','F','+919988776655','sunita@example.com','Pune, MH','B+','HealthInsure','INS1001'),
('Amit','Joshi','1990-03-02','M','+919977665544','amit@example.com','Mumbai, MH','O+','MediCare','INS1002'),
('Rohit','Patel','1978-12-21','M','+919933445566','rohit@example.com','Nashik, MH','A+','HealthSecure','INS1003'),
('Sneha','Nair','1995-11-09','F','+919922334455','sneha@example.com','Nagpur, MH','AB+','CarePlus','INS1004'),
('Arjun','Reddy','2005-02-15','M','+919911223344','arjun@example.com','Hyderabad, TS','O-','MediLife','INS1005'),
('Manisha','Pillai','1989-04-27','F','+919988112233','manisha@example.com','Thane, MH','A-','LifeCare','INS1006'),
('Vikram','Shah','1975-10-18','M','+919977889900','vikram@example.com','Pune, MH','B-','HealthFirst','INS1007');


--  ROOMS

INSERT INTO room (room_no, type, status) VALUES
('101','single','available'),
('102','double','occupied'),
('103','icu','available'),
('104','ward','maintenance'),
('105','single','available');


--  MEDICATIONS

INSERT INTO medication (name, brand, unit, stock, reorder_level) VALUES
('Paracetamol','Acme','500mg tablet',200,20),
('Amoxicillin','PharmaCo','250mg capsule',120,30),
('Ibuprofen','MedPlus','400mg tablet',180,25),
('Cough Syrup','HealthCare','100ml bottle',90,10),
('Azithromycin','Wellness','500mg tablet',150,25),
('Vitamin C','Nutra','1000mg tablet',300,50),
('Antacid','Relief','200ml bottle',80,20);


--  LAB TESTS

INSERT INTO lab_test (name, code, price) VALUES
('Complete Blood Count','CBC',250.00),
('Lipid Profile','LIPID',800.00),
('Blood Sugar','BS',150.00),
('Thyroid Panel','THY',600.00),
('Liver Function Test','LFT',700.00);


--  APPOINTMENTS

INSERT INTO appointment (patient_id, doctor_id, department_id, scheduled_start, scheduled_end, status, reason, created_by) VALUES
(1,1,1,'2025-10-18 10:00:00','2025-10-18 10:20:00','completed','Fever and cough',6),
(2,2,2,'2025-10-18 11:00:00','2025-10-18 11:30:00','completed','Chest pain',6),
(3,3,3,'2025-10-18 12:00:00','2025-10-18 12:30:00','completed','Knee pain',6),
(4,4,4,'2025-10-18 13:00:00','2025-10-18 13:30:00','scheduled','Flu symptoms',6),
(5,1,1,'2025-10-19 10:00:00','2025-10-19 10:20:00','scheduled','Regular check-up',6),
(6,2,2,'2025-10-19 11:00:00','2025-10-19 11:30:00','cancelled','Chest discomfort',6),
(7,3,3,'2025-10-20 09:30:00','2025-10-20 10:00:00','no_show','Back pain',6);


--  VISITS

INSERT INTO visit (appointment_id, patient_id, doctor_id, visit_start, visit_end, visit_type, notes, room_id) VALUES
(1,1,1,'2025-10-18 10:00:00','2025-10-18 10:25:00','outpatient','Prescribed paracetamol and rest',NULL),
(2,2,2,'2025-10-18 11:00:00','2025-10-18 11:40:00','outpatient','Suggested ECG and blood test',NULL),
(3,3,3,'2025-10-18 12:05:00','2025-10-18 12:40:00','outpatient','Advised physiotherapy',NULL);


--  PRESCRIPTIONS

INSERT INTO prescription (visit_id, patient_id, doctor_id, prescribed_on, notes) VALUES
(1,1,1,'2025-10-18 10:25:00','Take rest and stay hydrated'),
(2,2,2,'2025-10-18 11:40:00','Avoid heavy meals, take meds for 5 days'),
(3,3,3,'2025-10-18 12:40:00','Use pain relief gel and perform exercises');


--  PRESCRIPTION ITEMS

INSERT INTO prescription_item (prescription_id, medication_id, dose, frequency, duration_days, instructions) VALUES
(1,1,'1 tablet','twice a day',3,'After meals'),
(2,2,'1 capsule','thrice a day',5,'Before meals'),
(2,5,'1 tablet','once a day',5,'After dinner'),
(3,3,'1 tablet','twice a day',7,'Take with water');


--  LAB ORDERS

INSERT INTO lab_order (visit_id, patient_id, ordered_by, ordered_on, status, total_amount) VALUES
(2,2,2,'2025-10-18 11:45:00','completed',950.00),
(1,1,1,'2025-10-18 10:30:00','completed',250.00);

INSERT INTO lab_order_item (lab_order_id, lab_test_id, result_value, unit, normal_range, status) VALUES
(1,1,'Normal','N/A','Normal','done'),
(1,2,'Slightly High','mg/dL','<200','done'),
(2,1,'Normal','N/A','Normal','done');


--  INVOICES

INSERT INTO invoice (patient_id, visit_id, invoice_date, total_amount, paid_amount, status, remarks) VALUES
(1,1,'2025-10-18 10:45:00',550.00,550.00,'paid','Consultation + Lab test'),
(2,2,'2025-10-18 11:50:00',1450.00,1000.00,'partial','Consultation + Lab test'),
(3,3,'2025-10-18 12:45:00',600.00,0.00,'unpaid','Consultation only');


--  PAYMENTS

INSERT INTO payment (invoice_id, amount, payment_mode, paid_on, reference, processed_by) VALUES
(1,550.00,'cash','2025-10-18 10:50:00','CASH-001',6),
(2,500.00,'card','2025-10-18 12:00:00','CARD-002',6),
(2,500.00,'insurance','2025-10-19 09:00:00','INS-002',7);


-- List all patients with their name, gender, and contact number.

SELECT first_name, last_name, gender, phone
FROM patient;


-- Show all doctors and their specializations.

SELECT s.first_name, s.last_name, d.speciality
FROM staff s
JOIN doctor d ON s.id = d.id;


-- Display the departments available in the hospital.

SELECT id, name, location FROM department;


-- Show all available rooms (not occupied or under maintenance).

SELECT room_no, type, status
FROM room
WHERE status = 'available';


-- Find the email addresses of all staff members working in Cardiology.

SELECT s.first_name, s.last_name, s.email
FROM staff s
JOIN department d ON s.department_id = d.id
WHERE d.name = 'Cardiology';


-- Show all appointments scheduled for 2025-10-18 with patient and doctor names.

SELECT a.id AS Appointment_ID,
       p.first_name AS Patient,
       d.first_name AS Doctor,
       a.scheduled_start,
       a.status
FROM appointment a
JOIN patient p ON a.patient_id = p.id
JOIN staff d ON a.doctor_id = d.id
WHERE DATE(a.scheduled_start) = '2025-10-18';


-- Find all patients treated by Dr. Alice Sharma.

SELECT DISTINCT p.first_name, p.last_name
FROM appointment a
JOIN patient p ON a.patient_id = p.id
JOIN staff s ON a.doctor_id = s.id
WHERE s.first_name = 'Alice' AND s.last_name = 'Sharma';


-- Display all invoices along with the patient name and payment status.

SELECT i.id AS Invoice_ID,
       p.first_name AS Patient,
       i.total_amount,
       i.paid_amount,
       i.status
FROM invoice i
JOIN patient p ON i.patient_id = p.id;


-- Show all lab orders along with test names and results.

SELECT lo.id AS Lab_Order_ID,
       p.first_name AS Patient,
       lt.name AS Test_Name,
       loi.result_value,
       loi.status
FROM lab_order lo
JOIN patient p ON lo.patient_id = p.id
JOIN lab_order_item loi ON lo.id = loi.lab_order_id
JOIN lab_test lt ON loi.lab_test_id = lt.id;


-- List all prescriptions given by Dr. Rahul Verma.

SELECT pr.id AS Prescription_ID, p.first_name AS Patient, pr.prescribed_on
FROM prescription pr
JOIN patient p ON pr.patient_id = p.id
JOIN staff s ON pr.doctor_id = s.id
WHERE s.first_name = 'Rahul' AND s.last_name = 'Verma';


-- Find the number of appointments handled by each doctor.

SELECT s.first_name AS Doctor, COUNT(a.id) AS Total_Appointments
FROM appointment a
JOIN staff s ON a.doctor_id = s.id
GROUP BY s.id;


-- Calculate the total revenue collected per doctor (from invoices).

SELECT s.first_name AS Doctor, SUM(i.paid_amount) AS Total_Revenue
FROM invoice i
JOIN visit v ON i.visit_id = v.id
JOIN staff s ON v.doctor_id = s.id
GROUP BY s.id;


-- Show how many patients belong to each blood group.

SELECT blood_group, COUNT(*) AS Total_Patients
FROM patient
GROUP BY blood_group;


-- Find the average consulting fee charged by all doctors.

SELECT ROUND(AVG(consulting_fee),2) AS Avg_Consulting_Fee
FROM doctor;


-- Count the number of appointments by their status (scheduled, completed, cancelled).

SELECT status, COUNT(*) AS Count
FROM appointment
GROUP BY status;


-- Find patients who have unpaid or partially paid invoices.

SELECT DISTINCT p.first_name, p.last_name, i.status
FROM invoice i
JOIN patient p ON i.patient_id = p.id
WHERE i.status IN ('unpaid','partial');


-- Find the doctor with the highest number of appointments.

SELECT s.first_name, s.last_name, COUNT(a.id) AS Total_Appointments
FROM appointment a
JOIN staff s ON a.doctor_id = s.id
GROUP BY s.id
ORDER BY Total_Appointments DESC
LIMIT 1;


-- Find medications that are low in stock.

SELECT name, stock, reorder_level
FROM medication
WHERE stock <= reorder_level;


-- Find patients who took lab tests costing more than ₹500.

SELECT DISTINCT p.first_name, p.last_name, lt.name AS Test_Name, lt.price
FROM lab_order lo
JOIN lab_order_item loi ON lo.id = loi.lab_order_id
JOIN lab_test lt ON loi.lab_test_id = lt.id
JOIN patient p ON lo.patient_id = p.id
WHERE lt.price > 500;


-- Find the total amount due (unpaid) for each patient.

SELECT p.first_name, p.last_name,
       SUM(i.total_amount - i.paid_amount) AS Outstanding_Balance
FROM invoice i
JOIN patient p ON p.id = i.patient_id
GROUP BY p.id
HAVING Outstanding_Balance > 0;


-- Find the most common reason for appointments.

SELECT reason, COUNT(*) AS Count
FROM appointment
GROUP BY reason
ORDER BY Count DESC
LIMIT 1;


-- Show patients who visited more than once.

SELECT p.first_name, p.last_name, COUNT(v.id) AS Total_Visits
FROM visit v
JOIN patient p ON p.id = v.patient_id
GROUP BY p.id
HAVING COUNT(v.id) > 1;


-- Calculate the daily revenue collected (from payments).

SELECT DATE(paid_on) AS Date, SUM(amount) AS Daily_Revenue
FROM payment
GROUP BY DATE(paid_on)
ORDER BY Date;


-- List all patients who had lab tests and prescriptions on the same day.

SELECT DISTINCT p.first_name, p.last_name
FROM patient p
JOIN lab_order lo ON p.id = lo.patient_id
JOIN prescription pr ON p.id = pr.patient_id
WHERE DATE(lo.ordered_on) = DATE(pr.prescribed_on);


-- Show top 3 highest-paying patients (by total paid amount).

SELECT p.first_name, p.last_name, SUM(pay.amount) AS Total_Paid
FROM payment pay
JOIN invoice i ON pay.invoice_id = i.id
JOIN patient p ON i.patient_id = p.id
GROUP BY p.id
ORDER BY Total_Paid DESC
LIMIT 3;


-- Show which receptionist created each appointment.

SELECT a.id AS Appointment_ID, p.first_name AS Patient,
       s.first_name AS Receptionist
FROM appointment a
JOIN patient p ON p.id = a.patient_id
JOIN staff s ON a.created_by = s.id;


-- Find doctors who have not received any appointments.

SELECT s.first_name, s.last_name
FROM staff s
JOIN doctor d ON s.id = d.id
WHERE s.id NOT IN (SELECT doctor_id FROM appointment);


-- Show all medications prescribed by Dr. Meena Iyer.

SELECT m.name, pi.dose, pi.duration_days, p.first_name AS Patient
FROM prescription_item pi
JOIN prescription pr ON pi.prescription_id = pr.id
JOIN medication m ON m.id = pi.medication_id
JOIN patient p ON p.id = pr.patient_id
JOIN staff s ON s.id = pr.doctor_id
WHERE s.first_name = 'Meena' AND s.last_name = 'Iyer';


-- Display each doctor and their total number of patients treated.

SELECT s.first_name AS Doctor, COUNT(DISTINCT v.patient_id) AS Unique_Patients
FROM visit v
JOIN staff s ON s.id = v.doctor_id
GROUP BY s.id;


-- Find the department with the highest total appointments.

SELECT d.name AS Department, COUNT(a.id) AS Total_Appointments
FROM appointment a
JOIN department d ON a.department_id = d.id
GROUP BY d.id
ORDER BY Total_Appointments DESC
LIMIT 1;
