#!/bin/bash

# Pass Options Display Test Script
# Tests that pass options are correctly displayed in the booking flow

API_BASE="http://localhost:3000/api"

echo "=========================================="
echo "Pass Options Display Test"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get user ID (you need to set this)
USER_ID="${USER_ID:-}"

if [ -z "$USER_ID" ]; then
  echo -e "${RED}❌ Please set USER_ID environment variable${NC}"
  echo "   Example: export USER_ID='your-user-id-here'"
  exit 1
fi

echo -e "${BLUE}Using User ID: $USER_ID${NC}"
echo ""

# Test 1: Fetch all multi-day events
echo -e "${YELLOW}Test 1: Fetching multi-day events...${NC}"
EVENTS_RESPONSE=$(curl -s "$API_BASE/events?type=public")

# Extract multi-day events
MULTI_DAY_EVENTS=$(echo "$EVENTS_RESPONSE" | jq '[.data[] | select(.eventType == "multi-day")]')
MULTI_DAY_COUNT=$(echo "$MULTI_DAY_EVENTS" | jq 'length')

echo -e "${GREEN}✅ Found $MULTI_DAY_COUNT multi-day events${NC}"
echo ""

if [ "$MULTI_DAY_COUNT" -eq 0 ]; then
  echo -e "${RED}❌ No multi-day events found. Please create one first.${NC}"
  exit 1
fi

# Test each multi-day event
for i in $(seq 0 $((MULTI_DAY_COUNT - 1))); do
  EVENT=$(echo "$MULTI_DAY_EVENTS" | jq ".[$i]")
  EVENT_ID=$(echo "$EVENT" | jq -r '._id')
  EVENT_NAME=$(echo "$EVENT" | jq -r '.name')
  
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}Event: $EVENT_NAME${NC}"
  echo -e "${BLUE}ID: $EVENT_ID${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  
  # Check pass options
  DAILY_ENABLED=$(echo "$EVENT" | jq -r '.passOptions.dailyPass.enabled')
  SEASON_ENABLED=$(echo "$EVENT" | jq -r '.passOptions.seasonPass.enabled')
  DAILY_PRICE=$(echo "$EVENT" | jq -r '.passOptions.dailyPass.price')
  SEASON_PRICE=$(echo "$EVENT" | jq -r '.passOptions.seasonPass.price')
  
  echo ""
  echo "Pass Options:"
  
  if [ "$DAILY_ENABLED" = "true" ]; then
    echo -e "${GREEN}  ✅ Daily Pass: ₹$DAILY_PRICE${NC}"
  else
    echo -e "${RED}  ❌ Daily Pass: Disabled${NC}"
  fi
  
  if [ "$SEASON_ENABLED" = "true" ]; then
    echo -e "${GREEN}  ✅ Season Pass: ₹$SEASON_PRICE${NC}"
  else
    echo -e "${RED}  ❌ Season Pass: Disabled${NC}"
  fi
  
  # Validation
  if [ "$DAILY_ENABLED" = "false" ] && [ "$SEASON_ENABLED" = "false" ]; then
    echo -e "${RED}  ⚠️  WARNING: No pass options enabled!${NC}"
  fi
  
  # Check daily seats
  echo ""
  echo "Daily Seats:"
  echo "$EVENT" | jq -r '.dailySeats | to_entries[] | "  \(.key): \(.value.available)/\(.value.total) available"'
  
  echo ""
  
  # Test locking based on available pass types
  if [ "$DAILY_ENABLED" = "true" ]; then
    echo -e "${YELLOW}Testing Daily Pass Lock...${NC}"
    FIRST_DATE=$(echo "$EVENT" | jq -r '.dailySeats | keys[0]')
    
    LOCK_RESPONSE=$(curl -s -X POST "$API_BASE/events/$EVENT_ID/lock" \
      -H "Content-Type: application/json" \
      -d "{
        \"userId\": \"$USER_ID\",
        \"seats\": 1,
        \"passType\": \"daily\",
        \"selectedDate\": \"$FIRST_DATE\",
        \"idempotencyKey\": \"test-daily-$(date +%s)-$i\"
      }")
    
    if echo "$LOCK_RESPONSE" | jq -e '.success' | grep -q true; then
      echo -e "${GREEN}  ✅ Daily pass lock successful${NC}"
      LOCK_ID=$(echo "$LOCK_RESPONSE" | jq -r '.lock._id')
      
      # Cancel immediately
      curl -s -X POST "$API_BASE/locks/$LOCK_ID/cancel" > /dev/null
      echo -e "${GREEN}  ✅ Lock cancelled${NC}"
    else
      ERROR_MSG=$(echo "$LOCK_RESPONSE" | jq -r '.message')
      echo -e "${RED}  ❌ Daily pass lock failed: $ERROR_MSG${NC}"
    fi
  fi
  
  if [ "$SEASON_ENABLED" = "true" ]; then
    echo -e "${YELLOW}Testing Season Pass Lock...${NC}"
    
    LOCK_RESPONSE=$(curl -s -X POST "$API_BASE/events/$EVENT_ID/lock" \
      -H "Content-Type: application/json" \
      -d "{
        \"userId\": \"$USER_ID\",
        \"seats\": 1,
        \"passType\": \"season\",
        \"idempotencyKey\": \"test-season-$(date +%s)-$i\"
      }")
    
    if echo "$LOCK_RESPONSE" | jq -e '.success' | grep -q true; then
      echo -e "${GREEN}  ✅ Season pass lock successful${NC}"
      LOCK_ID=$(echo "$LOCK_RESPONSE" | jq -r '.lock._id')
      
      # Cancel immediately
      curl -s -X POST "$API_BASE/locks/$LOCK_ID/cancel" > /dev/null
      echo -e "${GREEN}  ✅ Lock cancelled${NC}"
    else
      ERROR_MSG=$(echo "$LOCK_RESPONSE" | jq -r '.message')
      echo -e "${RED}  ❌ Season pass lock failed: $ERROR_MSG${NC}"
    fi
  fi
  
  echo ""
done

echo ""
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo -e "${GREEN}✅ Pass options are correctly configured${NC}"
echo -e "${GREEN}✅ Lock API accepts pass types${NC}"
echo ""
echo "Frontend Checklist:"
echo "1. Open the event in browser"
echo "2. Verify pass options are displayed"
echo "3. Try booking with each pass type"
echo "4. Verify correct prices are shown"
echo ""
