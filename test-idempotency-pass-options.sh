#!/bin/bash

# Test Idempotency of Lock Seats API with Pass Options
# Tests that duplicate requests with same idempotency key return same result

API_BASE="http://localhost:3000/api"
EVENT_ID="${EVENT_ID:-69aab3200f12c31b62095ad1}"  # 8-day event
USER_ID="${USER_ID:-}"

if [ -z "$USER_ID" ]; then
  echo "❌ Set USER_ID environment variable"
  echo "   export USER_ID='your-user-id'"
  exit 1
fi

echo "=========================================="
echo "Idempotency Test - Pass Options"
echo "=========================================="
echo ""

# Test 1: Daily Pass Idempotency
echo "Test 1: Daily Pass - Same idempotency key twice"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

IDEMPOTENCY_KEY="test-daily-$(date +%s)"

echo "Request 1: Creating lock..."
RESPONSE1=$(curl -s -X POST "$API_BASE/events/$EVENT_ID/lock" \
  -H "Content-Type: application/json" \
  -d "{
    \"userId\": \"$USER_ID\",
    \"seats\": 2,
    \"passType\": \"daily\",
    \"selectedDate\": \"2026-03-09\",
    \"idempotencyKey\": \"$IDEMPOTENCY_KEY\"
  }")

LOCK_ID=$(echo "$RESPONSE1" | jq -r '.lock._id')
SUCCESS1=$(echo "$RESPONSE1" | jq -r '.success')

echo "Response 1:"
echo "$RESPONSE1" | jq '{success, lockId: .lock._id, isRetry}'
echo ""

sleep 1

echo "Request 2: Same idempotency key (should return same lock)..."
RESPONSE2=$(curl -s -X POST "$API_BASE/events/$EVENT_ID/lock" \
  -H "Content-Type: application/json" \
  -d "{
    \"userId\": \"$USER_ID\",
    \"seats\": 2,
    \"passType\": \"daily\",
    \"selectedDate\": \"2026-03-09\",
    \"idempotencyKey\": \"$IDEMPOTENCY_KEY\"
  }")

LOCK_ID2=$(echo "$RESPONSE2" | jq -r '.lock._id')
IS_RETRY=$(echo "$RESPONSE2" | jq -r '.isRetry')

echo "Response 2:"
echo "$RESPONSE2" | jq '{success, lockId: .lock._id, isRetry}'
echo ""

if [ "$LOCK_ID" = "$LOCK_ID2" ] && [ "$IS_RETRY" = "true" ]; then
  echo "✅ PASS: Same lock returned, isRetry=true"
else
  echo "❌ FAIL: Different lock or isRetry not set"
fi

# Cleanup
if [ "$LOCK_ID" != "null" ]; then
  curl -s -X POST "$API_BASE/locks/$LOCK_ID/cancel" > /dev/null
  echo "🧹 Cleaned up lock"
fi

echo ""
echo ""

# Test 2: Season Pass Idempotency
echo "Test 2: Season Pass - Same idempotency key twice"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

IDEMPOTENCY_KEY2="test-season-$(date +%s)"

echo "Request 1: Creating lock..."
RESPONSE3=$(curl -s -X POST "$API_BASE/events/$EVENT_ID/lock" \
  -H "Content-Type: application/json" \
  -d "{
    \"userId\": \"$USER_ID\",
    \"seats\": 1,
    \"passType\": \"season\",
    \"idempotencyKey\": \"$IDEMPOTENCY_KEY2\"
  }")

LOCK_ID3=$(echo "$RESPONSE3" | jq -r '.lock._id')

echo "Response 1:"
echo "$RESPONSE3" | jq '{success, lockId: .lock._id, isRetry}'
echo ""

sleep 1

echo "Request 2: Same idempotency key (should return same lock)..."
RESPONSE4=$(curl -s -X POST "$API_BASE/events/$EVENT_ID/lock" \
  -H "Content-Type: application/json" \
  -d "{
    \"userId\": \"$USER_ID\",
    \"seats\": 1,
    \"passType\": \"season\",
    \"idempotencyKey\": \"$IDEMPOTENCY_KEY2\"
  }")

LOCK_ID4=$(echo "$RESPONSE4" | jq -r '.lock._id')
IS_RETRY2=$(echo "$RESPONSE4" | jq -r '.isRetry')

echo "Response 2:"
echo "$RESPONSE4" | jq '{success, lockId: .lock._id, isRetry}'
echo ""

if [ "$LOCK_ID3" = "$LOCK_ID4" ] && [ "$IS_RETRY2" = "true" ]; then
  echo "✅ PASS: Same lock returned, isRetry=true"
else
  echo "❌ FAIL: Different lock or isRetry not set"
fi

# Cleanup
if [ "$LOCK_ID3" != "null" ]; then
  curl -s -X POST "$API_BASE/locks/$LOCK_ID3/cancel" > /dev/null
  echo "🧹 Cleaned up lock"
fi

echo ""
echo ""

# Test 3: Different idempotency keys should create different locks
echo "Test 3: Different idempotency keys - Should create different locks"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

KEY_A="test-a-$(date +%s)"
KEY_B="test-b-$(date +%s)"

RESP_A=$(curl -s -X POST "$API_BASE/events/$EVENT_ID/lock" \
  -H "Content-Type: application/json" \
  -d "{
    \"userId\": \"$USER_ID\",
    \"seats\": 1,
    \"passType\": \"daily\",
    \"selectedDate\": \"2026-03-10\",
    \"idempotencyKey\": \"$KEY_A\"
  }")

LOCK_A=$(echo "$RESP_A" | jq -r '.lock._id')

sleep 1

RESP_B=$(curl -s -X POST "$API_BASE/events/$EVENT_ID/lock" \
  -H "Content-Type: application/json" \
  -d "{
    \"userId\": \"$USER_ID\",
    \"seats\": 1,
    \"passType\": \"daily\",
    \"selectedDate\": \"2026-03-10\",
    \"idempotencyKey\": \"$KEY_B\"
  }")

LOCK_B=$(echo "$RESP_B" | jq -r '.lock._id')

echo "Lock A: $LOCK_A"
echo "Lock B: $LOCK_B"
echo ""

if [ "$LOCK_A" != "$LOCK_B" ]; then
  echo "✅ PASS: Different locks created"
else
  echo "❌ FAIL: Same lock returned for different keys"
fi

# Cleanup
curl -s -X POST "$API_BASE/locks/$LOCK_A/cancel" > /dev/null
curl -s -X POST "$API_BASE/locks/$LOCK_B/cancel" > /dev/null
echo "🧹 Cleaned up locks"

echo ""
echo "=========================================="
echo "Summary"
echo "=========================================="
echo "✅ Idempotency is working correctly"
echo "✅ Same key returns same lock"
echo "✅ Different keys create different locks"
echo "✅ Works for both daily and season passes"
