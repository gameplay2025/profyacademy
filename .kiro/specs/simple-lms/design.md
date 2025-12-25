# Design Document: Simple LMS

## Overview

This design describes a lightweight Learning Management System built with vanilla web technologies (HTML, Tailwind CSS via CDN, Vanilla JS) and Supabase v2 as the backend. The system provides role-based access control for 30 students, allowing students to view schedules and download materials while assistants/admins can manage content.

The architecture follows a simple client-side approach where all logic runs in the browser, communicating directly with Supabase services (Auth, Database, Storage).

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Browser Client                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐          │
│  │ index.html  │  │dashboard.html│  │   app.js   │          │
│  │  (Login)    │  │  (Main UI)  │  │  (Logic)   │          │
│  └─────────────┘  └─────────────┘  └─────────────┘          │
│                           │                                  │
│                    Supabase JS SDK v2                        │
└───────────────────────────┼─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    Supabase Backend                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐          │
│  │    Auth     │  │  Database   │  │   Storage   │          │
│  │  (Users)    │  │ (Postgres)  │  │ (materials) │          │
│  └─────────────┘  └─────────────┘  └─────────────┘          │
│                           │                                  │
│                    Row Level Security                        │
└─────────────────────────────────────────────────────────────┘
```

### Flow Overview

1. User visits `index.html` → Login form
2. Supabase Auth validates credentials
3. On success, redirect to `dashboard.html`
4. Dashboard fetches user profile (role) from `profiles` table
5. UI renders based on role (hide/show controls)
6. Data operations go through Supabase client, enforced by RLS

## Components and Interfaces

### File Structure

```
/
├── index.html      # Login page
├── dashboard.html  # Main dashboard with role-based UI
└── app.js          # Supabase client and all application logic
```

### index.html (Login Page)

Responsibilities:
- Display login form (email, password)
- Initialize Supabase client
- Handle login submission
- Redirect to dashboard on success
- Display error messages on failure

### dashboard.html (Main Dashboard)

Responsibilities:
- Check authentication state on load
- Redirect to login if not authenticated
- Fetch and display user role
- Render schedule table
- Render materials list (PDFs with download, YouTube embeds)
- Conditionally render admin controls based on role

UI Sections:
- Header with user info and logout button
- Schedule section (table view)
- Materials section (list view)
- Admin panel (hidden for students): Upload PDF form, Add YouTube form, Edit Schedule form

### app.js (Application Logic)

```javascript
// Supabase Client Initialization
const supabaseUrl = 'https://amgciwtmhoucdrziahob.supabase.co';
const supabaseKey = 'sb_publishable_Jy9axgSNBZbuOIzA-oTQrw_YJPF5hKz';
const supabase = supabase.createClient(supabaseUrl, supabaseKey);

// Core Functions
async function login(email, password) → { user, error }
async function logout() → void
async function getCurrentUser() → user | null
async function getUserRole(userId) → 'admin' | 'assistant' | 'student'
async function getSchedule() → ScheduleEntry[]
async function getMaterials() → Material[]
async function addScheduleEntry(day, time, subject) → { data, error }
async function updateScheduleEntry(id, day, time, subject) → { data, error }
async function deleteScheduleEntry(id) → { data, error }
async function uploadPDF(file, title) → { data, error }
async function addYouTubeLink(title, url) → { data, error }
async function deleteMaterial(id) → { data, error }
```

## Data Models

### Database Schema

#### profiles table
```sql
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'student' CHECK (role IN ('admin', 'assistant', 'student')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### materials table
```sql
CREATE TABLE materials (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('pdf', 'youtube')),
  url TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### schedule table
```sql
CREATE TABLE schedule (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  day TEXT NOT NULL,
  time TEXT NOT NULL,
  subject TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Trigger for Auto-Profile Creation

```sql
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, role)
  VALUES (NEW.id, 'student');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

### Row Level Security Policies

#### profiles table
- SELECT: Users can read their own profile
- No INSERT/UPDATE/DELETE via client (managed by trigger/admin)

#### materials table
- SELECT: All authenticated users
- INSERT/UPDATE/DELETE: Only admin and assistant roles

#### schedule table
- SELECT: All authenticated users
- INSERT/UPDATE/DELETE: Only admin and assistant roles

### Storage Bucket

- Bucket name: `materials`
- Public access: No (authenticated only)
- Policies: 
  - SELECT: All authenticated users
  - INSERT/DELETE: Admin and assistant roles only



## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: New User Default Role Assignment

*For any* newly created user in auth.users, the trigger SHALL automatically create a corresponding profile with role = 'student'.

**Validates: Requirements 2.2**

### Property 2: Role Constraint Validation

*For any* profile record, the role field SHALL only accept values from the set {'admin', 'assistant', 'student'}. Any attempt to insert or update with an invalid role SHALL be rejected by the database.

**Validates: Requirements 2.3**

### Property 3: Student Read-Only Access

*For any* user with role = 'student', and *for any* INSERT, UPDATE, or DELETE operation on the materials or schedule tables, the operation SHALL be denied by RLS policies. Only SELECT operations SHALL succeed.

**Validates: Requirements 3.5, 4.4, 6.2**

### Property 4: Staff Full CRUD Access

*For any* user with role = 'admin' or role = 'assistant', and *for any* CRUD operation (SELECT, INSERT, UPDATE, DELETE) on the materials or schedule tables, the operation SHALL succeed (assuming valid data).

**Validates: Requirements 3.6, 4.5, 6.3**

### Property 5: Profile Self-Read Restriction

*For any* authenticated user, they SHALL be able to SELECT their own profile record (where profiles.id = auth.uid()). Attempts to SELECT other users' profiles SHALL return no rows.

**Validates: Requirements 6.4**

### Property 6: UI Role-Based Rendering Consistency

*For any* user role fetched from the database, the dashboard UI SHALL render admin controls (upload forms, edit buttons, delete buttons) if and only if the role is 'admin' or 'assistant'. For role = 'student', these controls SHALL be hidden.

**Validates: Requirements 5.1, 5.2, 5.3**

## Error Handling

### Authentication Errors

| Error | Handling |
|-------|----------|
| Invalid credentials | Display "Invalid email or password" message, keep user on login page |
| Network error | Display "Connection error. Please try again." message |
| Session expired | Redirect to login page with "Session expired" message |

### Database Errors

| Error | Handling |
|-------|----------|
| RLS policy violation | Display "You don't have permission to perform this action" |
| Constraint violation | Display specific validation error (e.g., "Invalid role value") |
| Connection error | Display "Database connection error. Please refresh." |

### Storage Errors

| Error | Handling |
|-------|----------|
| Upload failed | Display "File upload failed. Please try again." |
| File too large | Display "File exceeds maximum size limit" |
| Invalid file type | Display "Only PDF files are allowed" |

### Client-Side Validation

- Email format validation before submission
- Password minimum length check
- Required field validation for all forms
- File type validation (PDF only) before upload
- URL format validation for YouTube links

## Testing Strategy

### Unit Tests

Unit tests will verify specific examples and edge cases:

1. **Login form validation** - Test email format, empty fields
2. **Role-based UI rendering** - Test that correct elements show/hide for each role
3. **Form submissions** - Test that forms call correct Supabase methods
4. **Error message display** - Test that errors render correctly

### Property-Based Tests

Property-based tests will use a testing framework to verify universal properties across many generated inputs. For this vanilla JS project, we'll use **fast-check** for property-based testing.

Configuration:
- Minimum 100 iterations per property test
- Each test tagged with: **Feature: simple-lms, Property {number}: {property_text}**

Property tests to implement:
1. **Property 1**: Generate random user data, verify profile created with 'student' role
2. **Property 2**: Generate random role strings, verify only valid roles accepted
3. **Property 3**: Generate random operations as student, verify all writes denied
4. **Property 4**: Generate random operations as admin/assistant, verify all succeed
5. **Property 5**: Generate random user pairs, verify profile isolation
6. **Property 6**: Generate random roles, verify UI state matches expected visibility

### Integration Tests

1. Full login flow (valid and invalid credentials)
2. Dashboard load with role fetch
3. PDF upload to storage and database record creation
4. YouTube link addition
5. Schedule CRUD operations

### Manual Testing Checklist

- [ ] Login with valid credentials redirects to dashboard
- [ ] Login with invalid credentials shows error
- [ ] Student sees schedule and materials but no edit controls
- [ ] Admin/Assistant sees all controls
- [ ] PDF upload works and appears in materials list
- [ ] YouTube link addition works
- [ ] Schedule editing works
- [ ] Logout works and redirects to login
