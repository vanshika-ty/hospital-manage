
--create database with functions 

CREATE DATABASE IF NOT EXISTS hospital_db;

USE hospital_db;

-- Disable FK checks temporarily so the script can be safely re-run.
SET FOREIGN_KEY_CHECKS = 0;

-- PHASE 1: SCHEMA DESIGN — CREATE TABLES

-- Drop tables if they exist (safe re-run)

DROP TABLE IF EXISTS billing;
DROP TABLE IF EXISTS prescriptions;
DROP TABLE IF EXISTS medical_records;
DROP TABLE IF EXISTS appointments;
DROP TABLE IF EXISTS room_assignments;
DROP TABLE IF EXISTS rooms;
DROP TABLE IF EXISTS nurses;
DROP TABLE IF EXISTS medications;
DROP TABLE IF EXISTS patients;
DROP TABLE IF EXISTS doctors;
DROP TABLE IF EXISTS departments;
SET FOREIGN_KEY_CHECKS = 1;
SET FOREIGN_KEY_CHECKS = 1;

-- 1. departments

CREATE TABLE departments (
    department_id   INT PRIMARY KEY AUTO_INCREMENT,
    dept_name       VARCHAR(100) NOT NULL,
    location        VARCHAR(100),
    head_doctor_id  INT                        -- FK added later
);

-- 2. doctors

CREATE TABLE doctors (
    doctor_id       INT PRIMARY KEY AUTO_INCREMENT,
    first_name      VARCHAR(50)  NOT NULL,
    last_name       VARCHAR(50)  NOT NULL,
    specialization  VARCHAR(100),
    department_id   INT,
    phone           VARCHAR(20),
    email           VARCHAR(100) UNIQUE,
    joining_date    DATE,
    salary          DECIMAL(10,2),
    FOREIGN KEY (department_id) REFERENCES departments(department_id)

);

-- Add the department head foreign key after doctors exists.
ALTER TABLE departments
    ADD CONSTRAINT fk_departments_head_doctor
    FOREIGN KEY (head_doctor_id) REFERENCES doctors(doctor_id);

-- 3. patients

CREATE TABLE patients (
    patient_id      INT PRIMARY KEY AUTO_INCREMENT,
    first_name      VARCHAR(50)  NOT NULL,
    last_name       VARCHAR(50)  NOT NULL,
    date_of_birth   DATE,
    gender          ENUM('Male','Female','Other'),
    blood_group     VARCHAR(5),
    phone           VARCHAR(20),
    email           VARCHAR(100),
    address         TEXT,
    registered_on   DATE DEFAULT (CURRENT_DATE)
);

-- 4. nurses

CREATE TABLE nurses (
    nurse_id        INT PRIMARY KEY AUTO_INCREMENT,
    first_name      VARCHAR(50) NOT NULL,
    last_name       VARCHAR(50) NOT NULL,
    department_id   INT,
    phone           VARCHAR(20),
    shift           ENUM('Morning','Evening','Night'),
    FOREIGN KEY (department_id) REFERENCES departments(department_id)
);

-- 5. rooms

CREATE TABLE rooms (
    room_id         INT PRIMARY KEY AUTO_INCREMENT,
    room_number     VARCHAR(10) NOT NULL UNIQUE,
    room_type       ENUM('General','Semi-Private','Private','ICU'),
    department_id   INT,
    is_available    BOOLEAN DEFAULT TRUE,
    price_per_day   DECIMAL(8,2),
    FOREIGN KEY (department_id) REFERENCES departments(department_id)
);

-- 6. appointments

CREATE TABLE appointments (
    appointment_id  INT PRIMARY KEY AUTO_INCREMENT,
    patient_id      INT NOT NULL,
    doctor_id       INT NOT NULL,
    appointment_date DATE NOT NULL,
    appointment_time TIME,
    reason          VARCHAR(255),
    status          ENUM('Scheduled','Completed','Cancelled') DEFAULT 'Scheduled',
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    FOREIGN KEY (doctor_id)  REFERENCES doctors(doctor_id)
);

-- 7. medical_records

CREATE TABLE medical_records (
    record_id       INT PRIMARY KEY AUTO_INCREMENT,
    patient_id      INT NOT NULL,
    doctor_id       INT NOT NULL,
    visit_date      DATE NOT NULL,
    diagnosis       TEXT,
    treatment       TEXT,
    notes           TEXT,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    FOREIGN KEY (doctor_id)  REFERENCES doctors(doctor_id)
);

-- 8. medications

CREATE TABLE medications (
    medication_id   INT PRIMARY KEY AUTO_INCREMENT,
    med_name        VARCHAR(100) NOT NULL,
    category        VARCHAR(100),
    manufacturer    VARCHAR(100),
    unit_price      DECIMAL(8,2),
    stock_qty       INT DEFAULT 0
);

-- 9. prescriptions

CREATE TABLE prescriptions (
    prescription_id INT PRIMARY KEY AUTO_INCREMENT,
    record_id       INT NOT NULL,
    medication_id   INT NOT NULL,
    dosage          VARCHAR(100),
    duration_days   INT,
    prescribed_date DATE,
    FOREIGN KEY (record_id)     REFERENCES medical_records(record_id),
    FOREIGN KEY (medication_id) REFERENCES medications(medication_id)
);

-- 10. billing

CREATE TABLE billing (

    bill_id         INT PRIMARY KEY AUTO_INCREMENT,

    patient_id      INT NOT NULL,

    appointment_id  INT,

    bill_date       DATE NOT NULL,

    room_charges    DECIMAL(10,2) DEFAULT 0,

    doctor_fees     DECIMAL(10,2) DEFAULT 0,

    medication_cost DECIMAL(10,2) DEFAULT 0,

    other_charges   DECIMAL(10,2) DEFAULT 0,

    total_amount    DECIMAL(10,2),

    payment_status  ENUM('Paid','Pending','Partial') DEFAULT 'Pending',

    FOREIGN KEY (patient_id)    REFERENCES patients(patient_id),

    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id)

);

-- 11. room_assignments

CREATE TABLE room_assignments (

    assignment_id   INT PRIMARY KEY AUTO_INCREMENT,

    patient_id      INT NOT NULL,

    room_id         INT NOT NULL,

    admitted_on     DATE NOT NULL,

    discharged_on   DATE,

    FOREIGN KEY (patient_id) REFERENCES patients(patient_id),

    FOREIGN KEY (room_id)    REFERENCES rooms(room_id)

);

-- PHASE 2: INSERT CUSTOMIZED FICTIONAL SAMPLE DATA
-- Names, contact details, locations, room labels, and sample encounter dates are fictionalized for this project.

-- departments

INSERT INTO departments (dept_name, location) VALUES

('Cardiology',        'North Wing - Level 2'),

('Neurology',         'North Wing - Level 3'),

('Orthopedics',       'East Wing - Level 1'),

('Pediatrics',        'Children Wing - Level 1'),

('Oncology',          'Specialty Wing - Level 4'),

('Emergency',         'Emergency Wing - Ground Floor'),

('Dermatology',       'Outpatient Wing - Level 1'),

('Gynecology',        'Children Wing - Level 2');

-- doctors

INSERT INTO doctors (first_name, last_name, specialization, department_id, phone, email, joining_date, salary) VALUES

('Aarav',    'Malhotra',    'Cardiologist',        1, '9112304001', 'aarav.malhotra@hospital.com',    '2018-03-15', 186500),

('Ishita',    'Bansal',     'Neurologist',         2, '9112304002', 'ishita.bansal@hospital.com',     '2019-07-01', 178500),

('Kabir',    'Saxena',     'Orthopedic Surgeon',  3, '9112304003', 'kabir.saxena@hospital.com',     '2017-11-20', 194000),

('Nandini',   'Kapoor',       'Pediatrician',        4, '9112304004', 'nandini.kapoor@hospital.com',      '2020-01-10', 163500),

('Aditya',   'Chauhan',     'Oncologist',          5, '9112304005', 'aditya.chauhan@hospital.com',    '2016-05-22', 218000),

('Rhea',  'Sethi',      'Emergency Medicine',  6, '9112304006', 'rhea.sethi@hospital.com',    '2021-08-05', 158000),

('Yash',   'Arora',     'Dermatologist',       7, '9112304007', 'yash.arora@hospital.com',    '2022-02-14', 149500),

('Aditi',   'Khanna',     'Gynecologist',        8, '9112304008', 'aditi.khanna@hospital.com',    '2019-09-30', 171000),

('Vihaan',    'Bhatia',    'Cardiologist',        1, '9112304009', 'vihaan.bhatia@hospital.com',    '2020-06-18', 176000),

('Tanya',    'Ahuja',       'Neurologist',         2, '9112304010', 'tanya.ahuja@hospital.com',       '2021-03-25', 173500);

-- Update department heads

UPDATE departments SET head_doctor_id = 1 WHERE department_id = 1;

UPDATE departments SET head_doctor_id = 2 WHERE department_id = 2;

UPDATE departments SET head_doctor_id = 3 WHERE department_id = 3;

UPDATE departments SET head_doctor_id = 4 WHERE department_id = 4;

UPDATE departments SET head_doctor_id = 5 WHERE department_id = 5;

UPDATE departments SET head_doctor_id = 6 WHERE department_id = 6;

UPDATE departments SET head_doctor_id = 7 WHERE department_id = 7;

UPDATE departments SET head_doctor_id = 8 WHERE department_id = 8;

-- patients

INSERT INTO patients (first_name, last_name, date_of_birth, gender, blood_group, phone, email, address, registered_on) VALUES

('Dev',       'Rathore',      '1985-04-12', 'Male',   'O+',  '9123405001', 'dev.rathore@gmail.com',      'Vaishali Nagar, Jaipur',          '2023-01-05'),

('Myra',      'Chopra',      '1990-07-22', 'Female', 'A+',  '9123405002', 'myra.chopra@gmail.com',     'Malviya Nagar, Jaipur',      '2023-01-18'),

('Nikhil',       'Joshi',    '1975-11-03', 'Male',   'B+',  '9123405003', 'nikhil.joshi@gmail.com',          'Mansarovar, Jaipur',      '2023-02-10'),

('Tara',      'Menon',       '2000-05-30', 'Female', 'AB-', '9123405004', 'tara.menon@gmail.com',      'C-Scheme, Jaipur',        '2023-02-14'),

('Kunal',     'Agarwal',       '1965-09-15', 'Male',   'A-',  '9123405005', 'kunal.agarwal@gmail.com',     'Jagatpura, Jaipur',       '2023-03-01'),

('Anaya',    'Purohit',       '1995-12-28', 'Female', 'O-',  '9123405006', 'anaya.purohit@gmail.com',       'Vidhyadhar Nagar, Jaipur',       '2023-03-20'),

('Rohan',      'Sood',      '1988-08-08', 'Male',   'B-',  '9123405007', 'rohan.sood@gmail.com',         'Pratap Nagar, Jaipur',       '2023-04-05'),

('Kiara',      'Bedi',       '2005-02-14', 'Female', 'AB+', '9123405008', 'kiara.bedi@gmail.com',      'Bani Park, Jaipur',     '2023-04-22'),

('Manav',     'Goyal',     '1970-06-19', 'Male',   'O+',  '9123405009', 'manav.goyal@gmail.com',        'Shyam Nagar, Jaipur',      '2023-05-10'),

('Sanya',      'Bose',      '1998-03-07', 'Female', 'A+',  '9123405010', 'sanya.bose@gmail.com',         'Civil Lines, Jaipur',     '2023-05-25'),

('Parth',      'Sethi',       '1982-01-25', 'Male',   'B+',  '9123405011', 'parth.sethi@gmail.com',         'Sanganer, Jaipur',  '2023-06-08'),

('Ira',    'Dutta',   '1992-10-11', 'Female', 'O+',  '9123405012', 'ira.dutta@gmail.com',       'Gopalpura, Jaipur',        '2023-06-19'),

('Ayaan',     'Gill',     '1960-07-04', 'Male',   'A-',  '9123405013', 'ayaan.gill2@gmail.com',        'Ajmer Road, Jaipur',        '2023-07-03'),

('Meher',     'Talwar',        '2002-09-17', 'Female', 'B+',  '9123405014', 'meher.talwar@gmail.com',        'Tonk Road, Jaipur',           '2023-07-15'),

('Reyansh',  'Bhalla',      '1978-12-01', 'Male',   'AB+', '9123405015', 'reyansh.bhalla@gmail.com',     'Jhotwara, Jaipur',       '2023-08-01');

-- nurses

INSERT INTO nurses (first_name, last_name, department_id, phone, shift) VALUES

('Simran',    'D''Souza',  1, '9134506001', 'Morning'),

('Pallavi',    'Bhatia',   1, '9134506002', 'Night'),

('Charu',     'Kohli',    2, '9134506003', 'Morning'),

('Mitali',     'Bajaj',   3, '9134506004', 'Evening'),

('Ritika',   'D''Souza', 4, '9134506005', 'Morning'),

('Neha',     'Malhotra',   5, '9134506006', 'Night'),

('Shreya',  'Rathore',    6, '9134506007', 'Evening'),

('Ishani',   'Sethi',     7, '9134506008', 'Morning');

-- rooms

INSERT INTO rooms (room_number, room_type, department_id, is_available, price_per_day) VALUES

('A101', 'General',      1, TRUE,  800),

('A102', 'Semi-Private', 1, TRUE,  1500),

('A103', 'Private',      1, FALSE, 2500),

('B201', 'General',      2, TRUE,  800),

('B202', 'ICU',          2, FALSE, 5000),

('C301', 'General',      3, TRUE,  800),

('C302', 'Private',      3, TRUE,  2500),

('D401', 'Semi-Private', 4, TRUE,  1500),

('D402', 'General',      4, FALSE, 800),

('E501', 'ICU',          5, TRUE,  5000);

-- medications

INSERT INTO medications (med_name, category, manufacturer, unit_price, stock_qty) VALUES

('Aspirin 75mg',       'Blood Thinner',    'Cipla',    12.50,  500),

('Metformin 500mg',    'Antidiabetic',     'Aster Labs',         8.00,   400),

('Atorvastatin 20mg',  'Cholesterol',      'Zydus',     25.00,  300),

('Amoxicillin 500mg',  'Antibiotic',       'MediCore Labs',        35.00,  350),

('Paracetamol 500mg',  'Analgesic',        'WellSpring Pharma',           5.00,   600),

('Omeprazole 20mg',    'Antacid',          'NovaMed',   18.00,  250),

('Losartan 50mg',      'Antihypertensive', 'Orchid Pharma',         22.00,  200),

('Cetirizine 10mg',    'Antihistamine',    'Helix Healthcare',       10.00,  450),

('Ibuprofen 400mg',    'Anti-inflammatory','CureWell Labs',       15.00,  380),

('Prednisolone 5mg',   'Corticosteroid',   'NorthStar Pharma',     30.00,  180);

-- appointments

INSERT INTO appointments (patient_id, doctor_id, appointment_date, appointment_time, reason, status) VALUES

(1,  1, '2025-01-10', '09:00:00', 'Chest pain and shortness of breath',  'Completed'),

(2,  2, '2025-01-12', '10:30:00', 'Frequent headaches',                  'Completed'),

(3,  3, '2025-01-15', '11:00:00', 'Knee pain',                           'Completed'),

(4,  4, '2025-01-18', '09:30:00', 'Routine child checkup',               'Completed'),

(5,  1, '2025-01-20', '14:00:00', 'High blood pressure follow-up',       'Completed'),

(6,  8, '2025-01-22', '15:30:00', 'Irregular periods',                   'Completed'),

(7,  5, '2025-01-25', '10:00:00', 'Lump in neck',                        'Completed'),

(8,  4, '2025-02-01', '09:00:00', 'Fever and cold',                      'Completed'),

(9,  1, '2025-02-05', '11:30:00', 'Chest tightness',                     'Completed'),

(10, 7, '2025-02-08', '12:00:00', 'Skin rash',                           'Completed'),

(11, 9, '2025-02-10', '10:00:00', 'Heart palpitations',                  'Completed'),

(12, 2, '2025-02-14', '11:00:00', 'Memory loss concerns',                'Completed'),

(13, 6, '2025-02-18', '16:00:00', 'Accident injury - emergency',         'Completed'),

(14, 4, '2025-02-20', '09:00:00', 'Vaccination schedule',                'Completed'),

(15, 3, '2025-02-22', '14:30:00', 'Back pain',                           'Completed'),

(1,  9, '2025-03-05', '10:00:00', 'Post-surgery cardiac checkup',        'Completed'),

(3,  3, '2025-03-10', '11:00:00', 'Physiotherapy follow-up',             'Scheduled'),

(5,  1, '2025-03-15', '14:00:00', 'BP monitoring',                       'Scheduled'),

(7,  5, '2025-03-18', '10:00:00', 'Chemotherapy session 2',              'Scheduled'),

(2,  10,'2025-03-20', '09:30:00', 'MRI review',                          'Cancelled');

-- medical_records

INSERT INTO medical_records (patient_id, doctor_id, visit_date, diagnosis, treatment, notes) VALUES

(1,  1, '2025-01-10', 'Angina pectoris',           'Nitroglycerin prescribed, lifestyle change advised',   'BP: 150/95, ECG normal'),

(2,  2, '2025-01-12', 'Migraine',                  'Sumatriptan prescribed, avoid triggers',               'MRI scheduled'),

(3,  3, '2025-01-15', 'Osteoarthritis - knee',     'Physiotherapy + NSAIDs',                               'X-ray shows mild degeneration'),

(4,  4, '2025-01-18', 'Healthy child',             'Vitamins prescribed',                                  'Weight and height normal for age'),

(5,  1, '2025-01-20', 'Hypertension Stage 2',      'Losartan 50mg daily',                                  'Diet counselling done'),

(6,  8, '2025-01-22', 'PCOS',                      'Hormonal therapy initiated',                           'Ultrasound done'),

(7,  5, '2025-01-25', 'Thyroid lymphoma suspected','Biopsy ordered',                                       'PET scan scheduled'),

(8,  4, '2025-02-01', 'Viral fever',               'Paracetamol + rest',                                   'Temperature 102F, resolving'),

(9,  1, '2025-02-05', 'Coronary artery disease',   'Statin + aspirin therapy',                             'Angiography recommended'),

(10, 7, '2025-02-08', 'Contact dermatitis',        'Topical corticosteroid',                               'Avoid allergen identified'),

(11, 9, '2025-02-10', 'Arrhythmia',                'Beta blockers prescribed',                             'Holter monitor for 24hrs'),

(12, 2, '2025-02-14', 'Early-stage Alzheimer''s',  'Donepezil initiated, family counselling',              'MMSE score: 22/30'),

(13, 6, '2025-02-18', 'Fractured radius',          'Plaster cast applied',                                 'X-ray confirmed fracture'),

(14, 4, '2025-02-20', 'Routine vaccination',       'DPT booster given',                                    'No adverse reaction'),

(15, 3, '2025-02-22', 'Lumbar disc herniation',    'Physical therapy + muscle relaxants',                  'MRI shows L4-L5 disc problem');

-- prescriptions

INSERT INTO prescriptions (record_id, medication_id, dosage, duration_days, prescribed_date) VALUES

(1,  1,  '75mg once daily',              30, '2025-01-10'),

(1,  3,  '20mg at night',               30, '2025-01-10'),

(2,  5,  '500mg as needed for pain',    15, '2025-01-12'),

(3,  9,  '400mg twice daily',           14, '2025-01-15'),

(5,  7,  '50mg once daily',             90, '2025-01-20'),

(5,  3,  '20mg at night',               90, '2025-01-20'),

(8,  5,  '500mg every 6 hours',          5, '2025-02-01'),

(9,  1,  '75mg once daily',             60, '2025-02-05'),

(9,  3,  '40mg at night',               60, '2025-02-05'),

(10, 10, '5mg twice daily for 7 days',   7, '2025-02-08'),

(11, 7,  '50mg once daily',             30, '2025-02-10'),

(13, 5,  '500mg three times daily',     10, '2025-02-18'),

(15, 9,  '400mg three times daily',     21, '2025-02-22'),

(15, 6,  '20mg before meals',           21, '2025-02-22');

-- room_assignments

INSERT INTO room_assignments (patient_id, room_id, admitted_on, discharged_on) VALUES

(1,  3, '2025-01-10', '2025-01-14'),

(5,  1, '2025-01-20', '2025-01-23'),

(7,  10,'2025-01-25', '2025-01-28'),

(9,  2, '2025-02-05', '2025-02-10'),

(11, 3, '2025-02-10', '2025-02-13'),

(13, 6, '2025-02-18', '2025-02-20'),

(15, 7, '2025-02-22', NULL);

-- billing

INSERT INTO billing (patient_id, appointment_id, bill_date, room_charges, doctor_fees, medication_cost, other_charges, total_amount, payment_status) VALUES

(1,  1,  '2025-01-14', 10000, 2000, 750,  500,  13250, 'Paid'),

(2,  2,  '2025-01-12', 0,     1500, 150,  200,   1850, 'Paid'),

(3,  3,  '2025-01-15', 0,     2000, 420,  300,   2720, 'Paid'),

(4,  4,  '2025-01-18', 0,      800, 200,  100,   1100, 'Paid'),

(5,  5,  '2025-01-23', 2400,  2000, 1350, 400,   6150, 'Paid'),

(6,  6,  '2025-01-22', 0,     1500, 0,    300,   1800, 'Pending'),

(7,  7,  '2025-01-28', 15000, 3000, 0,    1000, 19000, 'Partial'),

(8,  8,  '2025-02-01', 0,      800, 125,  100,   1025, 'Paid'),

(9,  9,  '2025-02-10', 20000, 2500, 1850, 800,  25150, 'Pending'),

(10, 10, '2025-02-08', 0,     1200, 210,  200,   1610, 'Paid'),

(11, 11, '2025-02-13', 7500,  2000, 660,  500,  10660, 'Paid'),

(12, 12, '2025-02-14', 0,     2000, 0,    300,   2300, 'Pending'),

(13, 13, '2025-02-20', 1600,  1000, 125,  400,   3125, 'Paid'),

(14, 14, '2025-02-20', 0,      500, 0,    100,    600, 'Paid'),

(15, 15, '2025-02-28', 0,     2000, 945,  300,   3245, 'Pending');

-- PHASE 3: BASIC QUERIES (SELECT, WHERE, ORDER BY)

-- Q1. List all patients registered in 2023

SELECT patient_id, first_name, last_name, gender, registered_on

FROM patients

WHERE YEAR(registered_on) = 2023

ORDER BY registered_on;

-- Q2. Find all male patients with blood group O+

SELECT first_name, last_name, date_of_birth, phone

FROM patients

WHERE gender = 'Male' AND blood_group = 'O+';

-- Q3. List doctors with salary above 170,000

SELECT first_name, last_name, specialization, salary

FROM doctors

WHERE salary > 170000

ORDER BY salary DESC;

-- Q4. Find all appointments that were cancelled

SELECT a.appointment_id, p.first_name, p.last_name,

       d.first_name AS doctor_first, a.appointment_date, a.status

FROM appointments a

JOIN patients p ON a.patient_id = p.patient_id

JOIN doctors  d ON a.doctor_id  = d.doctor_id

WHERE a.status = 'Cancelled';

-- Q5. Find medications with stock less than 250

SELECT med_name, category, stock_qty, unit_price

FROM medications

WHERE stock_qty < 250

ORDER BY stock_qty;

-- PHASE 4: JOINS

-- Q6. List all appointments with patient name, doctor name, date, and status

SELECT

    a.appointment_id,

    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,

    CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,

    dept.dept_name AS department,

    a.appointment_date,

    a.status

FROM appointments a

JOIN patients    p    ON a.patient_id   = p.patient_id

JOIN doctors     d    ON a.doctor_id    = d.doctor_id

JOIN departments dept ON d.department_id = dept.department_id

ORDER BY a.appointment_date;

-- Q7. Show all medical records with patient, doctor, and diagnosis

SELECT

    mr.record_id,

    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,

    CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,

    mr.visit_date,

    mr.diagnosis,

    mr.treatment

FROM medical_records mr

JOIN patients p ON mr.patient_id = p.patient_id

JOIN doctors  d ON mr.doctor_id  = d.doctor_id

ORDER BY mr.visit_date;

-- Q8. List prescriptions with patient name, medication name, dosage

SELECT

    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,

    m.med_name,

    pr.dosage,

    pr.duration_days,

    pr.prescribed_date

FROM prescriptions pr

JOIN medical_records mr ON pr.record_id     = mr.record_id

JOIN patients        p  ON mr.patient_id    = p.patient_id

JOIN medications     m  ON pr.medication_id = m.medication_id

ORDER BY pr.prescribed_date;

-- Q9. LEFT JOIN — Find patients who have NO appointments

SELECT p.patient_id, CONCAT(p.first_name, ' ', p.last_name) AS patient_name, p.phone

FROM patients p

LEFT JOIN appointments a ON p.patient_id = a.patient_id

WHERE a.appointment_id IS NULL;

-- Q10. Show room assignment history with patient and room details

SELECT

    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,

    r.room_number,

    r.room_type,

    dept.dept_name,

    ra.admitted_on,

    ra.discharged_on,

    CASE

        WHEN ra.discharged_on IS NULL THEN 'Currently Admitted'

        ELSE CONCAT(DATEDIFF(ra.discharged_on, ra.admitted_on), ' days')

    END AS stay_duration

FROM room_assignments ra

JOIN patients    p    ON ra.patient_id    = p.patient_id

JOIN rooms       r    ON ra.room_id       = r.room_id

JOIN departments dept ON r.department_id  = dept.department_id

ORDER BY ra.admitted_on;

-- Q11. Billing details with patient and appointment info

SELECT

    b.bill_id,

    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,

    b.bill_date,

    b.room_charges,

    b.doctor_fees,

    b.medication_cost,

    b.other_charges,

    b.total_amount,

    b.payment_status

FROM billing b

JOIN patients p ON b.patient_id = p.patient_id

ORDER BY b.total_amount DESC;

-- PHASE 5: SUBQUERIES

-- Q12. Find patients whose total bill is above the average bill

SELECT

    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,

    b.total_amount

FROM billing b

JOIN patients p ON b.patient_id = p.patient_id

WHERE b.total_amount > (SELECT AVG(total_amount) FROM billing)

ORDER BY b.total_amount DESC;

-- Q13. Find doctors who have handled more than 2 appointments

SELECT

    CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,

    d.specialization

FROM doctors d

WHERE d.doctor_id IN (

    SELECT doctor_id

    FROM appointments

    GROUP BY doctor_id

    HAVING COUNT(*) > 2

);

-- Q14. Find patients admitted to ICU rooms

SELECT CONCAT(p.first_name, ' ', p.last_name) AS patient_name

FROM patients p

WHERE p.patient_id IN (

    SELECT ra.patient_id

    FROM room_assignments ra

    JOIN rooms r ON ra.room_id = r.room_id

    WHERE r.room_type = 'ICU'

);

-- Q15. Find the most expensive medication prescribed

SELECT med_name, unit_price

FROM medications

WHERE unit_price = (SELECT MAX(unit_price) FROM medications);

-- PHASE 6: AGGREGATIONS & GROUP BY

-- Q16. Count appointments per doctor

SELECT

    CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,

    d.specialization,

    COUNT(a.appointment_id) AS total_appointments

FROM doctors d

LEFT JOIN appointments a ON d.doctor_id = a.doctor_id

GROUP BY d.doctor_id, d.first_name, d.last_name, d.specialization

ORDER BY total_appointments DESC;

-- Q17. Total revenue per department

SELECT

    dept.dept_name,

    SUM(b.total_amount)  AS total_revenue,

    COUNT(b.bill_id)     AS total_bills,

    AVG(b.total_amount)  AS avg_bill

FROM billing b

JOIN appointments a    ON b.appointment_id = a.appointment_id

JOIN doctors      d    ON a.doctor_id       = d.doctor_id

JOIN departments  dept ON d.department_id   = dept.department_id

GROUP BY dept.dept_name

ORDER BY total_revenue DESC;

-- Q18. Pending payments summary

SELECT

    payment_status,

    COUNT(*)           AS count,

    SUM(total_amount)  AS total_amount

FROM billing

GROUP BY payment_status;

-- Q19. Patients who visited more than once

SELECT

    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,

    COUNT(a.appointment_id) AS visit_count

FROM patients p

JOIN appointments a ON p.patient_id = a.patient_id

GROUP BY p.patient_id, p.first_name, p.last_name

HAVING COUNT(a.appointment_id) > 1

ORDER BY visit_count DESC;

-- Q20. Average salary by department

SELECT

    dept.dept_name,

    COUNT(d.doctor_id)  AS num_doctors,

    AVG(d.salary)       AS avg_salary,

    MAX(d.salary)       AS max_salary,

    MIN(d.salary)       AS min_salary

FROM departments dept

LEFT JOIN doctors d ON dept.department_id = d.department_id

GROUP BY dept.dept_name

ORDER BY avg_salary DESC;

-- PHASE 7: WINDOW FUNCTIONS

-- Q21. Rank doctors by number of appointments

SELECT

    CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,

    d.specialization,

    COUNT(a.appointment_id) AS total_appointments,

    RANK() OVER (ORDER BY COUNT(a.appointment_id) DESC) AS appointment_rank

FROM doctors d

LEFT JOIN appointments a ON d.doctor_id = a.doctor_id

GROUP BY d.doctor_id, d.first_name, d.last_name, d.specialization;

-- Q22. Running total of billing amount ordered by date

SELECT

    bill_date,

    total_amount,

    SUM(total_amount) OVER (ORDER BY bill_date) AS running_total

FROM billing

ORDER BY bill_date;

-- Q23. Rank patients by total spending
SELECT
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    SUM(b.total_amount) AS total_spending,
    DENSE_RANK() OVER (ORDER BY SUM(b.total_amount) DESC) AS spending_rank
FROM billing b
JOIN patients p ON b.patient_id = p.patient_id
GROUP BY p.patient_id, p.first_name, p.last_name;

-- Q24. Previous appointment date for each patient (LAG)

SELECT

    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,

    a.appointment_date,

    LAG(a.appointment_date) OVER (PARTITION BY a.patient_id ORDER BY a.appointment_date) AS previous_visit

FROM appointments a

JOIN patients p ON a.patient_id = p.patient_id

ORDER BY p.patient_id, a.appointment_date;

-- Q25. Row number per department doctor listing

SELECT

    dept.dept_name,

    CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,

    d.salary,

    ROW_NUMBER() OVER (PARTITION BY dept.dept_name ORDER BY d.salary DESC) AS rank_in_dept

FROM doctors d

JOIN departments dept ON d.department_id = dept.department_id;

-- PHASE 8: VIEWS

-- View 1: Patient appointment summary

CREATE OR REPLACE VIEW vw_patient_appointments AS

SELECT

    p.patient_id,

    CONCAT(p.first_name, ' ', p.last_name)  AS patient_name,

    p.gender,

    p.blood_group,

    COUNT(a.appointment_id)                  AS total_appointments,

    MAX(a.appointment_date)                  AS last_visit

FROM patients p

LEFT JOIN appointments a ON p.patient_id = a.patient_id

GROUP BY p.patient_id, p.first_name, p.last_name, p.gender, p.blood_group;

-- Use the view

SELECT * FROM vw_patient_appointments ORDER BY total_appointments DESC;

-- View 2: Doctor performance view

CREATE OR REPLACE VIEW vw_doctor_performance AS

SELECT

    d.doctor_id,

    CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,

    d.specialization,

    dept.dept_name,

    COUNT(DISTINCT a.appointment_id)        AS total_appointments,

    COUNT(DISTINCT mr.record_id)            AS total_records,

    d.salary

FROM doctors d

JOIN departments dept ON d.department_id   = dept.department_id

LEFT JOIN appointments   a  ON d.doctor_id = a.doctor_id

LEFT JOIN medical_records mr ON d.doctor_id = mr.doctor_id

GROUP BY d.doctor_id, d.first_name, d.last_name, d.specialization, dept.dept_name, d.salary;

-- Use the view

SELECT * FROM vw_doctor_performance ORDER BY total_appointments DESC;

-- View 3: Pending bills view

CREATE OR REPLACE VIEW vw_pending_bills AS

SELECT

    b.bill_id,

    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,

    p.phone,

    b.bill_date,

    b.total_amount,

    b.payment_status

FROM billing b

JOIN patients p ON b.patient_id = p.patient_id

WHERE b.payment_status IN ('Pending', 'Partial')

ORDER BY b.total_amount DESC;

-- Use the view

SELECT * FROM vw_pending_bills;

-- PHASE 9: STORED PROCEDURES

-- Procedure 1: Get full patient profile

DROP PROCEDURE IF EXISTS GetPatientProfile;

DELIMITER $$

CREATE PROCEDURE GetPatientProfile(IN p_id INT)

BEGIN

-- Basic info

    SELECT CONCAT(first_name, ' ', last_name) AS patient_name,

           date_of_birth, gender, blood_group, phone, email, address

    FROM patients WHERE patient_id = p_id;

-- Appointments

    SELECT a.appointment_date, CONCAT(d.first_name,' ',d.last_name) AS doctor, a.reason, a.status

    FROM appointments a

    JOIN doctors d ON a.doctor_id = d.doctor_id

    WHERE a.patient_id = p_id ORDER BY a.appointment_date DESC;

-- Bills

    SELECT bill_date, total_amount, payment_status

    FROM billing WHERE patient_id = p_id;

END$$

DELIMITER ;

-- Call it

CALL GetPatientProfile(1);

-- Procedure 2: Get department report

DROP PROCEDURE IF EXISTS GetDeptReport;

DELIMITER $$

CREATE PROCEDURE GetDeptReport(IN dept_id INT)

BEGIN

    SELECT dept_name, location FROM departments WHERE department_id = dept_id;

    SELECT CONCAT(first_name,' ',last_name) AS doctor, specialization, salary

    FROM doctors WHERE department_id = dept_id;

    SELECT room_number, room_type, is_available, price_per_day

    FROM rooms WHERE department_id = dept_id;

END$$

DELIMITER ;

-- Call it

CALL GetDeptReport(1);

-- PHASE 10: INDEXES (for performance)

CREATE INDEX idx_appointments_patient  ON appointments(patient_id);

CREATE INDEX idx_appointments_doctor   ON appointments(doctor_id);

CREATE INDEX idx_appointments_date     ON appointments(appointment_date);

CREATE INDEX idx_billing_patient       ON billing(patient_id);

CREATE INDEX idx_billing_status        ON billing(payment_status);

CREATE INDEX idx_medical_patient       ON medical_records(patient_id);

CREATE INDEX idx_prescriptions_record  ON prescriptions(record_id);

-- BONUS: 10 INTERVIEW QUESTIONS WITH ANSWERS

-- INTERVIEW Q1.

-- Find the doctor who has treated the most patients

SELECT

    CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,

    COUNT(DISTINCT mr.patient_id) AS unique_patients_treated

FROM doctors d

JOIN medical_records mr ON d.doctor_id = mr.doctor_id

GROUP BY d.doctor_id, d.first_name, d.last_name

ORDER BY unique_patients_treated DESC

LIMIT 1;

-- INTERVIEW Q2.
-- Find patients who have pending bills and have visited more than once
SELECT
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    COUNT(DISTINCT a.appointment_id) AS total_visits,
    'Pending' AS payment_status
FROM patients p
JOIN appointments a ON p.patient_id = a.patient_id
WHERE EXISTS (
    SELECT 1
    FROM billing b
    WHERE b.patient_id = p.patient_id
      AND b.payment_status = 'Pending'
)
GROUP BY p.patient_id, p.first_name, p.last_name
HAVING COUNT(DISTINCT a.appointment_id) > 1;

-- INTERVIEW Q3.

-- Department with the highest total room charges collected

SELECT

    dept.dept_name,

    SUM(b.room_charges) AS total_room_charges

FROM billing b

JOIN appointments a    ON b.appointment_id = a.appointment_id

JOIN doctors      d    ON a.doctor_id       = d.doctor_id

JOIN departments  dept ON d.department_id   = dept.department_id

GROUP BY dept.dept_name

ORDER BY total_room_charges DESC

LIMIT 1;

-- INTERVIEW Q4.

-- List patients currently admitted (not yet discharged)

SELECT

    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    r.room_number, r.room_type, ra.admitted_on,
    DATEDIFF(CURRENT_DATE, ra.admitted_on) AS days_admitted
FROM room_assignments ra
JOIN patients p ON ra.patient_id = p.patient_id
JOIN rooms    r ON ra.room_id    = r.room_id
WHERE ra.discharged_on IS NULL;
-- INTERVIEW Q5.
-- Find medications that have never been prescribed
SELECT m.med_name, m.category, m.stock_qty
FROM medications m
WHERE m.medication_id NOT IN (SELECT medication_id FROM prescriptions);

-- INTERVIEW Q6.
-- Calculate each patient's average bill and classify them

SELECT
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    AVG(b.total_amount) AS avg_bill,
    CASE
        WHEN AVG(b.total_amount) > 15000 THEN 'High Value'
        WHEN AVG(b.total_amount) > 5000  THEN 'Medium Value'
        ELSE 'Low Value'
    END AS patient_category
FROM billing b
JOIN patients p ON b.patient_id = p.patient_id
GROUP BY p.patient_id, p.first_name, p.last_name
ORDER BY avg_bill DESC;

-- INTERVIEW Q7.
-- Find doctors who joined in the last 5 years and have salary > 160,000

SELECT
    CONCAT(first_name, ' ', last_name) AS doctor_name,
    specialization,
    joining_date,
    salary
FROM doctors
WHERE joining_date >= DATE_SUB(CURRENT_DATE, INTERVAL 5 YEAR)
  AND salary > 160000
ORDER BY joining_date DESC;

-- INTERVIEW Q8.
-- Month-wise appointment count for 2025

SELECT
    MONTHNAME(appointment_date) AS month,
    MONTH(appointment_date)     AS month_num,
    COUNT(*)                    AS total_appointments
FROM appointments
WHERE YEAR(appointment_date) = 2025
GROUP BY MONTH(appointment_date), MONTHNAME(appointment_date)
ORDER BY month_num;

-- INTERVIEW Q9.
-- Find duplicate patient phone numbers (data quality check)

SELECT phone, COUNT(*) AS occurrences
FROM patients
GROUP BY phone
HAVING COUNT(*) > 1;
-- INTERVIEW Q10.
-- Self JOIN — Find pairs of doctors in the same department
SELECT
    CONCAT(d1.first_name, ' ', d1.last_name) AS doctor_1,
    CONCAT(d2.first_name, ' ', d2.last_name) AS doctor_2,
    dept.dept_name
FROM doctors d1
JOIN doctors      d2   ON d1.department_id = d2.department_id AND d1.doctor_id < d2.doctor_id
JOIN departments  dept ON d1.department_id = dept.department_id
ORDER BY dept.dept_name;

