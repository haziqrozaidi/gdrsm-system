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
    FOREIGN KEY (user_id) REFERENCES user(user_id),
    FOREIGN KEY (parent_folder_id) REFERENCES folder(folder_id)
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
    FOREIGN KEY (user_id) REFERENCES user(user_id),
    FOREIGN KEY (folder_id) REFERENCES folder(folder_id),
    FOREIGN KEY (category_id) REFERENCES category(category_id)
);

-- Create user_group table
CREATE TABLE user_group (
    group_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    date_created DATETIME DEFAULT CURRENT_TIMESTAMP,
    user_id INT,
    FOREIGN KEY (user_id) REFERENCES user(user_id)
);

-- Create group_members table
CREATE TABLE group_members (
    user_id INT,
    group_id INT,
    date_joined DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, group_id),
    FOREIGN KEY (user_id) REFERENCES user(user_id),
    FOREIGN KEY (group_id) REFERENCES user_group(group_id)
);

-- Create user_resource table
CREATE TABLE user_resource (
    user_id INT,
    resource_id INT,
    date_shared DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, resource_id),
    FOREIGN KEY (user_id) REFERENCES user(user_id),
    FOREIGN KEY (resource_id) REFERENCES resource(resource_id)
);

-- Create group_resource table
CREATE TABLE group_resource (
    group_id INT,
    resource_id INT,
    date_shared DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (group_id, resource_id),
    FOREIGN KEY (group_id) REFERENCES user_group(group_id),
    FOREIGN KEY (resource_id) REFERENCES resource(resource_id)
);
