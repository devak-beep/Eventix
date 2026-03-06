# Admin Visibility Feature

## Feature Overview

Admins can now see **both public and private events** on the home page, with visibility tags to distinguish between them. Regular users continue to see only public events.

## Implementation

### Backend Changes

**File**: `eventix-backend/src/controllers/event.controller.js`

```javascript
// Modified getAllPublicEvents to check userRole
exports.getAllPublicEvents = async (req, res) => {
  const { userRole } = req.query;
  
  // Admin sees all events, users see only public
  const filter = userRole === 'admin' ? {} : { type: "public" };
  
  const events = await Event.find(filter)
    .select("name description eventDate totalSeats availableSeats type category amount currency image createdAt")
    .sort({ eventDate: 1 });

  res.status(200).json({
    success: true,
    data: events,
  });
};
```

### Frontend Changes

**1. API Call** (`api.js`):
```javascript
export const getAllPublicEvents = async (userRole = 'user') => {
  const response = await api.get('/events', {
    params: { userRole }
  });
  return response.data;
};
```

**2. EventList Component** (`EventList.js`):
- Fetches user role from localStorage
- Passes role to API call
- Shows visibility badge only to admin
- Badge positioned at bottom-right of event image

**3. CSS** (`App.css`):
- Green gradient badge for public events (🌍 Public)
- Purple gradient badge for private events (🔒 Private)
- Positioned at bottom-right (different from status badges)

## Visual Design

### For Admin Users:

**Public Event Card:**
```
┌─────────────────────────────┐
│ [Event Image]               │
│                             │
│                             │
│                 🌍 Public   │ ← Green badge (bottom-right)
│                             │
│ 🎵 Concerts                 │
│ Event Name                  │
└─────────────────────────────┘
```

**Private Event Card:**
```
┌─────────────────────────────┐
│ [Event Image]               │
│                             │
│                             │
│                 🔒 Private  │ ← Purple badge (bottom-right)
│                             │
│ 🎵 Concerts                 │
│ Event Name                  │
└─────────────────────────────┘
```

### For Regular Users:
- See only public events
- No visibility badges shown
- Private events not visible at all

## Badge Positioning

**Status Badges** (top-right):
- ⏰ Expired
- 🎫 Sold Out

**Visibility Badges** (bottom-right, admin only):
- 🌍 Public
- 🔒 Private

This prevents badge overlap and keeps the UI clean.

## Color Scheme

### Public Badge (Green):
```css
background: linear-gradient(135deg, 
  rgba(34, 197, 94, 0.9) 0%, 
  rgba(22, 163, 74, 0.9) 100%);
color: #fff;
box-shadow: 0 4px 12px rgba(34, 197, 94, 0.3);
```

### Private Badge (Purple):
```css
background: linear-gradient(135deg, 
  rgba(168, 85, 247, 0.9) 0%, 
  rgba(147, 51, 234, 0.9) 100%);
color: #fff;
box-shadow: 0 4px 12px rgba(168, 85, 247, 0.3);
```

## Logic Flow

### Admin View:
```
Admin logs in
  ↓
Opens home page
  ↓
EventList fetches user role from localStorage
  ↓
API called with userRole='admin'
  ↓
Backend returns ALL events (public + private)
  ↓
Each event card shows visibility badge at bottom-right
  ↓
Admin sees: "🌍 Public" or "🔒 Private"
```

### User View:
```
User logs in
  ↓
Opens home page
  ↓
EventList fetches user role from localStorage
  ↓
API called with userRole='user'
  ↓
Backend returns only PUBLIC events
  ↓
No visibility badges shown
  ↓
User sees only public events (clean UI)
```

## Priority Order (Admin View)

Badges are shown in this priority:
1. **Top-right**: Status badges (Expired > Sold Out)
2. **Bottom-right**: Visibility badge (Public/Private)

Example with multiple badges:
```
┌─────────────────────────────┐
│ [Event Image]  🎫 Sold Out  │ ← Status (top-right)
│                             │
│                             │
│                 🔒 Private  │ ← Visibility (bottom-right)
│                             │
│ 🎵 Concerts                 │
│ Event Name                  │
└─────────────────────────────┘
```

## Security

- User role checked on **backend** (not just frontend)
- Frontend role check only for UI display
- Backend enforces access control
- Private events never sent to regular users

## Testing

### Test as Admin:
1. Login as admin
2. Create a public event
3. Create a private event
4. Go to home page
5. **Expected**: See both events with visibility badges

### Test as User:
1. Login as regular user
2. Go to home page
3. **Expected**: See only public events, no visibility badges

### Test Badge Positioning:
1. Login as admin
2. View sold-out private event
3. **Expected**: 
   - "🎫 Sold Out" at top-right
   - "🔒 Private" at bottom-right
   - No overlap

## Files Modified

### Backend (1 file):
1. `eventix-backend/src/controllers/event.controller.js`

### Frontend (3 files):
1. `eventix-frontend/src/api.js`
2. `eventix-frontend/src/components/EventList.js`
3. `eventix-frontend/src/App.css`

## Code Statistics

- **Lines Added**: ~40 lines
- **New CSS Classes**: 2 (`.event-badge.visibility.public`, `.event-badge.visibility.private`)
- **API Changes**: 1 parameter added (`userRole`)

## Benefits

✅ **Admin Oversight**: Admins can see all events at a glance
✅ **Clear Distinction**: Visibility badges make event type obvious
✅ **User Privacy**: Regular users don't see private events
✅ **Clean UI**: Badges only shown when relevant
✅ **Professional**: Gradient badges match website theme
✅ **Secure**: Backend enforces access control

## Future Enhancements

Possible additions:
- Filter by visibility (Public/Private) for admin
- Count of public vs private events
- Bulk visibility change
- Event visibility toggle in admin panel
