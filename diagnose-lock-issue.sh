#!/bin/bash

echo "=== Multi-Day Event Lock Diagnostic ==="
echo ""

# Check if backend is running
echo "1. Checking if backend server is running..."
if pgrep -f "node.*server" > /dev/null; then
    echo "✅ Backend server is running"
else
    echo "❌ Backend server is NOT running"
    echo "   Start it with: cd eventix-backend && npm start"
    exit 1
fi

# Check MongoDB connection
echo ""
echo "2. Checking MongoDB connection..."
if pgrep -f mongod > /dev/null; then
    echo "✅ MongoDB is running"
else
    echo "⚠️  MongoDB might not be running"
fi

# Test API endpoint
echo ""
echo "3. Testing API health..."
HEALTH=$(curl -s http://localhost:3000/api/events 2>&1)
if echo "$HEALTH" | grep -q "success"; then
    echo "✅ API is responding"
else
    echo "❌ API is not responding"
    echo "Response: $HEALTH"
fi

echo ""
echo "=== Common Issues & Solutions ==="
echo ""
echo "Issue: 'Seat lock failed — please try again'"
echo ""
echo "Possible causes:"
echo "1. Backend server not restarted after code changes"
echo "   Solution: cd eventix-backend && npm start"
echo ""
echo "2. Event not published (isPublished = false)"
echo "   Solution: Check event in database"
echo ""
echo "3. Pass options not properly configured"
echo "   Solution: Verify passOptions.dailyPass.enabled or seasonPass.enabled is true"
echo ""
echo "4. Selected date outside event range"
echo "   Solution: Ensure selectedDate is between eventDate and endDate"
echo ""
echo "To see actual error, check:"
echo "- Browser DevTools → Network tab → Look for /lock request"
echo "- Backend console logs"
echo "- MongoDB logs"
