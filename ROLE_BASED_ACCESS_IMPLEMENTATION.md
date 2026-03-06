# Role-Based Access Control (Admin/User) - Implementation Summary

## Overview
Added role-based access control to distinguish between Admin and User accounts:
- **Admin**: Can create and manage events
- **User**: Can only book events

---

## Changes Made

### 1. Frontend - Register Component (`eventix-frontend/src/components/Register.js`)
**Added:**
- Role selection dropdown in registration form
- State variable `role` (default: 'user')
- Role field sent to backend during registration

**UI Changes:**
- New dropdown: "Account Type" with options:
  - User (Book Events)
  - Admin (Create & Manage Events)

---

### 2. Frontend - App Component (`eventix-frontend/src/App.js`)
**Added:**
- Conditional rendering of "Create Event" button (only for admins)
- Display "(Admin)" badge next to admin username in navbar
- Route protection: Non-admins redirected to home if they try to access `/create`

**Changes:**
```javascript
// Show admin badge
<span className="user-info">{user.name} {user.role === 'admin' && '(Admin)'}</span>

// Hide Create Event button for users
{user.role === 'admin' && (
  <button onClick={() => navigate('/create')}>Create Event</button>
)}

// Protect route
<Route 
  path="/create" 
  element={
    user.role === 'admin' 
      ? <CreateEvent userId={user._id} /> 
      : <Navigate to="/" replace />
  } 
/>
```

---

### 3. Frontend - CreateEvent Component (`eventix-frontend/src/components/CreateEvent.js`)
**Added:**
- Sends `userRole` field to backend when creating event
- Retrieves role from localStorage

---

### 4. Backend - Auth Middleware (`eventix-backend/src/middlewares/auth.middleware.js`)
**Created new file:**
- `requireAdmin` middleware function
- Checks if `userRole` in request body is 'admin'
- Returns 403 Forbidden if not admin

---

### 5. Backend - Event Routes (`eventix-backend/src/routes/event.routes.js`)
**Added:**
- Import auth middleware
- Applied `requireAdmin` middleware to POST `/api/events` route

**Change:**
```javascript
router.post("/", requireAdmin, createEvent);
```

---

### 6. Backend - User Model (`eventix-backend/src/models/User.model.js`)
**No changes needed** - Already had role field:
```javascript
role: {
  type: String,
  enum: ["user", "admin"],
  default: "user"
}
```

---

### 7. Backend - User Controller (`eventix-backend/src/controllers/user.controller.js`)
**No changes needed** - Already supports role in:
- Registration (returns role in response)
- Login (returns role in response)

---

## How It Works

### Registration Flow:
1. User selects "Admin" or "User" during registration
2. Role is saved in database
3. Role is returned in login response
4. Role is stored in localStorage

### Access Control:
1. **Frontend**: 
   - Hides "Create Event" button for users
   - Redirects users away from `/create` route
   
2. **Backend**: 
   - Validates role before allowing event creation
   - Returns 403 error if non-admin tries to create event

---

## Testing

### Test as User:
1. Register with "User (Book Events)" option
2. Login
3. Verify "Create Event" button is NOT visible
4. Try accessing `/create` directly → Should redirect to home
5. Can book events normally

### Test as Admin:
1. Register with "Admin (Create & Manage Events)" option
2. Login
3. Verify "Create Event" button IS visible
4. Verify "(Admin)" badge shows next to name
5. Can create events
6. Can also book events

---

## Security Notes

⚠️ **Current Implementation:**
- Role is sent in request body (simple approach)
- No JWT tokens or session management
- Suitable for learning/demo projects

🔒 **For Production:**
- Implement JWT authentication
- Store role in encrypted token
- Validate token on every protected route
- Add password hashing (bcrypt)
- Add rate limiting
- Add CSRF protection

---

## API Changes

### POST /api/events (Create Event)
**Before:**
```json
{
  "name": "Concert",
  "totalSeats": 100,
  "userId": "123"
}
```

**After:**
```json
{
  "name": "Concert",
  "totalSeats": 100,
  "userId": "123",
  "userRole": "admin"  // NEW FIELD
}
```

**Response if not admin:**
```json
{
  "success": false,
  "message": "Access denied. Admin privileges required to create events."
}
```

---

## Files Modified

### Frontend:
1. `eventix-frontend/src/components/Register.js`
2. `eventix-frontend/src/components/App.js`
3. `eventix-frontend/src/components/CreateEvent.js`

### Backend:
1. `eventix-backend/src/middlewares/auth.middleware.js` (NEW)
2. `eventix-backend/src/routes/event.routes.js`

### No Changes Needed:
- Login component (already handles role)
- User model (already has role field)
- User controller (already supports role)

---

## Quick Test Commands

```bash
# Start backend
cd eventix-backend
npm start

# Start frontend (new terminal)
cd eventix-frontend
npm start
```

1. Register as Admin
2. Create an event
3. Logout
4. Register as User
5. Try to access create event (should be hidden/blocked)
6. Book the event created by admin

---

## Summary

✅ Users can only book events
✅ Admins can create and book events
✅ Frontend hides admin features from users
✅ Backend validates admin role before event creation
✅ Role is displayed in navbar
✅ No breaking changes to existing functionality
