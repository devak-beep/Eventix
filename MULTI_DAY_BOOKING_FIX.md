# Multi-Day Event Booking Fix

## Issue Summary
Multi-day events were created successfully but failed during booking with the following problems:
1. **Error during booking** - Lock controller was checking wrong field
2. **Pass options not showing** - Frontend wasn't receiving multi-day event data
3. **Daily/Season pass selection missing** - Event data incomplete

## Root Causes Identified

### 1. Event Status Field Mismatch
**File:** `eventix-backend/src/controllers/lock.controller.js` (Line 66)

**Problem:**
```javascript
if (event.status !== "published") {
```

**Issue:** Event model uses `isPublished` (boolean), not `status` (string)

**Fix:**
```javascript
if (!event.isPublished) {
```

### 2. Missing Multi-Day Fields in API Response
**File:** `eventix-backend/src/controllers/event.controller.js`

**Problem:** Both `getEventById` and `getAllPublicEvents` used `.select()` which explicitly excluded:
- `eventType` (single-day vs multi-day)
- `endDate` (end date for multi-day events)
- `passOptions` (daily/season pass configuration)
- `dailySeats` (per-day seat availability)

**Fix:** Removed `.select()` calls to return all event fields

### 3. Mongoose Map Not Serializing to JSON
**File:** `eventix-backend/src/models/Event.model.js`

**Problem:** `dailySeats` is stored as a Mongoose Map, which doesn't automatically convert to plain object in JSON responses

**Fix:** Added `toJSON` transform to schema:
```javascript
toJSON: {
  transform: function (doc, ret) {
    if (ret.dailySeats instanceof Map) {
      ret.dailySeats = Object.fromEntries(ret.dailySeats);
    }
    return ret;
  },
}
```

## Files Modified

1. **eventix-backend/src/controllers/lock.controller.js**
   - Fixed event status check (line 66)

2. **eventix-backend/src/controllers/event.controller.js**
   - Removed `.select()` from `getEventById` (line 474-479)
   - Removed `.select()` from `getAllPublicEvents` (line 170-176)

3. **eventix-backend/src/models/Event.model.js**
   - Added `toJSON` transform to convert Map to plain object (line 234-244)

## Testing Steps

### 1. Create a Multi-Day Event
```bash
# Frontend: Create Event page
- Select "Multi-Day Event"
- Set start and end dates
- Enable Daily Pass and/or Season Pass
- Set prices for each pass type
- Complete payment
```

### 2. Verify Event Data
```bash
# Check event details API
curl http://localhost:3000/api/events/{eventId}

# Should return:
{
  "success": true,
  "data": {
    "eventType": "multi-day",
    "eventDate": "2026-03-10T00:00:00.000Z",
    "endDate": "2026-03-12T00:00:00.000Z",
    "passOptions": {
      "dailyPass": { "enabled": true, "price": 500 },
      "seasonPass": { "enabled": true, "price": 1200 }
    },
    "dailySeats": {
      "2026-03-10": { "total": 100, "available": 100 },
      "2026-03-11": { "total": 100, "available": 100 },
      "2026-03-12": { "total": 100, "available": 100 }
    },
    "isPublished": true,
    ...
  }
}
```

### 3. Test Booking Flow
```bash
# Frontend: Event Details → Book Tickets
1. Should show pass type selector (Daily Pass / Season Pass)
2. If Daily Pass selected: Show day picker with availability
3. If Season Pass selected: Show all days coverage
4. Select seats and proceed to lock
5. Should successfully lock seats without errors
```

### 4. Test Lock API Directly
```bash
# Daily Pass Lock
curl -X POST http://localhost:3000/api/events/{eventId}/lock \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "{userId}",
    "seats": 2,
    "passType": "daily",
    "selectedDate": "2026-03-10",
    "idempotencyKey": "test-daily-123"
  }'

# Season Pass Lock
curl -X POST http://localhost:3000/api/events/{eventId}/lock \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "{userId}",
    "seats": 1,
    "passType": "season",
    "idempotencyKey": "test-season-456"
  }'
```

## Expected Behavior After Fix

### Single-Day Events (Unchanged)
- Works as before
- Shows single ticket price
- Books for one date only

### Multi-Day Events (Now Working)

#### Daily Pass Only
- User sees only "Day Pass" option
- Selects specific day from calendar
- Pays daily pass price
- Seats deducted only for selected day

#### Season Pass Only
- User sees only "Season Pass" option
- Gets access to all days
- Pays season pass price
- Seats deducted from all days

#### Both Options Available
- User chooses between Daily or Season
- UI shows price comparison
- Season pass disabled if any day is sold out
- Appropriate seat deduction based on selection

## Validation Checks

### Backend Validations (Already Implemented)
✅ At least one pass option must be enabled
✅ Daily pass requires selectedDate
✅ Season pass checks all days have availability
✅ Date must be within event date range
✅ Idempotency prevents duplicate locks

### Frontend Validations (Already Implemented)
✅ At least one pass option during creation
✅ End date must be after start date
✅ Daily pass requires day selection
✅ Season pass shows sold-out status
✅ Seat count cannot exceed availability

## API Endpoints Summary

### Event Creation
- `POST /api/razorpay/create-event-order` - Create payment order
- `POST /api/razorpay/verify-event-payment` - Verify payment & create event

### Event Retrieval
- `GET /api/events` - List all events (now includes multi-day fields)
- `GET /api/events/:id` - Get event details (now includes multi-day fields)

### Booking Flow
- `POST /api/events/:eventId/lock` - Lock seats (supports passType: regular/daily/season)
- `POST /api/locks/:id/cancel` - Cancel lock and restore seats
- `POST /api/bookings/confirm` - Confirm booking after lock

## Database Schema

### Event Model Fields (Multi-Day)
```javascript
{
  eventType: "single-day" | "multi-day",
  eventDate: Date,              // Start date
  endDate: Date,                // End date (multi-day only)
  passOptions: {
    dailyPass: {
      enabled: Boolean,
      price: Number
    },
    seasonPass: {
      enabled: Boolean,
      price: Number
    }
  },
  dailySeats: Map<String, {     // "YYYY-MM-DD" -> seat info
    total: Number,
    available: Number
  }>,
  isPublished: Boolean          // Must be true for booking
}
```

### SeatLock Model Fields
```javascript
{
  userId: ObjectId,
  eventId: ObjectId,
  seats: Number,
  passType: "regular" | "daily" | "season",
  selectedDate: Date,           // For daily pass only
  status: "ACTIVE" | "CANCELLED" | "CONFIRMED",
  expiresAt: Date              // 10 minutes TTL
}
```

## Rollback Plan (If Needed)

If issues arise, revert these commits:
```bash
cd eventix-backend
git log --oneline -5  # Find commit hashes
git revert <commit-hash>
```

Or manually revert changes:
1. Restore `.select()` in event.controller.js
2. Change `isPublished` back to `status !== "published"`
3. Remove toJSON transform from Event model

## Future Enhancements

1. **Variable Pricing Per Day**
   - Allow different daily pass prices for different days
   - Weekend vs weekday pricing

2. **Partial Season Pass**
   - Allow booking multiple consecutive days at discount
   - "3-day pass" option

3. **Group Discounts**
   - Bulk booking discounts for season passes
   - Early bird pricing

4. **Seat Categories**
   - VIP, Regular, Economy seats
   - Different pricing tiers per day

## Conclusion

All three critical bugs have been fixed:
1. ✅ Event status check now uses correct field
2. ✅ Multi-day fields now included in API responses
3. ✅ Mongoose Map properly serialized to JSON

The multi-day event booking feature should now work end-to-end.
