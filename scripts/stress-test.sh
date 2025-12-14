#!/bin/bash

# =============================================================================
# Stress Test Script for Todo API
# =============================================================================
# Usage:
#   ./scripts/stress-test.sh [OPTIONS]
#
# Options:
#   -u, --url        Base URL (default: http://localhost:3000)
#   -d, --duration   Test duration in seconds (default: 60)
#   -c, --concurrent Number of concurrent requests (default: 10)
#   -r, --rate       Requests per second (default: 50)
#   -t, --test       Test type: all, read, write, mixed (default: mixed)
#   -h, --help       Show this help message
# =============================================================================

set -e

# Default values
BASE_URL="http://localhost:3000"
DURATION=60
CONCURRENT=10
RATE=50
TEST_TYPE="mixed"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -u|--url)
            BASE_URL="$2"
            shift 2
            ;;
        -d|--duration)
            DURATION="$2"
            shift 2
            ;;
        -c|--concurrent)
            CONCURRENT="$2"
            shift 2
            ;;
        -r|--rate)
            RATE="$2"
            shift 2
            ;;
        -t|--test)
            TEST_TYPE="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -u, --url        Base URL (default: http://localhost:3000)"
            echo "  -d, --duration   Test duration in seconds (default: 60)"
            echo "  -c, --concurrent Number of concurrent requests (default: 10)"
            echo "  -r, --rate       Requests per second (default: 50)"
            echo "  -t, --test       Test type: all, read, write, mixed (default: mixed)"
            echo "  -h, --help       Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}   🚀 Todo API Stress Test${NC}"
echo -e "${BLUE}============================================${NC}"
echo -e "${YELLOW}Configuration:${NC}"
echo -e "  Base URL:    ${GREEN}$BASE_URL${NC}"
echo -e "  Duration:    ${GREEN}${DURATION}s${NC}"
echo -e "  Concurrent:  ${GREEN}$CONCURRENT${NC}"
echo -e "  Rate:        ${GREEN}${RATE} req/s${NC}"
echo -e "  Test Type:   ${GREEN}$TEST_TYPE${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Check if API is reachable
echo -e "${YELLOW}🔍 Checking API health...${NC}"
if curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/health" | grep -q "200"; then
    echo -e "${GREEN}✅ API is healthy!${NC}"
else
    echo -e "${RED}❌ API is not reachable at $BASE_URL${NC}"
    exit 1
fi
echo ""

# Create a temporary todo to use for read/update tests
echo -e "${YELLOW}📝 Creating test todo...${NC}"
TEST_TODO=$(curl -s -X POST "$BASE_URL/todos" \
    -H "Content-Type: application/json" \
    -d '{"title":"Stress Test Todo","description":"Created for stress testing"}')
TEST_TODO_ID=$(echo $TEST_TODO | grep -o '"id":[0-9]*' | grep -o '[0-9]*' | head -1)

if [ -z "$TEST_TODO_ID" ]; then
    echo -e "${RED}❌ Failed to create test todo${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Created test todo with ID: $TEST_TODO_ID${NC}"
echo ""

# Function to run stress test with curl loop
stress_test() {
    local endpoint=$1
    local method=$2
    local data=$3
    local description=$4
    local count=$5
    
    echo -e "${YELLOW}🔥 Testing: $description${NC}"
    echo -e "   Endpoint: $method $endpoint"
    echo -e "   Requests: $count"
    
    local start_time=$(date +%s.%N)
    local success=0
    local failed=0
    
    for i in $(seq 1 $count); do
        if [ "$method" == "GET" ]; then
            response=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL$endpoint" 2>/dev/null)
        elif [ "$method" == "POST" ]; then
            response=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL$endpoint" \
                -H "Content-Type: application/json" \
                -d "$data" 2>/dev/null)
        elif [ "$method" == "PATCH" ]; then
            response=$(curl -s -o /dev/null -w "%{http_code}" -X PATCH "$BASE_URL$endpoint" \
                -H "Content-Type: application/json" \
                -d "$data" 2>/dev/null)
        fi
        
        if [[ "$response" =~ ^2[0-9][0-9]$ ]]; then
            ((success++))
        else
            ((failed++))
        fi
        
        # Progress indicator every 10%
        if [ $((i % (count / 10 + 1))) -eq 0 ]; then
            echo -n "."
        fi
    done
    
    local end_time=$(date +%s.%N)
    local elapsed=$(echo "$end_time - $start_time" | bc)
    local rps=$(echo "scale=2; $count / $elapsed" | bc)
    
    echo ""
    echo -e "   ${GREEN}✅ Success: $success${NC} | ${RED}❌ Failed: $failed${NC}"
    echo -e "   ⏱️  Time: ${elapsed}s | 📊 Rate: ${rps} req/s"
    echo ""
}

# Function to run parallel stress test
parallel_stress_test() {
    local endpoint=$1
    local method=$2
    local data=$3
    local description=$4
    local total_requests=$5
    local concurrent=$6
    
    echo -e "${YELLOW}🔥 Parallel Testing: $description${NC}"
    echo -e "   Endpoint: $method $endpoint"
    echo -e "   Total Requests: $total_requests"
    echo -e "   Concurrent: $concurrent"
    
    local start_time=$(date +%s.%N)
    
    # Create temporary file for results
    local temp_file=$(mktemp)
    
    for i in $(seq 1 $total_requests); do
        (
            if [ "$method" == "GET" ]; then
                response=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL$endpoint" 2>/dev/null)
            elif [ "$method" == "POST" ]; then
                response=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL$endpoint" \
                    -H "Content-Type: application/json" \
                    -d "$data" 2>/dev/null)
            elif [ "$method" == "PATCH" ]; then
                response=$(curl -s -o /dev/null -w "%{http_code}" -X PATCH "$BASE_URL$endpoint" \
                    -H "Content-Type: application/json" \
                    -d "$data" 2>/dev/null)
            fi
            echo "$response" >> "$temp_file"
        ) &
        
        # Limit concurrent processes
        if [ $((i % concurrent)) -eq 0 ]; then
            wait
        fi
    done
    wait
    
    local end_time=$(date +%s.%N)
    local elapsed=$(echo "$end_time - $start_time" | bc)
    local success=$(grep -c "^2" "$temp_file" 2>/dev/null || echo "0")
    local failed=$((total_requests - success))
    local rps=$(echo "scale=2; $total_requests / $elapsed" | bc)
    
    rm -f "$temp_file"
    
    echo -e "   ${GREEN}✅ Success: $success${NC} | ${RED}❌ Failed: $failed${NC}"
    echo -e "   ⏱️  Time: ${elapsed}s | 📊 Rate: ${rps} req/s"
    echo ""
}

# Calculate total requests based on duration and rate
TOTAL_REQUESTS=$((DURATION * RATE))

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}   📊 Starting Stress Tests${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

case $TEST_TYPE in
    "read")
        parallel_stress_test "/health" "GET" "" "Health Check" $((TOTAL_REQUESTS / 2)) $CONCURRENT
        parallel_stress_test "/todos" "GET" "" "Get All Todos" $((TOTAL_REQUESTS / 2)) $CONCURRENT
        ;;
    "write")
        parallel_stress_test "/todos" "POST" '{"title":"Stress Test","description":"Created during stress test"}' "Create Todo" $TOTAL_REQUESTS $CONCURRENT
        ;;
    "mixed")
        parallel_stress_test "/health" "GET" "" "Health Check" $((TOTAL_REQUESTS / 4)) $CONCURRENT
        parallel_stress_test "/todos" "GET" "" "Get All Todos" $((TOTAL_REQUESTS / 4)) $CONCURRENT
        parallel_stress_test "/todos/$TEST_TODO_ID" "GET" "" "Get Single Todo" $((TOTAL_REQUESTS / 4)) $CONCURRENT
        parallel_stress_test "/todos" "POST" '{"title":"Stress Test","description":"Created during stress test"}' "Create Todo" $((TOTAL_REQUESTS / 4)) $CONCURRENT
        ;;
    "all")
        echo -e "${YELLOW}📍 Phase 1: Health Checks${NC}"
        parallel_stress_test "/health" "GET" "" "Health Check" $((TOTAL_REQUESTS / 5)) $CONCURRENT
        
        echo -e "${YELLOW}📍 Phase 2: Read Operations${NC}"
        parallel_stress_test "/todos" "GET" "" "Get All Todos" $((TOTAL_REQUESTS / 5)) $CONCURRENT
        parallel_stress_test "/todos/$TEST_TODO_ID" "GET" "" "Get Single Todo" $((TOTAL_REQUESTS / 5)) $CONCURRENT
        
        echo -e "${YELLOW}📍 Phase 3: Write Operations${NC}"
        parallel_stress_test "/todos" "POST" '{"title":"Stress Test","description":"Created during stress test"}' "Create Todo" $((TOTAL_REQUESTS / 5)) $CONCURRENT
        parallel_stress_test "/todos/$TEST_TODO_ID" "PATCH" '{"title":"Updated Stress Test"}' "Update Todo" $((TOTAL_REQUESTS / 5)) $CONCURRENT
        ;;
esac

# Cleanup
echo -e "${YELLOW}🧹 Cleaning up test data...${NC}"
curl -s -X DELETE "$BASE_URL/todos/$TEST_TODO_ID" > /dev/null 2>&1
echo -e "${GREEN}✅ Cleanup complete!${NC}"
echo ""

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}   ✅ Stress Test Complete!${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""
echo -e "${YELLOW}💡 Tips:${NC}"
echo "  - Check Grafana dashboard to see the metrics"
echo "  - Monitor error rate, latency, and throughput"
echo "  - Prometheus URL: http://localhost:9090"
echo "  - Grafana URL: http://localhost:3001"
echo ""
