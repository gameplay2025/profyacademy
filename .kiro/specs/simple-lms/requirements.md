# Requirements Document

## Introduction

A simple Learning Management System (LMS) for 30 students built with HTML, Tailwind CSS (CDN), and Vanilla JS with Supabase v2 as the backend. The system provides role-based access control where students can view content while assistants/admins can manage it.

## Glossary

- **LMS**: Learning Management System - the web application being built
- **Supabase**: Backend-as-a-Service providing authentication, database, and storage
- **RLS**: Row Level Security - Supabase's policy-based access control
- **Profile**: User metadata including role assignment
- **Material**: Educational content (PDFs, YouTube links) uploaded by staff
- **Schedule**: Class timetable with day, time, and subject information
- **Student**: User role with read-only access to materials and schedule
- **Assistant**: User role with full CRUD access to materials and schedule
- **Admin**: User role with full CRUD access to materials and schedule

## Requirements

### Requirement 1: User Authentication

**User Story:** As a user, I want to log in securely so that I can access the LMS dashboard.

#### Acceptance Criteria

1. WHEN a user visits the login page, THE LMS SHALL display email and password input fields with a login button
2. WHEN a user submits valid credentials, THE LMS SHALL authenticate via Supabase Auth and redirect to the dashboard
3. WHEN a user submits invalid credentials, THE LMS SHALL display an error message without redirecting
4. WHEN an unauthenticated user tries to access the dashboard, THE LMS SHALL redirect them to the login page

### Requirement 2: Role-Based Profile Management

**User Story:** As a system administrator, I want users to have roles so that I can control access to features.

#### Acceptance Criteria

1. THE Database SHALL store user profiles linked to auth.users with a role field
2. WHEN a new user registers, THE Database SHALL automatically assign the 'student' role via trigger
3. THE Profile table SHALL support three roles: 'admin', 'assistant', and 'student'
4. WHEN the dashboard loads, THE LMS SHALL fetch the current user's role from the profiles table

### Requirement 3: Materials Management

**User Story:** As an assistant/admin, I want to upload educational materials so that students can access them.

#### Acceptance Criteria

1. THE Database SHALL store materials with id, title, type ('pdf' or 'youtube'), url, and created_at fields
2. WHEN an assistant/admin uploads a PDF, THE LMS SHALL store the file in Supabase Storage bucket 'materials'
3. WHEN an assistant/admin adds a YouTube link, THE LMS SHALL save the URL to the materials table
4. WHEN a student views materials, THE LMS SHALL display download links for PDFs and embedded YouTube videos
5. WHILE a user has 'student' role, THE Database SHALL only allow SELECT operations on materials
6. WHILE a user has 'assistant' or 'admin' role, THE Database SHALL allow INSERT, UPDATE, and DELETE on materials

### Requirement 4: Schedule Management

**User Story:** As an assistant/admin, I want to manage the class schedule so that students know when classes occur.

#### Acceptance Criteria

1. THE Database SHALL store schedule entries with id, day, time, and subject fields
2. WHEN an assistant/admin edits the schedule, THE LMS SHALL update the schedule table
3. WHEN any user views the dashboard, THE LMS SHALL display the current schedule
4. WHILE a user has 'student' role, THE Database SHALL only allow SELECT operations on schedule
5. WHILE a user has 'assistant' or 'admin' role, THE Database SHALL allow INSERT, UPDATE, and DELETE on schedule

### Requirement 5: Role-Based UI Rendering

**User Story:** As a user, I want to see only the features I have access to so that the interface is not confusing.

#### Acceptance Criteria

1. WHEN a student views the dashboard, THE LMS SHALL hide all upload, edit, and delete buttons
2. WHEN an assistant/admin views the dashboard, THE LMS SHALL display upload PDF form, add YouTube link form, and edit schedule controls
3. WHEN the user's role is fetched, THE LMS SHALL conditionally render UI elements based on that role

### Requirement 6: Row Level Security

**User Story:** As a system administrator, I want database-level security so that unauthorized access is prevented even if UI is bypassed.

#### Acceptance Criteria

1. THE Database SHALL have RLS enabled on profiles, materials, and schedule tables
2. THE Database SHALL have policies allowing all authenticated users to SELECT from materials and schedule
3. THE Database SHALL have policies allowing only admin/assistant roles to INSERT, UPDATE, DELETE on materials and schedule
4. THE Database SHALL have policies allowing users to read their own profile
