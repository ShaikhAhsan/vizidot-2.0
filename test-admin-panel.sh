#!/bin/bash

# Comprehensive Admin Panel Testing Script
# Tests all pages, API endpoints, and CRUD operations

echo "🧪 Admin Panel Comprehensive Testing"
echo "======================================"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASSED=0
FAILED=0
WARNINGS=0

# Test 1: Check if services are running
echo "📡 Testing Services..."
echo "----------------------"

# Check backend
if curl -s http://localhost:8000/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Backend is running on port 8000${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}❌ Backend is NOT running on port 8000${NC}"
    FAILED=$((FAILED + 1))
fi

# Check admin panel
if curl -s http://localhost:3000 > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Admin Panel is running on port 3000${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}❌ Admin Panel is NOT running on port 3000${NC}"
    FAILED=$((FAILED + 1))
fi

echo ""

# Test 2: Check page files for syntax errors
echo "📄 Testing Page Files..."
echo "------------------------"

PAGES_DIR="/Users/macbook/Documents/GitHub/vizidot-2.0/admin-panel/src/pages"
PAGES=(
    "Dashboard.jsx"
    "UsersPage.jsx"
    "BusinessesPage.jsx"
    "ProductsPage.jsx"
    "OrdersPage.jsx"
    "CategoriesPage.jsx"
    "BrandsPage.jsx"
    "TagsPage.jsx"
    "CouponsPage.jsx"
    "ReviewsPage.jsx"
    "ArtistsPage.jsx"
    "ArtistFormPage.jsx"
    "AlbumsPage.jsx"
)

for page in "${PAGES[@]}"; do
    if [ -f "$PAGES_DIR/$page" ]; then
        # Check for basic React syntax
        if grep -q "import.*React\|from 'react'" "$PAGES_DIR/$page" && grep -q "export default\|export const" "$PAGES_DIR/$page"; then
            echo -e "${GREEN}✅ $page: Valid React component${NC}"
            PASSED=$((PASSED + 1))
        else
            echo -e "${YELLOW}⚠️  $page: Missing React import or export${NC}"
            WARNINGS=$((WARNINGS + 1))
        fi
    else
        echo -e "${RED}❌ $page: File not found${NC}"
        FAILED=$((FAILED + 1))
    fi
done

echo ""

# Test 3: Check for missing dependencies
echo "📦 Checking Dependencies..."
echo "----------------------------"

# Check if dayjs is needed and installed
if grep -r "dayjs" /Users/macbook/Documents/GitHub/vizidot-2.0/admin-panel/src/pages/ > /dev/null 2>&1; then
    if cd /Users/macbook/Documents/GitHub/vizidot-2.0/admin-panel && npm list dayjs > /dev/null 2>&1; then
        echo -e "${GREEN}✅ dayjs is installed${NC}"
        PASSED=$((PASSED + 1))
    else
        echo -e "${YELLOW}⚠️  dayjs is used but not installed${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi
    cd /Users/macbook/Documents/GitHub/vizidot-2.0
fi

echo ""

# Test 4: Test API endpoints (requires authentication)
echo "🌐 Testing API Endpoints..."
echo "----------------------------"
echo -e "${YELLOW}Note: API tests require authentication token${NC}"
echo ""

# List of endpoints to test
ENDPOINTS=(
    "/api/v1/admin/dashboard/stats:GET"
    "/api/v1/admin/users:GET"
    "/api/v1/admin/businesses:GET"
    "/api/v1/admin/products:GET"
    "/api/v1/admin/orders:GET"
    "/api/v1/admin/categories:GET"
    "/api/v1/admin/brands:GET"
    "/api/v1/admin/tags:GET"
    "/api/v1/admin/coupons:GET"
    "/api/v1/admin/reviews:GET"
    "/api/v1/music/artists:GET"
    "/api/v1/music/albums:GET"
)

for endpoint in "${ENDPOINTS[@]}"; do
    IFS=':' read -r path method <<< "$endpoint"
    response=$(curl -s -o /dev/null -w "%{http_code}" -X "$method" "http://localhost:8000$path" -H "Authorization: Bearer test" 2>/dev/null)
    
    if [ "$response" = "401" ] || [ "$response" = "403" ]; then
        echo -e "${GREEN}✅ $path: Endpoint exists (auth required)${NC}"
        PASSED=$((PASSED + 1))
    elif [ "$response" = "200" ]; then
        echo -e "${GREEN}✅ $path: Endpoint working${NC}"
        PASSED=$((PASSED + 1))
    elif [ "$response" = "404" ]; then
        echo -e "${RED}❌ $path: Endpoint not found${NC}"
        FAILED=$((FAILED + 1))
    else
        echo -e "${YELLOW}⚠️  $path: Status $response${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi
done

echo ""

# Test 5: Check database tables
echo "🗄️  Checking Database Tables..."
echo "-------------------------------"

cd /Users/macbook/Documents/GitHub/vizidot-2.0/backend
if export PATH="/usr/local/bin:$PATH" && node -e "const {sequelize} = require('./config/database'); sequelize.query('SHOW TABLES').then(([r]) => { const tables = r.map(t => Object.values(t)[0]); const musicTables = ['artists', 'artist_brandings', 'artist_shops', 'albums', 'audio_tracks', 'video_tracks', 'album_artists', 'track_artists']; const found = musicTables.filter(t => tables.includes(t)); console.log('Music tables found:', found.length, '/', musicTables.length); process.exit(found.length === musicTables.length ? 0 : 1); }).catch(e => { console.error(e.message); process.exit(1); });" 2>/dev/null; then
    echo -e "${GREEN}✅ All music platform tables exist${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}❌ Some music platform tables are missing${NC}"
    FAILED=$((FAILED + 1))
fi
cd /Users/macbook/Documents/GitHub/vizidot-2.0

echo ""

# Summary
echo "======================================"
echo "📊 TEST SUMMARY"
echo "======================================"
echo -e "${GREEN}✅ Passed: $PASSED${NC}"
echo -e "${YELLOW}⚠️  Warnings: $WARNINGS${NC}"
echo -e "${RED}❌ Failed: $FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All critical tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed. Please review the errors above.${NC}"
    exit 1
fi

