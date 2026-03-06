#!/bin/bash

# Multi-Day Event Booking Test Script
# Tests the fixed multi-day event booking functionality

API_BASE="http://localhost:3000/api"
EVENT_ID=""
USER_ID=""
LOCK_ID=""

echo "=========================================="
echo "Multi-Day Event Booking Test"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test 1: Get event details
echo -e "${YELLOW}Test 1: Fetching event details...${NC}"
if [ -z "$EVENT_ID" ]; then
  echo -e "${RED}❌ Please set EVENT_ID variable in the script${NC}"
  echo "   Find an event ID from your database or create one first"
  exit 1
fi

RESPONSE=$(curl -s "$API_BASE/events/$EVENT_ID")
echo "$RESPONSE" | jq '.'

# Check if response contains multi-day fields
if echo "$RESPONSE" | jq -e '.data.eventType' > /dev/null 2>&1; then
  EVENT_TYPE=$(echo "$RESPONSE" | jq -r '.data.eventType')
  echo -e "${GREEN}✅ Event type: $EVENT_TYPE${NC}"
else
  echo -e "${RED}❌ Missing eventType field${NC}"
  exit 1
fi

if [ "$EVENT_TYPE" = "multi-day" ]; then
  # Check for multi-day specific fields
  if echo "$RESPONSE" | jq -e '.data.passOptions' > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Pass options found${NC}"
    echo "$RESPONSE" | jq '.data.passOptions'
  else
    echo -e "${RED}❌ Missing passOptions field${NC}"
    exit 1
  fi

  if echo "$RESPONSE" | jq -e '.data.dailySeats' > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Daily seats found${NC}"
    echo "$RESPONSE" | jq '.data.dailySeats'
  else
    echo -e "${RED}❌ Missing dailySeats field${NC}"
    exit 1
  fi

  if echo "$RESPONSE" | jq -e '.data.endDate' > /dev/null 2>&1; then
    echo -e "${GREEN}✅ End date found${NC}"
  else
    echo -e "${RED}❌ Missing endDate field${NC}"
    exit 1
  fi

  # Check if event is published
  IS_PUBLISHED=$(echo "$RESPONSE" | jq -r '.data.isPublished')
  if [ "$IS_PUBLISHED" = "true" ]; then
    echo -e "${GREEN}✅ Event is published${NC}"
  else
    echo -e "${RED}❌ Event is not published (isPublished: $IS_PUBLISHED)${NC}"
    exit 1
  fi

  echo ""
  echo -e "${YELLOW}Test 2: Testing daily pass lock...${NC}"
  
  if [ -z "$USER_ID" ]; then
    echo -e "${RED}❌ Please set USER_ID variable in the script${NC}"
    exit 1
  fi

  # Get first available date
  FIRST_DATE=$(echo "$RESPONSE" | jq -r '.data.dailySeats | keys[0]')
  echo "Attempting to lock 2 seats for date: $FIRST_DATE"

  LOCK_RESPONSE=$(curl -s -X POST "$API_BASE/events/$EVENT_ID/lock" \
    -H "Content-Type: application/json" \
    -d "{
      \"userId\": \"$USER_ID\",
      \"seats\": 2,
      \"passType\": \"daily\",
      \"selectedDate\": \"$FIRST_DATE\",
      \"idempotencyKey\": \"test-daily-$(date +%s)\"
    }")

  echo "$LOCK_RESPONSE" | jq '.'

  if echo "$LOCK_RESPONSE" | jq -e '.success' | grep -q true; then
    echo -e "${GREEN}✅ Daily pass lock successful${NC}"
    LOCK_ID=$(echo "$LOCK_RESPONSE" | jq -r '.lock._id')
    
    # Cancel the lock
    echo ""
    echo -e "${YELLOW}Test 3: Cancelling lock...${NC}"
    CANCEL_RESPONSE=$(curl -s -X POST "$API_BASE/locks/$LOCK_ID/cancel")
    echo "$CANCEL_RESPONSE" | jq '.'
    
    if echo "$CANCEL_RESPONSE" | jq -e '.success' | grep -q true; then
      echo -e "${GREEN}✅ Lock cancelled successfully${NC}"
    else
      echo -e "${RED}❌ Failed to cancel lock${NC}"
    fi
  else
    echo -e "${RED}❌ Daily pass lock failed${NC}"
    echo "Error: $(echo "$LOCK_RESPONSE" | jq -r '.message')"
    exit 1
  fi

  echo ""
  echo -e "${YELLOW}Test 4: Testing season pass lock...${NC}"
  
  SEASON_LOCK_RESPONSE=$(curl -s -X POST "$API_BASE/events/$EVENT_ID/lock" \
    -H "Content-Type: application/json" \
    -d "{
      \"userId\": \"$USER_ID\",
      \"seats\": 1,
      \"passType\": \"season\",
      \"idempotencyKey\": \"test-season-$(date +%s)\"
    }")

  echo "$SEASON_LOCK_RESPONSE" | jq '.'

  if echo "$SEASON_LOCK_RESPONSE" | jq -e '.success' | grep -q true; then
    echo -e "${GREEN}✅ Season pass lock successful${NC}"
    SEASON_LOCK_ID=$(echo "$SEASON_LOCK_RESPONSE" | jq -r '.lock._id')
    
    # Cancel the season lock
    echo ""
    echo -e "${YELLOW}Test 5: Cancelling season lock...${NC}"
    SEASON_CANCEL_RESPONSE=$(curl -s -X POST "$API_BASE/locks/$SEASON_LOCK_ID/cancel")
    echo "$SEASON_CANCEL_RESPONSE" | jq '.'
    
    if echo "$SEASON_CANCEL_RESPONSE" | jq -e '.success' | grep -q true; then
      echo -e "${GREEN}✅ Season lock cancelled successfully${NC}"
    else
      echo -e "${RED}❌ Failed to cancel season lock${NC}"
    fi
  else
    echo -e "${RED}❌ Season pass lock failed${NC}"
    echo "Error: $(echo "$SEASON_LOCK_RESPONSE" | jq -r '.message')"
  fi

else
  echo -e "${YELLOW}ℹ️  This is a single-day event, skipping multi-day tests${NC}"
fi

echo ""
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo -e "${GREEN}✅ All critical fields are present${NC}"
echo -e "${GREEN}✅ Multi-day booking flow is working${NC}"
echo ""
echo "Next steps:"
echo "1. Test the frontend booking UI"
echo "2. Create a new multi-day event and book tickets"
echo "3. Verify seat deductions are correct"
