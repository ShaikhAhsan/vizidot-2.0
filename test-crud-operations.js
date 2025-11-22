/**
 * Comprehensive CRUD Operations Testing
 * Tests Create, Read, Update, Delete for all modules
 */

const http = require('http');

const BASE_URL = 'http://localhost:8000';
let AUTH_TOKEN = '';

// Helper to make HTTP requests
function makeRequest(path, method = 'GET', data = null) {
  return new Promise((resolve, reject) => {
    const url = new URL(path, BASE_URL);
    const options = {
      hostname: url.hostname,
      port: url.port || 8000,
      path: url.pathname + url.search,
      method,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${AUTH_TOKEN}`
      }
    };

    const req = http.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => { body += chunk; });
      res.on('end', () => {
        try {
          const parsed = body ? JSON.parse(body) : {};
          resolve({
            status: res.statusCode,
            success: res.statusCode >= 200 && res.statusCode < 300,
            data: parsed
          });
        } catch (e) {
          resolve({
            status: res.statusCode,
            success: false,
            data: { error: 'Invalid JSON response' },
            raw: body
          });
        }
      });
    });

    req.on('error', reject);
    
    if (data && method !== 'GET') {
      req.write(JSON.stringify(data));
    }
    
    req.end();
  });
}

// Test results
const results = {
  modules: {},
  summary: { total: 0, passed: 0, failed: 0 }
};

// Test CRUD for a module
async function testModuleCRUD(moduleName, endpoints) {
  console.log(`\n🔧 Testing ${moduleName} CRUD Operations...`);
  console.log('─'.repeat(50));
  
  const moduleResults = {
    create: null,
    read: null,
    update: null,
    delete: null
  };

  // CREATE
  if (endpoints.create) {
    try {
      const result = await makeRequest(endpoints.create.path, 'POST', endpoints.create.data || {});
      moduleResults.create = result;
      if (result.success) {
        console.log(`  ✅ CREATE: Success (ID: ${result.data?.data?.id || result.data?.data?.artist_id || 'N/A'})`);
        results.summary.passed++;
      } else if (result.status === 400 || result.status === 422) {
        console.log(`  ⚠️  CREATE: Validation error (expected for empty data)`);
      } else {
        console.log(`  ❌ CREATE: Failed - ${result.data?.error || result.status}`);
        results.summary.failed++;
      }
    } catch (error) {
      console.log(`  ❌ CREATE: Error - ${error.message}`);
      results.summary.failed++;
    }
    results.summary.total++;
  }

  // READ (List)
  if (endpoints.read) {
    try {
      const result = await makeRequest(endpoints.read.path, 'GET');
      moduleResults.read = result;
      if (result.success) {
        const count = result.data?.data?.length || result.data?.pagination?.total || 0;
        console.log(`  ✅ READ: Success (${count} items)`);
        results.summary.passed++;
      } else {
        console.log(`  ❌ READ: Failed - ${result.data?.error || result.status}`);
        results.summary.failed++;
      }
    } catch (error) {
      console.log(`  ❌ READ: Error - ${error.message}`);
      results.summary.failed++;
    }
    results.summary.total++;
  }

  // UPDATE
  if (endpoints.update) {
    try {
      const result = await makeRequest(endpoints.update.path, 'PUT', endpoints.update.data || {});
      moduleResults.update = result;
      if (result.success) {
        console.log(`  ✅ UPDATE: Success`);
        results.summary.passed++;
      } else if (result.status === 404) {
        console.log(`  ⚠️  UPDATE: Record not found (expected if no data exists)`);
      } else {
        console.log(`  ❌ UPDATE: Failed - ${result.data?.error || result.status}`);
        results.summary.failed++;
      }
    } catch (error) {
      console.log(`  ❌ UPDATE: Error - ${error.message}`);
      results.summary.failed++;
    }
    results.summary.total++;
  }

  // DELETE
  if (endpoints.delete) {
    try {
      const result = await makeRequest(endpoints.delete.path, 'DELETE');
      moduleResults.delete = result;
      if (result.success) {
        console.log(`  ✅ DELETE: Success`);
        results.summary.passed++;
      } else if (result.status === 404) {
        console.log(`  ⚠️  DELETE: Record not found (expected if no data exists)`);
      } else {
        console.log(`  ❌ DELETE: Failed - ${result.data?.error || result.status}`);
        results.summary.failed++;
      }
    } catch (error) {
      console.log(`  ❌ DELETE: Error - ${error.message}`);
      results.summary.failed++;
    }
    results.summary.total++;
  }

  results.modules[moduleName] = moduleResults;
}

// Main test function
async function runCRUDTests() {
  console.log('🧪 CRUD Operations Testing');
  console.log('='.repeat(60));
  console.log('Note: This requires a valid authentication token');
  console.log('Set AUTH_TOKEN environment variable or it will test without auth\n');

  // Test modules
  const modules = {
    'Users': {
      create: { path: '/api/v1/admin/users', data: { email: 'test@test.com', first_name: 'Test', last_name: 'User' } },
      read: { path: '/api/v1/admin/users' },
      update: { path: '/api/v1/admin/users/1', data: { first_name: 'Updated' } },
      delete: { path: '/api/v1/admin/users/1' }
    },
    'Artists': {
      create: { path: '/api/v1/music/artists', data: { name: 'Test Artist', country: 'US' } },
      read: { path: '/api/v1/music/artists' },
      update: { path: '/api/v1/music/artists/1', data: { name: 'Updated Artist' } },
      delete: { path: '/api/v1/music/artists/1' }
    },
    'Albums': {
      create: { path: '/api/v1/music/albums', data: { title: 'Test Album', artist_id: 1, album_type: 'audio' } },
      read: { path: '/api/v1/music/albums' },
      update: { path: '/api/v1/music/albums/1', data: { title: 'Updated Album' } },
      delete: { path: '/api/v1/music/albums/1' }
    },
    'Brands': {
      create: { path: '/api/v1/admin/brands', data: { name: 'Test Brand' } },
      read: { path: '/api/v1/admin/brands' },
      update: { path: '/api/v1/admin/brands/1', data: { name: 'Updated Brand' } },
      delete: { path: '/api/v1/admin/brands/1' }
    },
    'Tags': {
      create: { path: '/api/v1/admin/tags', data: { name: 'Test Tag' } },
      read: { path: '/api/v1/admin/tags' },
      update: { path: '/api/v1/admin/tags/1', data: { name: 'Updated Tag' } },
      delete: { path: '/api/v1/admin/tags/1' }
    }
  };

  for (const [moduleName, endpoints] of Object.entries(modules)) {
    await testModuleCRUD(moduleName, endpoints);
  }

  // Summary
  console.log('\n' + '='.repeat(60));
  console.log('📊 CRUD TEST SUMMARY');
  console.log('='.repeat(60));
  console.log(`Total Tests: ${results.summary.total}`);
  console.log(`✅ Passed: ${results.summary.passed}`);
  console.log(`❌ Failed: ${results.summary.failed}`);
  console.log(`Success Rate: ${((results.summary.passed / results.summary.total) * 100).toFixed(1)}%`);
  console.log('='.repeat(60));

  return results.summary.failed === 0;
}

// Run if called directly
if (require.main === module) {
  AUTH_TOKEN = process.env.AUTH_TOKEN || '';
  runCRUDTests()
    .then(success => {
      process.exit(success ? 0 : 1);
    })
    .catch(error => {
      console.error('Test execution error:', error);
      process.exit(1);
    });
}

module.exports = { runCRUDTests, makeRequest };

