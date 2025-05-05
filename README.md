# Project Name

> A web system for managing and sharing Google Drive resources within UTM's Faculty of Computing.

## Table of Contents

- [About](#about)
  - [Demo Video](#demo-video)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Usage](#usage)
- [Contributing](#contributing)
- [Acknowledgments](#acknowledgments)

## About

The Google Drive Resource Sharing Management System (GDRSMS) is a web application built to help students, lecturers, and administrators at UTM's Faculty of Computing share academic resources more easily. Instead of sending Google Drive links through emails or chats, users can upload, manage, and share them directly within the system. Lecturers can create groups, add students, and share resources with them. Users can also search for shared links, update or remove them, and organize everything in one place. GDRSMS was developed using agile methods, which means it is updated often based on feedback to keep improving the user experience.

### Demo Video

To get a quick overview of how the system works, check out this demo video:

[![Watch the Video](https://img.youtube.com/vi/WWaKVyBhrlI/maxresdefault.jpg)](https://youtu.be/WWaKVyBhrlI)

## Features

- Manage academic resources by adding, updating, deleting, sharing, and viewing resources within the system
- Lecturers can create, update, delete groups, view group details, and add members to groups for easy resource sharing
- Users can share resources with individuals or groups and quickly search for resources based on specific criteria
- Admins can organize resources by adding, updating, and deleting categories
- Admins can manage user roles by updating or deleting roles as needed

## Tech Stack

A list of technologies, frameworks, and tools used in the project. For example:

- **Frontend**: Vue.js, PrimeVue, TailwindCSS
- **Backend**: Mojolicious, MySQL
- **DevOps**: Docker
- **Languages**: HTML, CSS, JavaScript, Perl, SQL

## Getting Started

Instructions on how to set up and use the project locally.

### Prerequisites

Before running the project, make sure you have the following installed:

- `Node.js (v16+)`
- `MySQL (v5.7+)`
- `Docker`
- `Perl (v5.30+)`
- `npm (v7+)`

### Installation

Step-by-step instructions on how to install your project:

1. **Clone or Download the Repository**: Clone the repository using Git or download the ZIP file and extract it:

   ```bash
   git clone <repository-url>
   ```

2. **Navigate to the Project Directory**: Open a terminal and navigate to the directory containing the project files:

   ```bash
   cd <repository-folder>
   ```

3. **Update Database Configuration**: Set the value of `backend/config/database.yml` to the following:

   ```yaml
   ---
   database:
     dsn: 'dbi:mysql:database=gdrsms;host=mysql;mysql_ssl=1'
     username: 'aatrox'
     password: '12345'
   ```

4. **Build and Run the System**: Use Docker Compose to build and start the application:

   ```bash
   docker compose up --build
   ```

5. **Access the Web Application**: Once the system is running, open your web browser and go to:

   ```
   http://localhost:5173/
   ```

### Usage

Once the system is up and running, you can start using the application by following these steps:

1. **Access the Application**:  
   Open your web browser and go to:

   ```url
   http://localhost:5173/
   ```

2. **Log In**:  
   Use the credentials for your role (Student, Lecturer, or Admin) to log in to the system. Below are the login credentials for each type of account:

   - **Lecturer**  
     - Username: `12085`  
     - Password: `S808323`  

   - **Student**  
     - Username: Your Matric Number  
     - Password: Your Identity Card Number  

   - **Administrator**  
     - Username: `bob_wilson`  
     - Password: `hashed_password789`  

## Contributing

We welcome contributions to the **Google Drive Resource Sharing Management System (GDRSMS)**! If you'd like to contribute, follow these steps:

1. **Fork the Repository**  
   Click the "Fork" button at the top-right of this repository to create a copy of the project under your GitHub account.

2. **Create a Feature Branch**  
   After forking, create a new branch for your feature or bug fix:

   ```bash
   git checkout -b my-new-feature
   ```

3. **Make Your Changes**  
   Implement the changes or additions you want to contribute.

4. **Commit Your Changes**  
   Once you're happy with the changes, commit them with a clear and concise message:

   ```bash
   git commit -m 'Add a new feature or fix a bug'
   ```

5. **Push to Your Branch**  
   Push your changes to your forked repository:

   ```bash
   git push origin my-new-feature
   ```

6. **Create a Pull Request**  
   Go to your repository on GitHub and open a pull request to the main repository. Provide a description of the changes you’ve made.

## Acknowledgments

Special thanks to the following individuals for their invaluable contributions to the **Google Drive Resource Sharing Management System (GDRSMS)**:

- **Muhammad Haziq Bin Rozaidi**
- **Muhammad Syahmi Syazwan Bin Shuhairam**
- **Jolyn Lin Xin En**
- **Edwin Koh Wei Shan**

Their hard work, dedication, and collaboration were essential to the success of this project.
