# Quick Testing Guide - Pass Options Display

## What Was Fixed?
Previously, the pass options (Daily Pass / Season Pass) only appeared when BOTH were enabled. Now they appear when at least ONE is enabled.

## Testing Steps

### 1. Start the Application

**Terminal 1 - Backend:**
```bash
cd eventix-backend
npm start
```

**Terminal 2 - Frontend:**
```bash
cd eventix-frontend
npm start
```

### 2. Create Test Events

#### Test Event 1: Daily Pass Only
1. Login as admin/superadmin
2. Click "Create Event"
3. Fill in basic details:
   - Name: "Daily Pass Test Event"
   - Description: "Testing daily pass only"
   - Event Duration: **Multi-Day**
   - Start Date: Tomorrow
   - End Date: 3 days from now
   - Total Seats: 50
4. **Pass Options:**
   - ✅ Check "Day Pass" → Set price: ₹500
   - ❌ Leave "Season Pass" unchecked
5. Complete payment and create event

#### Test Event 2: Season Pass Only
1. Create another event
2. Fill in basic details (similar to above)
3. **Pass Options:**
   - ❌ Leave "Day Pass" unchecked
   - ✅ Check "Season Pass" → Set price: ₹1200
4. Complete payment and create event

#### Test Event 3: Both Passes
1. Create another event
2. Fill in basic details
3. **Pass Options:**
   - ✅ Check "Day Pass" → Set price: ₹500
   - ✅ Check "Season Pass" → Set price: ₹1200
4. Complete payment and create event

### 3. Test Booking Flow

#### For Daily Pass Only Event:
1. Open the event from home page
2. **Expected:** You should see:
   ```
   Day Pass
   ┌─────────────────────┐
   │  🎟️ Day Pass       │
   │  ₹500              │
   │  Attend one day    │
   └─────────────────────┘
   ```
3. **Expected:** Day selector calendar appears below
4. Select a day
5. Select number of tickets
6. Click "Book Tickets"
7. **Expected:** Confirmation shows "Day Pass — [selected date]"
8. **Expected:** Payment shows correct daily pass price

#### For Season Pass Only Event:
1. Open the event from home page
2. **Expected:** You should see:
   ```
   Season Pass
   ┌─────────────────────┐
   │  🌟 Season Pass    │
   │  ₹1200             │
   │  All 3 days        │
   └─────────────────────┘
   ```
3. **Expected:** Season pass coverage list appears below
4. Select number of passes
5. Click "Book Tickets"
6. **Expected:** Confirmation shows "Season Pass (all days)"
7. **Expected:** Payment shows correct season pass price

#### For Both Passes Event:
1. Open the event from home page
2. **Expected:** You should see:
   ```
   Select Pass Type
   ┌──────────────┐  ┌──────────────┐
   │ 🎟️ Day Pass │  │ 🌟 Season   │
   │ ₹500        │  │ ₹1200       │
   │ Attend one  │  │ All 3 days  │
   └──────────────┘  └──────────────┘
   ```
3. Click on "Day Pass" → Day selector appears
4. Click on "Season Pass" → Season coverage appears
5. Test booking with each option

### 4. Verify Backend API

Run the test script:
```bash
# Get your user ID from MongoDB or browser localStorage
export USER_ID="your-user-id-here"

# Run test
./test-pass-options.sh
```

**Expected Output:**
```
==========================================
Pass Options Display Test
==========================================

Test 1: Fetching multi-day events...
✅ Found 3 multi-day events

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Event: Daily Pass Test Event
ID: 67abc123...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Pass Options:
  ✅ Daily Pass: ₹500
  ❌ Season Pass: Disabled

Daily Seats:
  2026-03-07: 50/50 available
  2026-03-08: 50/50 available
  2026-03-09: 50/50 available

Testing Daily Pass Lock...
  ✅ Daily pass lock successful
  ✅ Lock cancelled
```

## Common Issues & Solutions

### Issue 1: Pass options not showing
**Symptom:** Booking page shows no pass options

**Check:**
1. Is the event multi-day? (`eventType: "multi-day"`)
2. Is at least one pass enabled in database?
3. Check browser console for errors

**Fix:**
```javascript
// In MongoDB, verify:
db.events.findOne({ _id: ObjectId("event-id") })
// Should have:
{
  eventType: "multi-day",
  passOptions: {
    dailyPass: { enabled: true, price: 500 },
    // OR
    seasonPass: { enabled: true, price: 1200 }
  }
}
```

### Issue 2: Both passes showing when only one enabled
**Symptom:** UI shows both pass buttons even when only one is enabled

**Fix:** Clear browser cache and reload:
```bash
# In browser DevTools Console:
localStorage.clear()
location.reload()
```

### Issue 3: Wrong price in payment
**Symptom:** Payment shows incorrect amount

**Check:**
1. Verify pass prices in event creation
2. Check browser console for state values
3. Verify backend `computeBookingAmount()` function

## Success Indicators

✅ **Daily Pass Only:**
- Single pass button displayed full-width
- Label shows "Day Pass"
- Day selector appears
- Correct price in confirmation and payment

✅ **Season Pass Only:**
- Single pass button displayed full-width
- Label shows "Season Pass"
- Season coverage list appears
- Correct price in confirmation and payment

✅ **Both Passes:**
- Two pass buttons side-by-side
- Label shows "Select Pass Type"
- Can toggle between both
- Correct price based on selection

## Rollback (If Needed)

If you encounter critical issues:

```bash
cd /home/hello/Documents/Eventix

# Revert all changes
git revert HEAD~3..HEAD

# Or revert specific commit
git log --oneline -5
git revert <commit-hash>

# Push changes
git push origin master
```

## Support

If you encounter issues:
1. Check browser console for errors
2. Check backend logs for API errors
3. Run `./test-pass-options.sh` to verify backend
4. Verify event data in MongoDB

## Next Steps After Testing

Once verified:
1. Push changes to GitHub
2. Deploy to production
3. Update user documentation
4. Monitor for any issues

```bash
# Push to GitHub
git push origin master

# Push submodules
cd eventix-frontend
git push origin main
cd ..
```
