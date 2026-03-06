# Admin Hierarchy System - Implementation Guide

## Overview

Eventix now features a comprehensive 3-tier admin hierarchy system with request-based approval workflow. This ensures professional governance over admin account creation.

## System Architecture

### 3-Tier Role System

```
┌─────────────┐
│  SuperAdmin │  (Initial setup required)
│ (Authorizes │  - Can approve/reject admin requests
│   admins)   │  - Can manage platform-wide settings
└─────────────┘
       ↓
┌─────────────┐
│    Admin    │  (Created via approval)
│  (Creates & │  - Can create and manage events
│  Manages    │  - Can moderate event content
│   Events)   │
└─────────────┘
       ↓
┌─────────────┐
│    User     │  (Direct registration)
│  (Books     │  - Can register immediately
│   Events)   │  - Can book and cancel event tickets
└─────────────┘
```

## User Registration Flow

### Regular User Registration (Existing Flow)

```
1. User clicks "Register" without checking admin box
2. User data + password validation
3. Account created immediately with:
   - role: "user"
   - isApproved: true
   - adminRequestStatus: "none"
4. User can book events immediately
```

### Admin Request Registration (NEW)

```
1. User clicks "Register" + checks "Request Admin Access" checkbox
2. User data + password validation
3. Instead of creating active account:
   - User record created with:
     - role: "user" (temporary)
     - isApproved: false
     - adminRequestStatus: "pending"
     - adminRequestDate: timestamp
   - AdminRequest document created with:
     - status: "pending"
     - createdAt: timestamp
4. Success message: "Admin request submitted. Your account will be created once approved by a super admin."
5. User cannot login until approved
```

### Admin Approval Flow

```
SuperAdmin Dashboard → Admin Requests Tab
    ↓
1. SuperAdmin sees pending admin requests
2. SuperAdmin clicks "Approve" button
   - Confirmation modal appears
   - SuperAdmin confirms action
3. System:
   - Updates User: isApproved = true, role = "admin"
   - Updates AdminRequest: status = "approved", approvalDate
   - User can now login as admin
   - User can create/manage events
4. Success message: "Admin request from [name] has been approved!"
```

### Admin Rejection Flow

```
SuperAdmin Dashboard → Admin Requests Tab
    ↓
1. SuperAdmin sees pending admin requests
2. SuperAdmin clicks "Reject" button
   - Confirmation modal appears with rejection reason input
   - SuperAdmin can optionally enter rejection reason
3. System:
   - Updates AdminRequest: status = "rejected", rejectionReason
   - Deletes User record completely
   - User receives rejection (via UI message)
4. User can re-register later and request again
```

## Database Schema Updates

### User Model Fields (Added)

```javascript
{
  // Existing fields
  name: String,
  email: String,
  password: String,
  role: String, // "user" | "admin" | "superAdmin"

  // NEW FIELDS for approval workflow
  isApproved: Boolean,           // default: true for users, false for admin requests
  adminRequestStatus: String,    // "none" | "pending" | "approved" | "rejected"
  adminRequestDate: Date,        // when admin request was submitted

  createdAt: Date,
  updatedAt: Date
}
```

### AdminRequest Model (NEW)

```javascript
{
  user: ObjectId,                      // Reference to User
  name: String,                        // Snapshot of name at request time
  email: String,                       // Snapshot of email at request time
  status: String,                      // "pending" | "approved" | "rejected"
  rejectionReason: String,             // (nullable) reason for rejection
  approvedBy: ObjectId,                // Reference to SuperAdmin user who approved
  approvalDate: Date,                  // when request was approved
  createdAt: Date,
  updatedAt: Date
}
```

## API Endpoints

### 1. User Registration (Existing)

```
POST /api/users/register
Request Body:
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "Secure123!",
  "requestAdmin": false   // NEW: omit or false for regular user
}

Response (Regular User):
{
  "success": true,
  "message": "User registered successfully!",
  "data": {
    "_id": "...",
    "name": "John Doe",
    "email": "john@example.com",
    "role": "user",
    "isApproved": true,
    "isAdminRequest": false
  }
}

Response (Admin Request):
{
  "success": true,
  "message": "Admin request submitted. Your account will be created once approved by a super admin.",
  "data": {
    "_id": "...",
    "name": "Jane Doe",
    "email": "jane@example.com",
    "role": "user",
    "isApproved": false,
    "adminRequestStatus": "pending",
    "isAdminRequest": true
  }
}
```

### 2. Get Pending Admin Requests (SuperAdmin only)

```
GET /api/users/admin-requests/pending
Headers:
{
  "Authorization": "Bearer {token}"
}
Response:
{
  "success": true,
  "data": [
    {
      "_id": "req123",
      "user": "user456",
      "name": "Jane Doe",
      "email": "jane@example.com",
      "status": "pending",
      "createdAt": "2024-01-15T10:30:00Z"
    }
  ]
}
```

### 3. Approve Admin Request (SuperAdmin only)

```
POST /api/users/admin-requests/{requestId}/approve
Headers:
{
  "Authorization": "Bearer {token}"
}
Response:
{
  "success": true,
  "message": "Admin request approved successfully",
  "data": {
    "_id": "req123",
    "status": "approved",
    "approvalDate": "2024-01-15T11:00:00Z"
  }
}
```

### 4. Reject Admin Request (SuperAdmin only)

```
POST /api/users/admin-requests/{requestId}/reject
Headers:
{
  "Authorization": "Bearer {token}"
}
Request Body:
{
  "rejectionReason": "Need more event management experience"
}

Response:
{
  "success": true,
  "message": "Admin request rejected successfully",
  "data": {
    "_id": "req123",
    "status": "rejected",
    "rejectionReason": "Need more event management experience"
  }
}
```

## Frontend Components

### 1. Register Component (`src/components/Register.js`)

- New checkbox: "Request Admin Access to Create & Manage Events"
- Conditional help text based on checkbox state
- Different success messages for users vs admin requests
- State management: `requestAdmin` boolean

### 2. AdminRequests Component (`src/components/AdminRequests.js`)

- NEW: Displays pending admin requests
- Features:
  - List of pending requests with user details
  - "Approve" button (green)
  - "Reject" button (red)
  - Confirmation modals before action
  - Optional rejection reason input
  - Success/error alerts
  - Empty state when no pending requests

### 3. MyBookings Integration (`src/components/MyBookings.js`)

- NEW: "Admin Requests" tab (visible only to superAdmin)
- Tab switching between:
  - My Bookings (all roles)
  - My Events (admin only)
  - Admin Requests (superAdmin only)

## Security Considerations

### Current Implementation

- `requireSuperAdmin` middleware on admin management routes
- Routes protected from unauthorized access

### Production Recommendations

1. Implement proper JWT token verification in middleware
2. Decode JWT and extract user role claims
3. Verify user role in token matches database
4. Use HTTPS for all authentication routes
5. Implement rate limiting on auth endpoints
6. Log all admin approval/rejection actions
7. Consider email notifications for admins on approval
8. Implement admin request timeout (e.g., 30 days)

## Setup Instructions

### Initial SuperAdmin Creation

Currently requires manual database setup. Choose ONE method:

#### Method 1: MongoDB Compass (Recommended for Development)

```javascript
// Insert document into users collection:
{
  "name": "System Administrator",
  "email": "superadmin@eventix.local",
  "password": "hashedPasswordHere",  // Hash password before insertion
  "role": "superAdmin",
  "isApproved": true,
  "adminRequestStatus": "none",
  "createdAt": new Date(),
  "updatedAt": new Date()
}
```

#### Method 2: Database Seed Script (For Production)

Create `scripts/seed-superadmin.js`:

```javascript
const mongoose = require("mongoose");
const User = require("../src/models/User.model");
const bcrypt = require("bcrypt");

async function seedSuperAdmin() {
  try {
    const hashedPassword = await bcrypt.hash("SecurePassword123!", 10);
    const superAdmin = new User({
      name: "System Administrator",
      email: "superadmin@eventix.local",
      password: hashedPassword,
      role: "superAdmin",
      isApproved: true,
      adminRequestStatus: "none",
    });

    await superAdmin.save();
    console.log("✓ SuperAdmin created successfully");
  } catch (err) {
    console.error("Error creating SuperAdmin:", err);
  }
}
```

### Verification Checklist

- [ ] SuperAdmin account created in database
- [ ] SuperAdmin can login successfully
- [ ] SuperAdmin can see "Admin Requests" tab in dashboard
- [ ] Regular user registration works (without admin checkbox)
- [ ] Admin request registration works (with admin checkbox)
- [ ] SuperAdmin can approve pending requests
- [ ] Approved user receives admin role
- [ ] SuperAdmin can reject pending requests
- [ ] Rejected user account is deleted
- [ ] Rejected users can re-register

## Testing Scenarios

### Scenario 1: Regular User Registration

1. Visit registration page
2. Fill form without checking admin box
3. Submit
4. ✓ Account created immediately
5. ✓ Can login and book events

### Scenario 2: Admin Request Submission

1. Visit registration page
2. Fill form and check "Request Admin Access"
3. Submit
4. ✓ See success message about pending approval
5. ✓ Try to login → fails (isApproved: false)

### Scenario 3: SuperAdmin Approval

1. Login as superAdmin
2. Go to dashboard → "Admin Requests" tab
3. Click "Approve" on pending request
4. Confirm in modal
5. ✓ Request status changes to approved
6. ✓ User account activated (isApproved: true)
7. ✓ User role changed to "admin"
8. ✓ User can now login and create events

### Scenario 4: SuperAdmin Rejection

1. Login as superAdmin
2. Go to dashboard → "Admin Requests" tab
3. Click "Reject" on pending request
4. Enter optional rejection reason
5. Confirm in modal
6. ✓ Request status changes to rejected
7. ✓ User account deleted
8. ✓ User can re-register later

## Future Enhancements

1. **Email Notifications**
   - Email to admin when request submitted
   - Email to user when request approved/rejected

2. **Request Timeout**
   - Auto-reject requests after 30 days of no action

3. **Admin Request History**
   - View all approved/rejected requests
   - Filter and search capabilities

4. **Audit Logging**
   - Log all admin approval/rejection actions
   - Track who approved/rejected and when

5. **Admin-to-SuperAdmin Promotion**
   - Allow existing admins to request superAdmin role
   - Similar approval workflow

6. **Role Delegation**
   - SuperAdmin can temporarily delegate authority

## File Structure

```
eventix-backend/
  src/
    models/
      AdminRequest.model.js    (NEW)
      User.model.js            (UPDATED)
    controllers/
      user.controller.js       (UPDATED - added 3 new functions)
    routes/
      user.routes.js           (UPDATED - added 3 new routes)
    middlewares/
      auth.middleware.js       (UPDATED - added requireSuperAdmin)

eventix-frontend/
  src/
    components/
      Register.js              (UPDATED - added checkbox)
      AdminRequests.js         (NEW)
      MyBookings.js            (UPDATED - added tab)
    App.css                    (UPDATED - added styles)
```

## Troubleshooting

### SuperAdmin Can't See Admin Requests Tab

- Verify user role is exactly "superAdmin" in database
- Check localStorage token contains correct role
- Verify MyBookings component receives correct userId

### Admin Request Doesn't Show in Pending List

- Check AdminRequest document was created in database
- Verify request status is "pending"
- Check superAdmin has correct authorization token

### Approve/Reject Buttons Not Working

- Verify superAdmin middleware is applied to routes
- Check Authorization header format: "Bearer {token}"
- Look at browser console for API error messages
- Check backend logs for detailed errors

### User Can't Login After Approval

- Verify isApproved field is true in User document
- Check login logic validates isApproved field
- Verify adminRequestStatus was updated to "approved"

## Support & Maintenance

For issues or questions:

1. Check database documents for correct structure
2. Review backend logs for error messages
3. Verify API responses match expected format
4. Test with Postman before debugging frontend
5. Check browser console for frontend errors
