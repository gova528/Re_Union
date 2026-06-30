-- =========================================================================
-- schema.sql — GRT 2006-2007 Grand Reunion Tour
-- Normalized MySQL schema with seed data
-- =========================================================================

CREATE DATABASE IF NOT EXISTS grt_reunion CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE grt_reunion;

-- -------------------------------------------------------------------------
-- ADMINISTRATORS
-- -------------------------------------------------------------------------
DROP TABLE IF EXISTS activity_logs;
DROP TABLE IF EXISTS likes;
DROP TABLE IF EXISTS rsvp;
DROP TABLE IF EXISTS announcements;
DROP TABLE IF EXISTS photos;
DROP TABLE IF EXISTS students;
DROP TABLE IF EXISTS settings;
DROP TABLE IF EXISTS administrators;

CREATE TABLE administrators (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(64) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    display_name VARCHAR(120) DEFAULT 'Administrator',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_login DATETIME NULL
) ENGINE=InnoDB;

-- Default credentials: username "admin" / password "ReunionAdmin@2007"
-- CHANGE THIS IMMEDIATELY AFTER DEPLOYMENT.
INSERT INTO administrators (username, password_hash, display_name) VALUES
('admin', 'scrypt:32768:8:1$WoKsgwDA2ObJAlp7$dc176f0313453f9b7cb90e6f66c614cb536c3966d084765966d344cf7b80a0bf8b8941d212057a429178879346eb29fc0fb82671da987a6bb92392982fe79dd0', 'Reunion Administrator');

-- -------------------------------------------------------------------------
-- STUDENTS
-- -------------------------------------------------------------------------
CREATE TABLE students (
    id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(150) NOT NULL,
    gender ENUM('Male','Female') NOT NULL,
    occupation VARCHAR(150) DEFAULT NULL,
    current_city VARCHAR(120) DEFAULT NULL,
    biography TEXT,
    contact_info VARCHAR(150) DEFAULT NULL,
    photo_path VARCHAR(255) DEFAULT 'reunion_001.jpg',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_student_name (full_name),
    INDEX idx_student_gender (gender)
) ENGINE=InnoDB;

-- -------------------------------------------------------------------------
-- PHOTOS (Gallery)
-- -------------------------------------------------------------------------
CREATE TABLE photos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    file_path VARCHAR(255) NOT NULL,
    caption VARCHAR(255) DEFAULT '',
    photo_date DATE DEFAULT NULL,
    uploaded_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_photo_date (photo_date)
) ENGINE=InnoDB;

INSERT INTO photos (file_path, caption, photo_date) VALUES
('reunion_001.jpg', 'Opening night of the Grand Reunion Tour', '2007-12-20'),
('reunion_002.jpg', 'Classmates catching up under the lights', '2007-12-20'),
('class_group_photo.jpg', 'The full GRT 2006-2007 batch, together again', '2007-12-21'),
('farewell.webp', 'Farewell moment as the reunion came to a close', '2007-12-22');

-- -------------------------------------------------------------------------
-- ANNOUNCEMENTS
-- -------------------------------------------------------------------------
CREATE TABLE announcements (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    body TEXT NOT NULL,
    published_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_announcement_date (published_at)
) ENGINE=InnoDB;

INSERT INTO announcements (title, body, published_at) VALUES
('Welcome to the GRT 2006-2007 Grand Reunion Tour!', 'After all these years, the GRT batch of 2006-2007 is finally coming together again. Mark your calendars, confirm your RSVP, and get ready for a night of nostalgia, laughter, and reconnecting with old friends.', '2007-11-01 09:00:00'),
('Venue & Schedule Confirmed', 'The reunion venue and the full day schedule have been finalized. Check the Invitation section for full details on timing, dress code, and the evening program.', '2007-11-15 10:30:00'),
('RSVP Deadline Approaching', 'Please confirm your attendance through the RSVP section at the earliest. This helps us plan seating, catering, and memorabilia for every classmate joining us.', '2007-12-01 18:00:00');

-- -------------------------------------------------------------------------
-- LIKES (session/browser based, no login)
-- -------------------------------------------------------------------------
CREATE TABLE likes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    announcement_id INT NOT NULL,
    visitor_token VARCHAR(64) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_like_per_visitor (announcement_id, visitor_token),
    FOREIGN KEY (announcement_id) REFERENCES announcements(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- -------------------------------------------------------------------------
-- RSVP
-- -------------------------------------------------------------------------
CREATE TABLE rsvp (
    id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(150) NOT NULL,
    email VARCHAR(150) DEFAULT NULL,
    phone VARCHAR(30) DEFAULT NULL,
    response ENUM('Accept','Decline','Maybe') NOT NULL,
    message TEXT,
    submitted_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_rsvp_response (response)
) ENGINE=InnoDB;

-- -------------------------------------------------------------------------
-- SETTINGS (key-value site settings)
-- -------------------------------------------------------------------------
CREATE TABLE settings (
    setting_key VARCHAR(100) PRIMARY KEY,
    setting_value TEXT
) ENGINE=InnoDB;

INSERT INTO settings (setting_key, setting_value) VALUES
('hero_title', 'GRT 2006-2007 Grand Reunion Tour'),
('hero_subtitle', 'Once classmates, forever family. Join us as we relive the golden days.'),
('event_date', '2027-12-20 18:00:00'),
('event_venue', 'Grand Heritage Convention Center, Andhra Pradesh'),
('contact_email', 'reunion.grt2007@example.com'),
('contact_phone', '+91 90000 00000');

-- -------------------------------------------------------------------------
-- ACTIVITY LOGS
-- -------------------------------------------------------------------------
CREATE TABLE activity_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    admin_id INT,
    action VARCHAR(255) NOT NULL,
    details TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (admin_id) REFERENCES administrators(id) ON DELETE SET NULL
) ENGINE=InnoDB;

INSERT INTO activity_logs (admin_id, action, details) VALUES
(1, 'SYSTEM_INIT', 'Database initialized and seeded with sample data.');

-- -------------------------------------------------------------------------
-- SEED: STUDENT DIRECTORY (from uploaded class roster, generated profiles)
-- -------------------------------------------------------------------------
-- Auto-generated student seed data from class roster
INSERT INTO students (full_name, gender, occupation, current_city, biography, photo_path) VALUES
('Sankarapu Anjaneyulu', 'Male', 'Income Tax Officer', 'Tirupati', 'After completing schooling, Sankarapu pursued a career in income tax officer and now resides in Tirupati.', 'class_group_photo.jpg'),
('Tolla Anjaneyulu', 'Male', 'Agriculture Officer', 'Anantapur', 'After completing schooling, Tolla pursued a career in agriculture officer and now resides in Anantapur.', 'reunion_001.jpg'),
('Mekala Anvesh Kumar Reddy', 'Male', 'Police Constable', 'Guntakal', 'Currently working as a police constable in Guntakal, Mekala looks forward to reconnecting with old classmates at the reunion.', 'class_group_photo.jpg'),
('Katlaganti Ashok Kumar Reddy', 'Male', 'Government Employee (RTC)', 'Singapore', 'Katlaganti has built a successful career as a government employee (rtc) in Singapore and cherishes memories from the 2006-2007 batch.', 'reunion_001.jpg'),
('Shaik Babajan', 'Male', 'Bank Manager', 'Guntur', 'After completing schooling, Shaik pursued a career in bank manager and now resides in Guntur.', 'reunion_001.jpg'),
('Shaik Bavajan', 'Male', 'Shop Owner', 'Hyderabad (Kondapur)', 'After completing schooling, Shaik pursued a career in shop owner and now resides in Hyderabad (Kondapur).', 'class_group_photo.jpg'),
('B.BharathKumar Reddy', 'Male', 'Sub Inspector', 'Nandyal', 'Currently working as a sub inspector in Nandyal, B.Bharathkumar looks forward to reconnecting with old classmates at the reunion.', 'class_group_photo.jpg'),
('Madduri Bhargava', 'Male', 'Beautician', 'Proddatur', 'After completing schooling, Madduri pursued a career in beautician and now resides in Proddatur.', 'reunion_002.jpg'),
('Gumpolla Chandra Sekhar', 'Male', 'Data Analyst', 'Chittoor', 'After completing schooling, Gumpolla pursued a career in data analyst and now resides in Chittoor.', 'reunion_001.jpg'),
('Gudla Dasaratha', 'Male', 'Loco Pilot (Railways)', 'Kakinada', 'Gudla has built a successful career as a loco pilot (railways) in Kakinada and cherishes memories from the 2006-2007 batch.', 'reunion_001.jpg'),
('Yallam Dileep Kumar Raju', 'Male', 'Pharmacist', 'Adoni', 'Yallam has built a successful career as a pharmacist in Adoni and cherishes memories from the 2006-2007 batch.', 'reunion_001.jpg'),
('Barenkala Eswaraiah', 'Male', 'Government Employee (RTC)', 'Ongole', 'After completing schooling, Barenkala pursued a career in government employee (rtc) and now resides in Ongole.', 'reunion_002.jpg'),
('Yarrajeni Eswar Reddy', 'Male', 'School Principal', 'Hyderabad (Kondapur)', 'Yarrajeni has built a successful career as a school principal in Hyderabad (Kondapur) and cherishes memories from the 2006-2007 batch.', 'reunion_001.jpg'),
('Appa Ganesh', 'Male', 'Self Employed', 'Dubai (UAE)', 'After completing schooling, Appa pursued a career in self employed and now resides in Dubai (UAE).', 'reunion_002.jpg'),
('Narnavaram Giri', 'Male', 'Government Employee (RTC)', 'Dubai (UAE)', 'Narnavaram has built a successful career as a government employee (rtc) in Dubai (UAE) and cherishes memories from the 2006-2007 batch.', 'class_group_photo.jpg'),
('Gutti Govardhana', 'Male', 'Bank PO', 'Visakhapatnam', 'Currently working as a bank po in Visakhapatnam, Gutti looks forward to reconnecting with old classmates at the reunion.', 'reunion_001.jpg'),
('Purum Govardhana', 'Male', 'Doctor', 'Vijayawada', 'Currently working as a doctor in Vijayawada, Purum looks forward to reconnecting with old classmates at the reunion.', 'reunion_001.jpg'),
('Maligi Haravendra Reddy', 'Male', 'Tax Consultant', 'Guntur', 'After completing schooling, Maligi pursued a career in tax consultant and now resides in Guntur.', 'reunion_001.jpg'),
('Mutra HariPrasad Reddy', 'Male', 'Marketing Executive', 'Chittoor', 'Mutra has built a successful career as a marketing executive in Chittoor and cherishes memories from the 2006-2007 batch.', 'class_group_photo.jpg'),
('Pogaku Jagadeesh', 'Male', 'Private Tutor', 'Nellore', 'Pogaku has built a successful career as a private tutor in Nellore and cherishes memories from the 2006-2007 batch.', 'reunion_002.jpg'),
('Pujari Janardhana', 'Male', 'Pharmacist', 'Guntakal', 'Pujari has built a successful career as a pharmacist in Guntakal and cherishes memories from the 2006-2007 batch.', 'class_group_photo.jpg'),
('Yalapala Jayaram', 'Male', 'Doctor', 'Hyderabad (Kondapur)', 'Currently working as a doctor in Hyderabad (Kondapur), Yalapala looks forward to reconnecting with old classmates at the reunion.', 'reunion_001.jpg'),
('Yalapala Kishore', 'Male', 'Beautician', 'Dhone', 'After completing schooling, Yalapala pursued a career in beautician and now resides in Dhone.', 'reunion_001.jpg'),
('Bathini Madan Mohan', 'Male', 'Self Employed', 'Ongole', 'Bathini has built a successful career as a self employed in Ongole and cherishes memories from the 2006-2007 batch.', 'class_group_photo.jpg'),
('Bukke Mahesh Naik', 'Male', 'Fashion Designer', 'Anantapur', 'Currently working as a fashion designer in Anantapur, Bukke looks forward to reconnecting with old classmates at the reunion.', 'reunion_002.jpg'),
('Pommala Mani Prasad', 'Male', 'Civil Engineer', 'Anantapur', 'After completing schooling, Pommala pursued a career in civil engineer and now resides in Anantapur.', 'reunion_002.jpg'),
('Vuttharadi Nagaraju', 'Male', 'Veterinary Doctor', 'Chittoor', 'After completing schooling, Vuttharadi pursued a career in veterinary doctor and now resides in Chittoor.', 'reunion_001.jpg'),
('Yalapalli Nagarjuna', 'Male', 'Lab Technician', 'Nandyal', 'Yalapalli has built a successful career as a lab technician in Nandyal and cherishes memories from the 2006-2007 batch.', 'reunion_001.jpg'),
('Purum Nagendra Babu', 'Male', 'Dairy Farmer', 'Ongole', 'Currently working as a dairy farmer in Ongole, Purum looks forward to reconnecting with old classmates at the reunion.', 'reunion_002.jpg'),
('Koneti Nagendra Kumar', 'Male', 'Accountant', 'Chittoor', 'After completing schooling, Koneti pursued a career in accountant and now resides in Chittoor.', 'reunion_001.jpg'),
('Korakoti Narasimhulu', 'Male', 'Fashion Designer', 'Dubai (UAE)', 'Korakoti has built a successful career as a fashion designer in Dubai (UAE) and cherishes memories from the 2006-2007 batch.', 'class_group_photo.jpg'),
('Talari Narasimhulu', 'Male', 'Data Analyst', 'Proddatur', 'Currently working as a data analyst in Proddatur, Talari looks forward to reconnecting with old classmates at the reunion.', 'reunion_002.jpg'),
('Bhojanapu Phani Bhushana', 'Male', 'Private Tutor', 'Anantapur', 'After completing schooling, Bhojanapu pursued a career in private tutor and now resides in Anantapur.', 'class_group_photo.jpg'),
('Mude Prasad', 'Male', 'Dairy Farmer', 'Guntur', 'After completing schooling, Mude pursued a career in dairy farmer and now resides in Guntur.', 'reunion_001.jpg'),
('Veeranala Prasanth Kumar', 'Male', 'Accountant', 'Hyderabad (Madhapur)', 'After completing schooling, Veeranala pursued a career in accountant and now resides in Hyderabad (Madhapur).', 'class_group_photo.jpg'),
('Bavanath Purushotham Naik', 'Male', 'Loco Pilot (Railways)', 'Hyderabad (Kondapur)', 'After completing schooling, Bavanath pursued a career in loco pilot (railways) and now resides in Hyderabad (Kondapur).', 'reunion_002.jpg'),
('Seelam Ramanjulu', 'Male', 'Marketing Executive', 'Hyderabad (Kondapur)', 'Seelam has built a successful career as a marketing executive in Hyderabad (Kondapur) and cherishes memories from the 2006-2007 batch.', 'class_group_photo.jpg'),
('Varikolla Ramanajaneyulu', 'Male', 'Electrician Contractor', 'Dubai (UAE)', 'After completing schooling, Varikolla pursued a career in electrician contractor and now resides in Dubai (UAE).', 'class_group_photo.jpg'),
('Bukke Ramesh Naik', 'Male', 'Businessman', 'Guntakal', 'Currently working as a businessman in Guntakal, Bukke looks forward to reconnecting with old classmates at the reunion.', 'reunion_002.jpg'),
('Gundlapalli Ravi Kumar', 'Male', 'Bank Clerk', 'Tirupati', 'Gundlapalli has built a successful career as a bank clerk in Tirupati and cherishes memories from the 2006-2007 batch.', 'reunion_002.jpg'),
('Jally Ravitheja Kumar', 'Male', 'Nurse', 'Bangalore', 'After completing schooling, Jally pursued a career in nurse and now resides in Bangalore.', 'class_group_photo.jpg'),
('Bommaluleni Reddeppa', 'Male', 'Electrician Contractor', 'Pune', 'After completing schooling, Bommaluleni pursued a career in electrician contractor and now resides in Pune.', 'class_group_photo.jpg'),
('Banda Samba siva', 'Male', 'Police Constable', 'Hyderabad (Madhapur)', 'Banda has built a successful career as a police constable in Hyderabad (Madhapur) and cherishes memories from the 2006-2007 batch.', 'class_group_photo.jpg'),
('Nulu Siva Kumar', 'Male', 'Shop Owner', 'Hyderabad (Kondapur)', 'After completing schooling, Nulu pursued a career in shop owner and now resides in Hyderabad (Kondapur).', 'reunion_001.jpg'),
('Ponna Siva Kumar', 'Male', 'Private Tutor', 'Adoni', 'After completing schooling, Ponna pursued a career in private tutor and now resides in Adoni.', 'class_group_photo.jpg'),
('Tudum Siva Kumar', 'Male', 'Homemaker', 'Hyderabad', 'Currently working as a homemaker in Hyderabad, Tudum looks forward to reconnecting with old classmates at the reunion.', 'reunion_002.jpg'),
('Yegavinti Sreenatha reddy', 'Male', 'Dairy Farmer', 'Hyderabad', 'After completing schooling, Yegavinti pursued a career in dairy farmer and now resides in Hyderabad.', 'reunion_002.jpg'),
('N sreenivasulu', 'Male', 'Software Tester', 'Anantapur', 'After completing schooling, N pursued a career in software tester and now resides in Anantapur.', 'reunion_001.jpg'),
('Kota kunda Suresh', 'Male', 'Lab Technician', 'Guntur', 'After completing schooling, Kota pursued a career in lab technician and now resides in Guntur.', 'class_group_photo.jpg'),
('E venkata charan', 'Male', 'Dairy Farmer', 'Guntur', 'Currently working as a dairy farmer in Guntur, E looks forward to reconnecting with old classmates at the reunion.', 'reunion_001.jpg'),
('V venkatesh', 'Male', 'Farmer', 'Guntakal', 'V has built a successful career as a farmer in Guntakal and cherishes memories from the 2006-2007 batch.', 'class_group_photo.jpg'),
('Kenga Venkatrama', 'Male', 'Nurse', 'Chittoor', 'Currently working as a nurse in Chittoor, Kenga looks forward to reconnecting with old classmates at the reunion.', 'class_group_photo.jpg'),
('BOGGULA VENUGOPAL', 'Male', 'Loco Pilot (Railways)', 'Kadapa', 'Currently working as a loco pilot (railways) in Kadapa, Boggula looks forward to reconnecting with old classmates at the reunion.', 'class_group_photo.jpg'),
('Anil', 'Male', 'Sub Inspector', 'Nandyal', 'Anil has built a successful career as a sub inspector in Nandyal and cherishes memories from the 2006-2007 batch.', 'reunion_002.jpg'),
('Rajasekhar -HG', 'Male', 'Private Tutor', 'Bangalore', 'Currently working as a private tutor in Bangalore, Rajasekhar looks forward to reconnecting with old classmates at the reunion.', 'reunion_002.jpg'),
('Vinod Kumar', 'Male', 'Businessman', 'Anantapur', 'After completing schooling, Vinod pursued a career in businessman and now resides in Anantapur.', 'reunion_001.jpg'),
('Devendra', 'Male', 'Bank Clerk', 'Hyderabad', 'Currently working as a bank clerk in Hyderabad, Devendra looks forward to reconnecting with old classmates at the reunion.', 'class_group_photo.jpg'),
('UmaMahesh', 'Male', 'Mechanical Engineer', 'Singapore', 'After completing schooling, Umamahesh pursued a career in mechanical engineer and now resides in Singapore.', 'reunion_001.jpg'),
('BODE ALIVELU', 'Female', 'Doctor', 'Nandyal', 'Currently working as a doctor in Nandyal, Bode looks forward to reconnecting with old classmates at the reunion.', 'reunion_001.jpg'),
('KONDREDDY AMALA', 'Female', 'Mechanical Engineer', 'Guntur', 'After completing schooling, Kondreddy pursued a career in mechanical engineer and now resides in Guntur.', 'reunion_002.jpg'),
('PATAN AMMAJAN', 'Female', 'Doctor', 'Pune', 'After completing schooling, Patan pursued a career in doctor and now resides in Pune.', 'reunion_002.jpg'),
('D AMMAJI', 'Female', 'Dairy Farmer', 'Kadapa', 'Currently working as a dairy farmer in Kadapa, D looks forward to reconnecting with old classmates at the reunion.', 'reunion_001.jpg'),
('A AMMULU', 'Female', 'Lab Technician', 'Singapore', 'A has built a successful career as a lab technician in Singapore and cherishes memories from the 2006-2007 batch.', 'reunion_001.jpg'),
('MINNAMA REDDY ANJANA', 'Female', 'Insurance Agent', 'Proddatur', 'After completing schooling, Minnama pursued a career in insurance agent and now resides in Proddatur.', 'reunion_001.jpg'),
('MEKALA ANITHA', 'Female', 'Police Constable', 'Guntakal', 'Mekala has built a successful career as a police constable in Guntakal and cherishes memories from the 2006-2007 batch.', 'reunion_002.jpg'),
('GUDDITI ARCHANA', 'Female', 'Loco Pilot (Railways)', 'Proddatur', 'Gudditi has built a successful career as a loco pilot (railways) in Proddatur and cherishes memories from the 2006-2007 batch.', 'class_group_photo.jpg'),
('JINKA ARUNA KUMARI', 'Female', 'Civil Engineer', 'Guntakal', 'Currently working as a civil engineer in Guntakal, Jinka looks forward to reconnecting with old classmates at the reunion.', 'class_group_photo.jpg'),
('CHINTAPALLI ASWANI', 'Female', 'Police Constable', 'Vijayawada', 'Chintapalli has built a successful career as a police constable in Vijayawada and cherishes memories from the 2006-2007 batch.', 'class_group_photo.jpg'),
('KATLAGANTI ASWANI', 'Female', 'Bank Clerk', 'Tirupati', 'After completing schooling, Katlaganti pursued a career in bank clerk and now resides in Tirupati.', 'reunion_001.jpg'),
('MODEM ASWANI', 'Female', 'Sub Inspector', 'Dubai (UAE)', 'Modem has built a successful career as a sub inspector in Dubai (UAE) and cherishes memories from the 2006-2007 batch.', 'reunion_001.jpg'),
('Y BAYAMMA', 'Female', 'Loco Pilot (Railways)', 'Nellore', 'Y has built a successful career as a loco pilot (railways) in Nellore and cherishes memories from the 2006-2007 batch.', 'reunion_002.jpg'),
('BOJANAPU BHARGAVI', 'Female', 'Real Estate Agent', 'Guntur', 'Bojanapu has built a successful career as a real estate agent in Guntur and cherishes memories from the 2006-2007 batch.', 'class_group_photo.jpg'),
('BURRA BHARGAVI', 'Female', 'Police Constable', 'Vijayawada', 'Currently working as a police constable in Vijayawada, Burra looks forward to reconnecting with old classmates at the reunion.', 'class_group_photo.jpg'),
('KOMMURI BRAHMANI', 'Female', 'Software Engineer', 'Guntur', 'After completing schooling, Kommuri pursued a career in software engineer and now resides in Guntur.', 'reunion_001.jpg'),
('B CHANDRAKALA', 'Female', 'Junior Lecturer', 'Chennai', 'B has built a successful career as a junior lecturer in Chennai and cherishes memories from the 2006-2007 batch.', 'reunion_001.jpg'),
('BIDHAM CHANDRAKALA', 'Female', 'Veterinary Doctor', 'Vijayawada', 'After completing schooling, Bidham pursued a career in veterinary doctor and now resides in Vijayawada.', 'reunion_002.jpg'),
('ANANTHA DEEPIKA', 'Female', 'Software Engineer', 'Ongole', 'Anantha has built a successful career as a software engineer in Ongole and cherishes memories from the 2006-2007 batch.', 'reunion_002.jpg'),
('POLURU DEEPIKA', 'Female', 'Tax Consultant', 'Proddatur', 'Currently working as a tax consultant in Proddatur, Poluru looks forward to reconnecting with old classmates at the reunion.', 'class_group_photo.jpg'),
('MUDIVETI DHANAMMA', 'Female', 'Fashion Designer', 'Guntakal', 'Currently working as a fashion designer in Guntakal, Mudiveti looks forward to reconnecting with old classmates at the reunion.', 'reunion_002.jpg'),
('VALIPI GANGAVATHI', 'Female', 'Accountant', 'Kadapa', 'Valipi has built a successful career as a accountant in Kadapa and cherishes memories from the 2006-2007 batch.', 'reunion_001.jpg'),
('B GAYATHRI', 'Female', 'Civil Engineer', 'Singapore', 'Currently working as a civil engineer in Singapore, B looks forward to reconnecting with old classmates at the reunion.', 'class_group_photo.jpg'),
('DOMMA GOWTHAMI', 'Female', 'Civil Engineer', 'Dhone', 'Domma has built a successful career as a civil engineer in Dhone and cherishes memories from the 2006-2007 batch.', 'reunion_001.jpg'),
('NARNAVARAM HARITHA', 'Female', 'Civil Engineer', 'Singapore', 'Narnavaram has built a successful career as a civil engineer in Singapore and cherishes memories from the 2006-2007 batch.', 'class_group_photo.jpg'),
('NANAPU HARITHA', 'Female', 'Homemaker', 'Nellore', 'After completing schooling, Nanapu pursued a career in homemaker and now resides in Nellore.', 'class_group_photo.jpg'),
('MODEM HEMALATHA', 'Female', 'Government Employee (RTC)', 'Nellore', 'After completing schooling, Modem pursued a career in government employee (rtc) and now resides in Nellore.', 'class_group_photo.jpg'),
('AKUTHOTA HEMAVANI', 'Female', 'Doctor', 'Guntakal', 'After completing schooling, Akuthota pursued a career in doctor and now resides in Guntakal.', 'reunion_002.jpg'),
('RAMISETTI HIMA BINDU', 'Female', 'Businessman', 'Singapore', 'After completing schooling, Ramisetti pursued a career in businessman and now resides in Singapore.', 'class_group_photo.jpg'),
('MADAKA JYOTHI', 'Female', 'Project Manager', 'Vijayawada', 'Currently working as a project manager in Vijayawada, Madaka looks forward to reconnecting with old classmates at the reunion.', 'reunion_001.jpg'),
('THIMNINI  GOWNOLLA KANRUNA SREE', 'Female', 'Junior Lecturer', 'Guntakal', 'Currently working as a junior lecturer in Guntakal, Thimnini looks forward to reconnecting with old classmates at the reunion.', 'class_group_photo.jpg'),
('BATTHALA KAVITHA RANI', 'Female', 'Homemaker', 'Kakinada', 'Batthala has built a successful career as a homemaker in Kakinada and cherishes memories from the 2006-2007 batch.', 'reunion_001.jpg'),
('BUDDA LALITHA', 'Female', 'HR Manager', 'Anantapur', 'Budda has built a successful career as a hr manager in Anantapur and cherishes memories from the 2006-2007 batch.', 'reunion_002.jpg'),
('CHAMANCHI MAMATHA', 'Female', 'Farmer', 'Guntakal', 'Currently working as a farmer in Guntakal, Chamanchi looks forward to reconnecting with old classmates at the reunion.', 'reunion_002.jpg'),
('ASADI MANEMMA', 'Female', 'Self Employed', 'Kakinada', 'After completing schooling, Asadi pursued a career in self employed and now resides in Kakinada.', 'reunion_001.jpg'),
('CHINTHA NANDINI', 'Female', 'Self Employed', 'Hyderabad (Kondapur)', 'Currently working as a self employed in Hyderabad (Kondapur), Chintha looks forward to reconnecting with old classmates at the reunion.', 'reunion_001.jpg'),
('THUGU NANDINI', 'Female', 'Doctor', 'Dubai (UAE)', 'After completing schooling, Thugu pursued a career in doctor and now resides in Dubai (UAE).', 'class_group_photo.jpg'),
('S NAJEENA', 'Female', 'Electrician Contractor', 'Kurnool', 'S has built a successful career as a electrician contractor in Kurnool and cherishes memories from the 2006-2007 batch.', 'reunion_001.jpg'),
('GUDLA NEELADEVI', 'Female', 'Real Estate Agent', 'Visakhapatnam', 'Gudla has built a successful career as a real estate agent in Visakhapatnam and cherishes memories from the 2006-2007 batch.', 'reunion_001.jpg'),
('RAMISETTI NETHRAVATHI', 'Female', 'Constable (AP Police)', 'Dubai (UAE)', 'Currently working as a constable (ap police) in Dubai (UAE), Ramisetti looks forward to reconnecting with old classmates at the reunion.', 'reunion_002.jpg'),
('CHINNAKOTLA NIRMALA', 'Female', 'Bank PO', 'Hyderabad (Madhapur)', 'Currently working as a bank po in Hyderabad (Madhapur), Chinnakotla looks forward to reconnecting with old classmates at the reunion.', 'reunion_001.jpg'),
('EDAGOTTI PADMA', 'Female', 'Fashion Designer', 'Rajahmundry', 'Currently working as a fashion designer in Rajahmundry, Edagotti looks forward to reconnecting with old classmates at the reunion.', 'reunion_001.jpg'),
('RAMISETTI PADMAVATHI', 'Female', 'Farmer', 'Chittoor', 'After completing schooling, Ramisetti pursued a career in farmer and now resides in Chittoor.', 'reunion_001.jpg'),
('Y PARVATHI', 'Female', 'Fashion Designer', 'Kurnool', 'Y has built a successful career as a fashion designer in Kurnool and cherishes memories from the 2006-2007 batch.', 'reunion_002.jpg'),
('PAMULURI PAVANA KUMARI', 'Female', 'Project Manager', 'Kadapa', 'Currently working as a project manager in Kadapa, Pamuluri looks forward to reconnecting with old classmates at the reunion.', 'reunion_002.jpg'),
('ANGAJALA PUSHPAVATHI', 'Female', 'Pharmacist', 'Guntakal', 'Currently working as a pharmacist in Guntakal, Angajala looks forward to reconnecting with old classmates at the reunion.', 'reunion_002.jpg'),
('SYED PYARI', 'Female', 'Shop Owner', 'Chennai', 'Syed has built a successful career as a shop owner in Chennai and cherishes memories from the 2006-2007 batch.', 'reunion_001.jpg'),
('BANDI RADHAMMA', 'Female', 'Government Employee (RTC)', 'Hyderabad (Madhapur)', 'Bandi has built a successful career as a government employee (rtc) in Hyderabad (Madhapur) and cherishes memories from the 2006-2007 batch.', 'reunion_002.jpg'),
('GODUGU RANJITHA', 'Female', 'Teacher', 'Hyderabad', 'Godugu has built a successful career as a teacher in Hyderabad and cherishes memories from the 2006-2007 batch.', 'reunion_001.jpg'),
('KANNEMADUGU RAMANJULAMMA', 'Female', 'Income Tax Officer', 'Chittoor', 'After completing schooling, Kannemadugu pursued a career in income tax officer and now resides in Chittoor.', 'class_group_photo.jpg'),
('SHAIK REDDI SHABANA', 'Female', 'Constable (AP Police)', 'Dubai (UAE)', 'Currently working as a constable (ap police) in Dubai (UAE), Shaik looks forward to reconnecting with old classmates at the reunion.', 'reunion_002.jpg'),
('BOJANAPU RENUKA', 'Female', 'Fashion Designer', 'Hyderabad', 'After completing schooling, Bojanapu pursued a career in fashion designer and now resides in Hyderabad.', 'reunion_001.jpg'),
('TRIVEDI RENUKA', 'Female', 'Accountant', 'Dubai (UAE)', 'After completing schooling, Trivedi pursued a career in accountant and now resides in Dubai (UAE).', 'reunion_002.jpg'),
('SHAIK RESHMA', 'Female', 'Data Analyst', 'Dubai (UAE)', 'After completing schooling, Shaik pursued a career in data analyst and now resides in Dubai (UAE).', 'reunion_002.jpg'),
('SHAIK RESHMA', 'Female', 'Farmer', 'Vijayawada', 'Shaik has built a successful career as a farmer in Vijayawada and cherishes memories from the 2006-2007 batch.', 'reunion_002.jpg'),
('KAMMALA RUKMINAMMA', 'Female', 'Teacher', 'Visakhapatnam', 'After completing schooling, Kammala pursued a career in teacher and now resides in Visakhapatnam.', 'class_group_photo.jpg'),
('SIBBALA SAILAJA', 'Female', 'Real Estate Agent', 'Guntakal', 'After completing schooling, Sibbala pursued a career in real estate agent and now resides in Guntakal.', 'reunion_002.jpg'),
('RAINETI SARASWATHI', 'Female', 'Fashion Designer', 'Proddatur', 'Currently working as a fashion designer in Proddatur, Raineti looks forward to reconnecting with old classmates at the reunion.', 'class_group_photo.jpg'),
('VANISE SARASWATHI', 'Female', 'Accountant', 'Anantapur', 'After completing schooling, Vanise pursued a career in accountant and now resides in Anantapur.', 'reunion_001.jpg'),
('SHAIK SHABANA', 'Female', 'Junior Lecturer', 'Hyderabad', 'After completing schooling, Shaik pursued a career in junior lecturer and now resides in Hyderabad.', 'class_group_photo.jpg'),
('RATHANAKARAM SIREESHA', 'Female', 'Bank Clerk', 'Proddatur', 'Currently working as a bank clerk in Proddatur, Rathanakaram looks forward to reconnecting with old classmates at the reunion.', 'class_group_photo.jpg'),
('SHAIK SONIA TAJ', 'Female', 'Real Estate Agent', 'Chittoor', 'After completing schooling, Shaik pursued a career in real estate agent and now resides in Chittoor.', 'class_group_photo.jpg'),
('CHANDRAGIRI SREELATHA', 'Female', 'Police Constable', 'Ongole', 'After completing schooling, Chandragiri pursued a career in police constable and now resides in Ongole.', 'reunion_002.jpg'),
('KUPPALA SREEVANYA', 'Female', 'Mechanical Engineer', 'Kadapa', 'Kuppala has built a successful career as a mechanical engineer in Kadapa and cherishes memories from the 2006-2007 batch.', 'reunion_002.jpg'),
('CHINTHAPALLI SIGUNA', 'Female', 'Software Tester', 'Anantapur', 'After completing schooling, Chinthapalli pursued a career in software tester and now resides in Anantapur.', 'reunion_001.jpg'),
('C SUGUNA', 'Female', 'Sub Inspector', 'Ongole', 'C has built a successful career as a sub inspector in Ongole and cherishes memories from the 2006-2007 batch.', 'reunion_002.jpg'),
('K SUGUNA', 'Female', 'Doctor', 'Adoni', 'K has built a successful career as a doctor in Adoni and cherishes memories from the 2006-2007 batch.', 'reunion_002.jpg'),
('DONDLA SULOCHANA', 'Female', 'Shop Owner', 'Ongole', 'Currently working as a shop owner in Ongole, Dondla looks forward to reconnecting with old classmates at the reunion.', 'class_group_photo.jpg'),
('KADIRI SUMATHI', 'Female', 'Bank Clerk', 'Hyderabad', 'After completing schooling, Kadiri pursued a career in bank clerk and now resides in Hyderabad.', 'reunion_002.jpg'),
('MADARAJULA SUMITHRA', 'Female', 'Lecturer', 'Singapore', 'Madarajula has built a successful career as a lecturer in Singapore and cherishes memories from the 2006-2007 batch.', 'reunion_001.jpg'),
('MUTRA SWARNALATHA', 'Female', 'Police Constable', 'Hyderabad (Kondapur)', 'Mutra has built a successful career as a police constable in Hyderabad (Kondapur) and cherishes memories from the 2006-2007 batch.', 'reunion_002.jpg'),
('SUNKOJI SWATHI', 'Female', 'HR Manager', 'Proddatur', 'Currently working as a hr manager in Proddatur, Sunkoji looks forward to reconnecting with old classmates at the reunion.', 'class_group_photo.jpg'),
('BOGGULA TULASI', 'Female', 'Businessman', 'Ongole', 'Currently working as a businessman in Ongole, Boggula looks forward to reconnecting with old classmates at the reunion.', 'reunion_001.jpg'),
('YALAPALA UMADEVI', 'Female', 'Electrician Contractor', 'Vijayawada', 'Currently working as a electrician contractor in Vijayawada, Yalapala looks forward to reconnecting with old classmates at the reunion.', 'reunion_002.jpg'),
('MALLEPULA VASANTHA', 'Female', 'Software Engineer', 'Pune', 'Currently working as a software engineer in Pune, Mallepula looks forward to reconnecting with old classmates at the reunion.', 'class_group_photo.jpg'),
('ERIKALA VASUNDHARA', 'Female', 'Sub Inspector', 'Visakhapatnam', 'Erikala has built a successful career as a sub inspector in Visakhapatnam and cherishes memories from the 2006-2007 batch.', 'reunion_001.jpg'),
('KONETI VIJAYA KUMARI', 'Female', 'Bank Clerk', 'Hyderabad (Kondapur)', 'Koneti has built a successful career as a bank clerk in Hyderabad (Kondapur) and cherishes memories from the 2006-2007 batch.', 'class_group_photo.jpg'),
('MEJARI VIJAYA KUMARI', 'Female', 'Businessman', 'Dhone', 'Mejari has built a successful career as a businessman in Dhone and cherishes memories from the 2006-2007 batch.', 'class_group_photo.jpg'),
('DADU GOLLA VINUTHA', 'Female', 'Software Tester', 'Guntakal', 'Dadu has built a successful career as a software tester in Guntakal and cherishes memories from the 2006-2007 batch.', 'reunion_002.jpg'),
('YERROLLA YELLAMMA', 'Female', 'Veterinary Doctor', 'Nandyal', 'Yerrolla has built a successful career as a veterinary doctor in Nandyal and cherishes memories from the 2006-2007 batch.', 'class_group_photo.jpg'),
('SADLA YASODHA', 'Female', 'Farmer', 'Kadapa', 'Sadla has built a successful career as a farmer in Kadapa and cherishes memories from the 2006-2007 batch.', 'class_group_photo.jpg');
