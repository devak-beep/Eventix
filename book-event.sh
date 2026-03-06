#!/bin/bash

API_URL="http://localhost:3000/api"
USER_ID="6985816d45b132b509bd2fd6"
EVENT_ID="6992f3897b165388bbc1c819"
SEATS=1

echo "=== Booking Event: Toxic ==="
echo ""

# Step 1: Lock seats
echo "Step 1: Locking $SEATS seat(s)..."
LOCK_RESPONSE=$(curl -s -X POST "$API_URL/locks" \
  -H "Content-Type: application/json" \
  -d "{
    \"eventId\": \"$EVENT_ID\",
    \"userId\": \"$USER_ID\",
    \"seats\": $SEATS,
    \"idempotencyKey\": \"$(uuidgen)\"
  }")

echo "$LOCK_RESPONSE" | jq '.'
LOCK_ID=$(echo "$LOCK_RESPONSE" | jq -r '.data._id')

if [ "$LOCK_ID" == "null" ] || [ -z "$LOCK_ID" ]; then
  echo "❌ Failed to lock seats"
  exit 1
fi

echo "✅ Seats locked. Lock ID: $LOCK_ID"
echo ""

# Step 2: Confirm booking
echo "Step 2: Confirming booking..."
BOOKING_RESPONSE=$(curl -s -X POST "$API_URL/bookings/confirm" \
  -H "Content-Type: application/json" \
  -d "{\"lockId\": \"$LOCK_ID\"}")

echo "$BOOKING_RESPONSE" | jq '.'
BOOKING_ID=$(echo "$BOOKING_RESPONSE" | jq -r '.booking._id')

if [ "$BOOKING_ID" == "null" ] || [ -z "$BOOKING_ID" ]; then
  echo "❌ Failed to confirm booking"
  exit 1
fi

echo "✅ Booking confirmed. Booking ID: $BOOKING_ID"
echo ""

# Step 3: Process payment
echo "Step 3: Processing payment..."
PAYMENT_RESPONSE=$(curl -s -X POST "$API_URL/payments/$BOOKING_ID/process" \
  -H "Content-Type: application/json" \
  -d "{
    \"status\": \"SUCCESS\",
    \"idempotencyKey\": \"$(uuidgen)\"
  }")

echo "$PAYMENT_RESPONSE" | jq '.'

if echo "$PAYMENT_RESPONSE" | jq -e '.success' > /dev/null; then
  echo ""
  echo "🎉 Booking completed successfully!"
  echo "Booking ID: $BOOKING_ID"
else
  echo "❌ Payment failed"
  exit 1
fi
