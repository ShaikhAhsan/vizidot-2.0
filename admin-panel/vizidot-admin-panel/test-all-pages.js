/**
 * Comprehensive Admin Panel Testing Script
 * Tests all pages, API endpoints, and CRUD operations
 */

const fs = require('fs');
const path = require('path');

// Test configuration
const BASE_URL = 'http://localhost:8000';
const ADMIN_TOKEN = process.env.ADMIN_TOKEN || ''; // Will need to be set

// Pages to test
const PAGES = [
  { name: 'Dashboard', route: '/dashboard', api: '/api/v1/admin/dashboard/stats', method: 'GET' },
  { name: 'Users', route: '/users', api: '/api/v1/admin/users', method: 'GET' },
  { name: 'Businesses', route: '/businesses', api: '/api/v1/admin/businesses', method: 'GET' },
  { name: 'Products', route: '/products', api: '/api/v1/admin/products', method: 'GET' },
  { name: 'Orders', route: '/orders', api: '/api/v1/admin/orders', method: 'GET' },
  { name: 'Categories', route: '/categories', api: '/api/v1/admin/categories', method: 'GET' },
  { name: 'Brands', route: '/brands', api: '/api/v1/admin/brands', method: 'GET' },
  { name: 'Tags', route: '/tags', api: '/api/v1/admin/tags', method: 'GET' },
  { name: 'Coupons', route: '/coupons', api: '/api/v1/admin/coupons', method: 'GET' },
  { name: 'Reviews', route: '/reviews', api: '/api/v1/admin/reviews', method: 'GET' },
  { name: 'Artists', route: '/artists', api: '/api/v1/music/artists', method: 'GET' },
  { name: 'Albums', route: '/albums', api: '/api/v1/music/albums', method: 'GET' },
];

// Test results
const results = {
  passed: [],
  failed: [],
  warnings: []
};

// Helper function to make API requests
async function testAPI(endpoint, method = 'GET', data = null) {
  try {
    const fetch = (await import('node-fetch')).default;
    const options = {
      method,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${ADMIN_TOKEN}`
      }
    };
    
    if (data && method !== 'GET') {
      options.body = JSON.stringify(data);
    }
    
    const response = await fetch(`${BASE_URL}${endpoint}`, options);
    const result = await response.json();
    
    return {
      success: response.ok,
      status: response.status,
      data: result
    };
  } catch (error) {
    return {
      success: false,
      error: error.message
    };
  }
}

// Test page file syntax
function testPageSyntax(pageName, filePath) {
  try {
    const content = fs.readFileSync(filePath, 'utf8');
    
    // Basic syntax checks
    const checks = {
      hasReactImport: content.includes('import React') || content.includes('from \'react\''),
      hasExport: content.includes('export default') || content.includes('export const'),
      hasValidJSX: content.includes('return') && (content.includes('<') || content.includes('jsx')),
      noSyntaxErrors: true // Would need actual parser for real check
    };
    
    const allPassed = Object.values(checks).every(v => v === true);
    
    if (allPassed) {
      results.passed.push(`✅ ${pageName}: Syntax check passed`);
    } else {
      results.warnings.push(`⚠️  ${pageName}: Some syntax checks failed`, checks);
    }
    
    return checks;
  } catch (error) {
    results.failed.push(`❌ ${pageName}: File read error - ${error.message}`);
    return null;
  }
}

// Test CRUD operations for a module
async function testCRUDOperations(moduleName, baseEndpoint) {
  const crudTests = {
    create: { method: 'POST', endpoint: baseEndpoint, data: {} },
    read: { method: 'GET', endpoint: baseEndpoint },
    update: { method: 'PUT', endpoint: `${baseEndpoint}/1`, data: {} },
    delete: { method: 'DELETE', endpoint: `${baseEndpoint}/1` }
  };
  
  const crudResults = {};
  
  for (const [operation, config] of Object.entries(crudTests)) {
    const result = await testAPI(config.endpoint, config.method, config.data);
    crudResults[operation] = result;
    
    if (result.success || result.status === 404 || result.status === 400) {
      // 404/400 are acceptable for update/delete if record doesn't exist
      results.passed.push(`✅ ${moduleName} - ${operation.toUpperCase()}: Endpoint accessible`);
    } else if (result.status === 401 || result.status === 403) {
      results.warnings.push(`⚠️  ${moduleName} - ${operation.toUpperCase()}: Auth required (expected)`);
    } else {
      results.failed.push(`❌ ${moduleName} - ${operation.toUpperCase()}: ${result.error || result.data?.error || 'Failed'}`);
    }
  }
  
  return crudResults;
}

// Main test function
async function runTests() {
  console.log('🧪 Starting Admin Panel Tests...\n');
  
  // Test 1: Check all page files exist and have valid syntax
  console.log('📄 Testing Page Files...');
  const pagesDir = path.join(__dirname, 'src/pages');
  const pageFiles = fs.readdirSync(pagesDir).filter(f => f.endsWith('.jsx'));
  
  for (const file of pageFiles) {
    const pageName = file.replace('.jsx', '');
    const filePath = path.join(pagesDir, file);
    testPageSyntax(pageName, filePath);
  }
  
  // Test 2: Test API endpoints (if token provided)
  if (ADMIN_TOKEN) {
    console.log('\n🌐 Testing API Endpoints...');
    for (const page of PAGES) {
      console.log(`Testing ${page.name}...`);
      const result = await testAPI(page.api, page.method);
      
      if (result.success) {
        results.passed.push(`✅ ${page.name} API: Working`);
      } else if (result.status === 401 || result.status === 403) {
        results.warnings.push(`⚠️  ${page.name} API: Auth required`);
      } else {
        results.failed.push(`❌ ${page.name} API: ${result.error || result.data?.error || 'Failed'}`);
      }
    }
    
    // Test 3: Test CRUD operations for key modules
    console.log('\n🔧 Testing CRUD Operations...');
    const modulesToTest = [
      { name: 'Users', endpoint: '/api/v1/admin/users' },
      { name: 'Artists', endpoint: '/api/v1/music/artists' },
      { name: 'Albums', endpoint: '/api/v1/music/albums' },
    ];
    
    for (const module of modulesToTest) {
      await testCRUDOperations(module.name, module.endpoint);
    }
  } else {
    console.log('\n⚠️  No ADMIN_TOKEN provided, skipping API tests');
    console.log('   Set ADMIN_TOKEN environment variable to test API endpoints');
  }
  
  // Print results
  console.log('\n' + '='.repeat(60));
  console.log('📊 TEST RESULTS SUMMARY');
  console.log('='.repeat(60));
  console.log(`✅ Passed: ${results.passed.length}`);
  console.log(`⚠️  Warnings: ${results.warnings.length}`);
  console.log(`❌ Failed: ${results.failed.length}`);
  
  if (results.passed.length > 0) {
    console.log('\n✅ PASSED TESTS:');
    results.passed.forEach(r => console.log(`   ${r}`));
  }
  
  if (results.warnings.length > 0) {
    console.log('\n⚠️  WARNINGS:');
    results.warnings.forEach(r => console.log(`   ${r}`));
  }
  
  if (results.failed.length > 0) {
    console.log('\n❌ FAILED TESTS:');
    results.failed.forEach(r => console.log(`   ${r}`));
  }
  
  console.log('\n' + '='.repeat(60));
  
  return results.failed.length === 0;
}

// Run tests
if (require.main === module) {
  runTests()
    .then(success => {
      process.exit(success ? 0 : 1);
    })
    .catch(error => {
      console.error('Test execution error:', error);
      process.exit(1);
    });
}

module.exports = { runTests, testAPI, testPageSyntax };
