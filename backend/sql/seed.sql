-- Insert dummy users
INSERT INTO user (username, full_name, email, password, role, faculty) VALUES
('john_doe', 'John Doe', 'john.doe@utm.my', 'hashed_password123', 'lecturer', 'Faculty of Computing'),
('jane_smith', 'Jane Smith', 'jane.smith@utm.my', 'hashed_password456', 'student', 'Faculty of Computing'),
('bob_wilson', 'Bob Wilson', 'bob.wilson@utm.my', 'hashed_password789', 'admin', 'Faculty of Computing'),
('alice_wong', 'Alice Wong', 'alice.wong@utm.my', 'hashed_password101', 'lecturer', 'Faculty of Computing'),
('sam_lee', 'Sam Lee', 'sam.lee@utm.my', 'hashed_password202', 'student', 'Faculty of Computing');

-- Insert dummy categories
INSERT INTO category (name, description) VALUES
('Lecture Notes', 'Materials used during lectures'),
('Tutorials', 'Tutorial materials and exercises'),
('Assignments', 'Assignment documents and submissions'),
('Past Papers', 'Previous examination papers'),
('References', 'Additional reading materials');

-- Insert dummy folders
INSERT INTO folder (name, description, user_id) VALUES
('Semester 1 2023', 'Main folder for Semester 1 2023', 1),
('Programming Fundamentals', 'Course materials for Programming', 2),
('Database Systems', 'Database course resources', 3),
('Software Engineering', 'SE course materials', 4),
('Project Management', 'PM documentation', 5);

-- Insert sub-folders (using parent_folder_id)
INSERT INTO folder (name, description, user_id, parent_folder_id) VALUES
('Week 1', 'First week materials', 1, 1),
('Week 2', 'Second week materials', 2, 2),
('Assignments', 'All assignments', 3, 3),
('Labs', 'Laboratory materials', 4, 4),
('Notes', 'Lecture notes', 5, 5);

-- Insert dummy resources
INSERT INTO resource (link, name, type, description, owner, session, semester, user_id, folder_id, category_id) VALUES
('https://drive.google.com/file1', 'Introduction to Programming.pdf', 'file', 'Week 1 lecture slides', 'lecturer1@external.com', '2023/2024', '1', 1, 1, 1),
('https://drive.google.com/file2', 'Database Design.docx', 'file', 'Database design documentation', 'lecturer2@external.com', '2023/2024', '1', 2, 2, 2),
('https://drive.google.com/folder1', 'Project Resources', 'folder', 'Project materials and guidelines', 'lecturer3@external.com', '2023/2024', '1', 3, 3, 3),
('https://drive.google.com/file3', 'Assignment 1.pdf', 'file', 'First assignment document', 'lecturer4@external.com', '2023/2024', '1', 4, 4, 4),
('https://drive.google.com/folder2', 'Reference Materials', 'folder', 'Additional reading resources', 'lecturer5@external.com', '2023/2024', '1', 5, 5, 5);

-- Insert dummy user groups
INSERT INTO user_group (name, description, user_id) VALUES
('Programming Group A', 'Study group for programming course', 1),
('Database Team', 'Database project team', 2),
('SE Project Group', 'Software Engineering project group', 3),
('Research Team', 'Research collaboration group', 4),
('Tutorial Group B', 'Tutorial discussion group', 5);

-- Insert dummy group members
INSERT INTO group_members (user_id, group_id) VALUES
(1, 1), (2, 1), (3, 1),
(2, 2), (3, 2), (4, 2),
(3, 3), (4, 3), (5, 3),
(4, 4), (5, 4), (1, 4),
(5, 5), (1, 5), (2, 5);

-- Insert dummy user resource sharing
INSERT INTO user_resource (user_id, resource_id) VALUES
(1, 1), (2, 1),
(2, 2), (3, 2),
(3, 3), (4, 3),
(4, 4), (5, 4),
(5, 5), (1, 5);

-- Insert dummy group resource sharing
INSERT INTO group_resource (group_id, resource_id) VALUES
(1, 1), (1, 2),
(2, 2), (2, 3),
(3, 3), (3, 4),
(4, 4), (4, 5),
(5, 5), (5, 1);
