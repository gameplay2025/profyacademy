# Implementation Plan: Simple LMS

## Overview

This plan implements a simple LMS with role-based access control using HTML, Tailwind CSS (CDN), Vanilla JS, and Supabase v2. The implementation follows an incremental approach: database setup first, then authentication, then UI with role-based rendering.

## Tasks

- [x] 1. Create SQL setup script for Supabase
  - [x] 1.1 Create profiles table with role constraint and foreign key to auth.users
    - Define UUID primary key referencing auth.users(id)
    - Add role TEXT field with CHECK constraint for 'admin', 'assistant', 'student'
    - Add created_at timestamp
    - _Requirements: 2.1, 2.3_
  - [x] 1.2 Create materials table
    - Define UUID primary key with gen_random_uuid()
    - Add title, type (with CHECK for 'pdf', 'youtube'), url, created_at fields
    - _Requirements: 3.1_
  - [x] 1.3 Create schedule table
    - Define UUID primary key with gen_random_uuid()
    - Add day, time, subject, created_at fields
    - _Requirements: 4.1_
  - [x] 1.4 Create trigger for automatic profile creation
    - Create handle_new_user() function that inserts profile with 'student' role
    - Create trigger on auth.users AFTER INSERT
    - _Requirements: 2.2_
  - [x] 1.5 Enable RLS and create policies
    - Enable RLS on all three tables
    - Create SELECT policy for profiles (own profile only)
    - Create SELECT policy for materials and schedule (all authenticated)
    - Create INSERT/UPDATE/DELETE policies for materials and schedule (admin/assistant only)
    - _Requirements: 3.5, 3.6, 4.4, 4.5, 6.1, 6.2, 6.3, 6.4_
  - [x] 1.6 Create storage bucket policies
    - Document bucket 'materials' creation (manual in Supabase dashboard)
    - Create storage policies for authenticated read, admin/assistant write
    - _Requirements: 3.2_

- [x] 2. Checkpoint - Verify SQL script
  - Run SQL script in Supabase SQL Editor
  - Verify tables created with correct structure
  - Verify RLS is enabled
  - Ask user if questions arise

- [x] 3. Create login page (index.html)
  - [x] 3.1 Create HTML structure with Tailwind CDN
    - Add doctype, head with Tailwind CDN link
    - Add Supabase v2 CDN script
    - Create centered login card layout
    - _Requirements: 1.1_
  - [x] 3.2 Create login form
    - Add email input with validation
    - Add password input
    - Add submit button with loading state
    - Add error message container
    - _Requirements: 1.1, 1.3_
  - [x] 3.3 Add login form submission handler
    - Call app.js login function
    - Handle success (redirect to dashboard)
    - Handle error (display message)
    - _Requirements: 1.2, 1.3_

- [x] 4. Create application logic (app.js)
  - [x] 4.1 Initialize Supabase client
    - Import createClient from CDN
    - Configure with provided URL and key
    - Export client instance
    - _Requirements: 1.2_
  - [x] 4.2 Implement authentication functions
    - login(email, password) - call supabase.auth.signInWithPassword
    - logout() - call supabase.auth.signOut
    - getCurrentUser() - call supabase.auth.getUser
    - _Requirements: 1.2, 1.4_
  - [x] 4.3 Implement profile functions
    - getUserRole(userId) - query profiles table for role
    - _Requirements: 2.4_
  - [x] 4.4 Implement materials functions
    - getMaterials() - query materials table
    - uploadPDF(file, title) - upload to storage, insert record
    - addYouTubeLink(title, url) - insert record with type 'youtube'
    - deleteMaterial(id) - delete from storage (if PDF) and table
    - _Requirements: 3.2, 3.3, 3.4_
  - [x] 4.5 Implement schedule functions
    - getSchedule() - query schedule table
    - addScheduleEntry(day, time, subject) - insert record
    - updateScheduleEntry(id, day, time, subject) - update record
    - deleteScheduleEntry(id) - delete record
    - _Requirements: 4.2, 4.3_

- [x] 5. Create dashboard page (dashboard.html)
  - [x] 5.1 Create HTML structure with Tailwind CDN
    - Add doctype, head with Tailwind CDN
    - Add Supabase v2 CDN script
    - Include app.js script
    - _Requirements: 4.3, 5.1_
  - [x] 5.2 Create header section
    - Display user email
    - Add logout button
    - _Requirements: 1.4_
  - [x] 5.3 Create schedule section
    - Add schedule table with day, time, subject columns
    - Add placeholder for schedule data
    - _Requirements: 4.3_
  - [x] 5.4 Create materials section
    - Add materials list container
    - Template for PDF items (download link)
    - Template for YouTube items (embedded player or link)
    - _Requirements: 3.4_
  - [x] 5.5 Create admin panel (hidden by default)
    - Upload PDF form (file input, title input, submit)
    - Add YouTube link form (title input, URL input, submit)
    - Edit schedule form (day, time, subject inputs, submit)
    - Delete buttons for materials and schedule entries
    - _Requirements: 5.2_
  - [x] 5.6 Implement dashboard initialization
    - Check auth state on load, redirect if not authenticated
    - Fetch user role from profiles
    - Show/hide admin panel based on role
    - Load and display schedule
    - Load and display materials
    - _Requirements: 1.4, 2.4, 5.1, 5.2, 5.3_
  - [x] 5.7 Wire up form handlers
    - PDF upload form → uploadPDF function
    - YouTube form → addYouTubeLink function
    - Schedule form → addScheduleEntry function
    - Delete buttons → respective delete functions
    - Refresh lists after mutations
    - _Requirements: 3.2, 3.3, 4.2_

- [x] 6. Final checkpoint - End-to-end verification
  - Verify login flow works
  - Verify student sees read-only view
  - Verify admin/assistant sees edit controls
  - Verify PDF upload works
  - Verify schedule editing works
  - Ask user if questions arise

- [ ]*  7. Write property tests
  - [ ]* 7.1 Write property test for new user default role
    - **Property 1: New User Default Role Assignment**
    - **Validates: Requirements 2.2**
  - [ ]* 7.2 Write property test for role constraint validation
    - **Property 2: Role Constraint Validation**
    - **Validates: Requirements 2.3**
  - [ ]* 7.3 Write property test for student read-only access
    - **Property 3: Student Read-Only Access**
    - **Validates: Requirements 3.5, 4.4, 6.2**
  - [ ]* 7.4 Write property test for staff CRUD access
    - **Property 4: Staff Full CRUD Access**
    - **Validates: Requirements 3.6, 4.5, 6.3**
  - [ ]* 7.5 Write property test for profile self-read restriction
    - **Property 5: Profile Self-Read Restriction**
    - **Validates: Requirements 6.4**
  - [ ]* 7.6 Write property test for UI role-based rendering
    - **Property 6: UI Role-Based Rendering Consistency**
    - **Validates: Requirements 5.1, 5.2, 5.3**

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- SQL script should be run manually in Supabase SQL Editor
- Storage bucket 'materials' must be created manually in Supabase dashboard before testing uploads
- The provided Supabase URL and key placeholders should be replaced with actual values
