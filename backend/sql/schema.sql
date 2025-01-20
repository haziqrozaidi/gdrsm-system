-- Create user table
CREATE TABLE user (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) NOT NULL UNIQUE,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL,
    faculty VARCHAR(100) NOT NULL
);

-- Create folder table
CREATE TABLE folder (
    folder_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    date_created DATETIME DEFAULT CURRENT_TIMESTAMP,
    user_id INT,
    parent_folder_id INT,
    FOREIGN KEY (user_id) REFERENCES user(user_id) ON DELETE CASCADE,
    FOREIGN KEY (parent_folder_id) REFERENCES folder(folder_id) ON DELETE CASCADE
);

-- Create category table
CREATE TABLE category (
    category_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL,
    description TEXT,
    date_created DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Create resource table
CREATE TABLE resource (
    resource_id INT PRIMARY KEY AUTO_INCREMENT,
    link VARCHAR(255) NOT NULL,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(50) NOT NULL,
    description TEXT,
    owner VARCHAR(100) NOT NULL,
    date_created DATETIME DEFAULT CURRENT_TIMESTAMP,
    session VARCHAR(20),
    semester VARCHAR(20),
    user_id INT,
    folder_id INT,
    category_id INT,
    FOREIGN KEY (user_id) REFERENCES user(user_id) ON DELETE CASCADE,
    FOREIGN KEY (folder_id) REFERENCES folder(folder_id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES category(category_id) ON DELETE CASCADE
);

-- Create user_group table
CREATE TABLE user_group (
    group_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    date_created DATETIME DEFAULT CURRENT_TIMESTAMP,
    user_id INT,
    FOREIGN KEY (user_id) REFERENCES user(user_id) ON DELETE CASCADE
);

-- Create group_members table
CREATE TABLE group_members (
    user_id INT,
    group_id INT,
    date_joined DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, group_id),
    FOREIGN KEY (user_id) REFERENCES user(user_id) ON DELETE CASCADE,
    FOREIGN KEY (group_id) REFERENCES user_group(group_id) ON DELETE CASCADE
);

-- Create user_resource table
CREATE TABLE user_resource (
    user_id INT,
    resource_id INT,
    date_shared DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, resource_id),
    FOREIGN KEY (user_id) REFERENCES user(user_id) ON DELETE CASCADE,
    FOREIGN KEY (resource_id) REFERENCES resource(resource_id) ON DELETE CASCADE
);

-- Create group_resource table
CREATE TABLE group_resource (
    group_id INT,
    resource_id INT,
    date_shared DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (group_id, resource_id),
    FOREIGN KEY (group_id) REFERENCES user_group(group_id) ON DELETE CASCADE,
    FOREIGN KEY (resource_id) REFERENCES resource(resource_id) ON DELETE CASCADE
);

-- Create table for logging function no need to populate
CREATE TABLE logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    action VARCHAR(255) NOT NULL,
    resource_name VARCHAR(255) NOT NULL,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES user(user_id) ON DELETE CASCADE
);