-- Drop the database if it exists to start fresh
DROP DATABASE IF EXISTS pakistan_voting_system;

-- Create the database
CREATE DATABASE pakistan_voting_system;
USE pakistan_voting_system;

-- Create provinces table
CREATE TABLE provinces (
    province_id INT AUTO_INCREMENT PRIMARY KEY,
    province_name VARCHAR(50) NOT NULL UNIQUE
);

-- Create cities table
CREATE TABLE cities (
    city_id INT AUTO_INCREMENT PRIMARY KEY,
    city_name VARCHAR(100) NOT NULL,
    province_id INT NOT NULL,
    FOREIGN KEY (province_id) REFERENCES provinces(province_id),
    UNIQUE KEY (city_name, province_id)
);

-- Create polling_stations table
CREATE TABLE polling_stations (
    station_id INT AUTO_INCREMENT PRIMARY KEY,
    station_name VARCHAR(100) NOT NULL,
    address VARCHAR(255) NOT NULL,
    city_id INT NOT NULL,
    FOREIGN KEY (city_id) REFERENCES cities(city_id)
);

-- Create voters table
CREATE TABLE voters (
    voter_id INT AUTO_INCREMENT PRIMARY KEY,
    id_number VARCHAR(50) NOT NULL UNIQUE,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    father_name VARCHAR(100) NOT NULL,
    gender ENUM('Male', 'Female', 'Other') NOT NULL,
    address VARCHAR(255) NOT NULL,
    city_id INT NOT NULL,
    polling_station_id INT NOT NULL,
    has_voted BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (city_id) REFERENCES cities(city_id),
    FOREIGN KEY (polling_station_id) REFERENCES polling_stations(station_id)
);

-- Create elections table
CREATE TABLE elections (
    election_id INT AUTO_INCREMENT PRIMARY KEY,
    election_name VARCHAR(100) NOT NULL,
    election_date DATE NOT NULL,
    status ENUM('Upcoming', 'Active', 'Completed') DEFAULT 'Upcoming'
);

-- Create parties table
CREATE TABLE parties (
    party_id INT AUTO_INCREMENT PRIMARY KEY,
    party_name VARCHAR(100) NOT NULL UNIQUE
);

-- Create votes table
CREATE TABLE votes (
    vote_id INT AUTO_INCREMENT PRIMARY KEY,
    election_id INT NOT NULL,
    voter_id INT NOT NULL,
    polling_station_id INT NOT NULL,
    party_id INT NOT NULL,
    voting_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (election_id) REFERENCES elections(election_id),
    FOREIGN KEY (voter_id) REFERENCES voters(voter_id),
    FOREIGN KEY (polling_station_id) REFERENCES polling_stations(station_id),
    FOREIGN KEY (party_id) REFERENCES parties(party_id),
    UNIQUE KEY (voter_id, election_id)
);

-- Insert sample data into provinces
INSERT INTO provinces (province_name) VALUES 
('Punjab'),
('Sindh'),
('Khyber Pakhtunkhwa'),
('Balochistan'),
('Islamabad Capital Territory');

-- Insert sample data into cities
INSERT INTO cities (city_name, province_id) VALUES 
('Lahore', 1),
('Karachi', 2),
('Peshawar', 3),
('Quetta', 4),
('Islamabad', 5);

-- Insert sample data into polling_stations
INSERT INTO polling_stations (station_name, address, city_id) VALUES 
('Lahore Central High School', '123 Mall Road, Lahore', 1),
('Karachi Public School', '456 Shahrah-e-Faisal, Karachi', 2),
('Peshawar District School', '101 Saddar Road, Peshawar', 3),
('Quetta Grammar School', '202 Jinnah Road, Quetta', 4),
('Islamabad Model College', '789 Blue Area, Islamabad', 5);

-- Insert sample data into elections
INSERT INTO elections (election_name, election_date, status) VALUES 
('General Election 2023', '2023-08-15', 'Completed'),
('By-Election 2024', '2024-03-10', 'Completed'),
('General Election 2025', '2025-06-01', 'Upcoming');

-- Insert sample data into parties
INSERT INTO parties (party_name) VALUES 
('Pakistan Muslim League (N)'),
('Pakistan Peoples Party'),
('Pakistan Tehreek-e-Insaf'),
('Muttahida Qaumi Movement'),
('Independent');

-- Insert sample data into voters
INSERT INTO voters (id_number, first_name, last_name, father_name, gender, address, city_id, polling_station_id, has_voted) VALUES 
('35201-1234567-1', 'Muhammad', 'Ahmed', 'Abdul Hameed', 'Male', '123 Garden Town, Lahore', 1, 1, TRUE),
('35201-2345678-2', 'Ayesha', 'Khan', 'Muhammad Tariq', 'Female', '456 Model Town, Lahore', 1, 1, FALSE),
('42101-3456789-3', 'Bilal', 'Malik', 'Abdul Malik', 'Male', '123 Clifton, Karachi', 2, 2, TRUE),
('42101-4567890-4', 'Zainab', 'Ahmed', 'Muhammad Imran', 'Female', '456 DHA, Karachi', 2, 2, TRUE),
('17201-5678901-5', 'Naveed', 'Khan', 'Abdullah Khan', 'Male', '123 Hayatabad, Peshawar', 3, 3, FALSE),
('17201-6789012-6', 'Nadia', 'Yousaf', 'Muhammad Yousaf', 'Female', '456 University Town, Peshawar', 3, 3, TRUE),
('21201-7890123-7', 'Khalid', 'Baloch', 'Ahmed Baloch', 'Male', '123 Jinnah Road, Quetta', 4, 4, FALSE),
('21201-8901234-8', 'Amina', 'Kakar', 'Abdul Kakar', 'Female', '456 Shahbaz Town, Quetta', 4, 4, FALSE),
('13101-9012345-9', 'Adeel', 'Shahid', 'Muhammad Shahid', 'Male', '123 F-10/2, Islamabad', 5, 5, TRUE),
('13101-0123456-0', 'Saima', 'Zafar', 'Muhammad Zafar', 'Female', '456 G-9/4, Islamabad', 5, 5, FALSE);

-- Insert sample data into votes
INSERT INTO votes (election_id, voter_id, polling_station_id, party_id, voting_time) VALUES 
(1, 1, 1, 1, '2023-08-15 09:00:00'),
(1, 3, 2, 2, '2023-08-15 10:30:00'),
(1, 4, 2, 3, '2023-08-15 11:15:00'),
(1, 6, 3, 4, '2023-08-15 12:00:00'),
(1, 9, 5, 5, '2023-08-15 13:45:00'),
(2, 1, 1, 1, '2024-03-10 09:30:00'),
(2, 4, 2, 3, '2024-03-10 10:00:00');

-- Create voter_details view (optional, but kept for flexibility)
CREATE VIEW voter_details AS
SELECT 
    v.voter_id,
    v.id_number,
    v.first_name,
    v.last_name,
    v.father_name,
    v.gender,
    v.address,
    c.city_name,
    p.province_name,
    ps.station_name AS polling_station,
    v.has_voted
FROM voters v
JOIN cities c ON v.city_id = c.city_id
JOIN provinces p ON c.province_id = p.province_id
JOIN polling_stations ps ON v.polling_station_id = ps.station_id;

-- Create search_voters procedure
DELIMITER //
CREATE PROCEDURE search_voters(
    IN p_first_name VARCHAR(50),
    IN p_last_name VARCHAR(50),
    IN p_father_name VARCHAR(100),
    IN p_city_id INT,
    IN p_has_voted BOOLEAN,
    IN p_gender ENUM('Male', 'Female', 'Other'),
    IN p_province_id INT,
    IN p_polling_station_id INT,
    IN p_id_number VARCHAR(50),
    IN p_election_id INT
)
BEGIN
    SELECT 
        v.voter_id,
        v.id_number,
        v.first_name,
        v.last_name,
        v.father_name,
        v.gender,
        v.address,
        c.city_name,
        p.province_name,
        ps.station_name AS polling_station,
        v.has_voted
    FROM voters v
    JOIN cities c ON v.city_id = c.city_id
    JOIN provinces p ON c.province_id = p.province_id
    JOIN polling_stations ps ON v.polling_station_id = ps.station_id
    LEFT JOIN votes vt ON v.voter_id = vt.voter_id AND (p_election_id IS NULL OR vt.election_id = p_election_id)
    WHERE (p_first_name IS NULL OR v.first_name LIKE CONCAT('%', p_first_name, '%'))
    AND (p_last_name IS NULL OR v.last_name LIKE CONCAT('%', p_last_name, '%'))
    AND (p_father_name IS NULL OR v.father_name LIKE CONCAT('%', p_father_name, '%'))
    AND (p_city_id IS NULL OR v.city_id = p_city_id)
    AND (p_has_voted IS NULL OR v.has_voted = p_has_voted)
    AND (p_gender IS NULL OR v.gender = p_gender)
    AND (p_province_id IS NULL OR c.province_id = p_province_id)
    AND (p_polling_station_id IS NULL OR v.polling_station_id = p_polling_station_id)
    AND (p_id_number IS NULL OR v.id_number LIKE CONCAT('%', p_id_number, '%'))
    AND (p_election_id IS NULL OR vt.voter_id IS NOT NULL);
END //
DELIMITER ;

-- Create insert_voter procedure
DELIMITER //
CREATE PROCEDURE insert_voter(
    IN p_id_number VARCHAR(50),
    IN p_first_name VARCHAR(50),
    IN p_last_name VARCHAR(50),
    IN p_father_name VARCHAR(100),
    IN p_gender ENUM('Male', 'Female', 'Other'),
    IN p_address VARCHAR(255),
    IN p_city_id INT,
    IN p_polling_station_id INT
)
BEGIN
    INSERT INTO voters (
        id_number,
        first_name,
        last_name,
        father_name,
        gender,
        address,
        city_id,
        polling_station_id
    ) VALUES (
        p_id_number,
        p_first_name,
        p_last_name,
        p_father_name,
        p_gender,
        p_address,
        p_city_id,
        p_polling_station_id
    );
END //
DELIMITER ;

-- Create insert_vote procedure
DELIMITER //
CREATE PROCEDURE insert_vote(
    IN p_id_number VARCHAR(50),
    IN p_election_id INT,
    IN p_polling_station_id INT,
    IN p_party_id INT
)
BEGIN
    DECLARE v_voter_id INT;
    
    -- Get voter_id from id_number
    SELECT voter_id INTO v_voter_id
    FROM voters
    WHERE id_number = p_id_number
    LIMIT 1;
    
    -- Check if voter exists
    IF v_voter_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Voter not found';
    END IF;
    
    -- Insert vote
    INSERT INTO votes (
        election_id,
        voter_id,
        polling_station_id,
        party_id
    ) VALUES (
        p_election_id,
        v_voter_id,
        p_polling_station_id,
        p_party_id
    );
    
    -- Update has_voted status
    UPDATE voters
    SET has_voted = TRUE
    WHERE voter_id = v_voter_id;
END //
DELIMITER ;

-- Create indexes for performance
CREATE INDEX idx_voters_name ON voters(first_name, last_name);
CREATE INDEX idx_voters_father_name ON voters(father_name);
CREATE INDEX idx_voters_city ON voters(city_id);
CREATE INDEX idx_voters_has_voted ON voters(has_voted);
CREATE INDEX idx_voters_gender ON voters(gender);
CREATE INDEX idx_voters_id_number ON voters(id_number);