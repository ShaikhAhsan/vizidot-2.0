// Quick verification script to check port configuration
const fs = require('fs');
const path = require('path');

console.log('🔍 Verifying Port Configuration...\n');

// Check backend port
const backendServer = fs.readFileSync(path.join(__dirname, 'backend/server.js'), 'utf8');
const backendPortMatch = backendServer.match(/const PORT = (\d+);/);
if (backendPortMatch) {
    console.log(`✅ Backend port: ${backendPortMatch[1]} (hardcoded)`);
} else {
    console.log('❌ Backend port not found or not hardcoded');
}

// Check admin panel port
const adminPackage = JSON.parse(fs.readFileSync(path.join(__dirname, 'admin-panel/package.json'), 'utf8'));
const adminStartScript = adminPackage.scripts.start || '';
if (adminStartScript.includes('PORT=3000')) {
    console.log(`✅ Admin Panel port: 3000 (hardcoded in start script)`);
} else {
    console.log('❌ Admin Panel port not hardcoded');
}

// Check proxy
if (adminPackage.proxy === 'http://localhost:8000') {
    console.log(`✅ Admin Panel proxy: http://localhost:8000 (correct)`);
} else {
    console.log(`⚠️  Admin Panel proxy: ${adminPackage.proxy || 'not set'}`);
}

console.log('\n📋 Summary:');
console.log('   Backend: http://localhost:8000');
console.log('   Admin Panel: http://localhost:3000');
console.log('   Proxy: Admin Panel → Backend (port 8000)');

