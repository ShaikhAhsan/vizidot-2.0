#!/usr/bin/env node
/**
 * Test MySQL connection with the same credentials as the API.
 * Run: node scripts/test-db-connection.js
 */
require('dotenv').config();
const mysql = require('mysql2/promise');

async function test() {
  const config = {
    host: process.env.DB_HOST || 'srv1149167.hstgr.cloud',
    port: parseInt(process.env.DB_PORT || '3306', 10),
    user: process.env.DB_USER || 'api_vizidot_user',
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME || 'u5gdchot-vizidot',
  };
  if (process.env.DB_SSL === 'true') {
    config.ssl = { rejectUnauthorized: false };
  }
  console.log('Connecting to:', { host: config.host, port: config.port, database: config.database, user: config.user, ssl: !!config.ssl });

  try {
    const conn = await mysql.createConnection(config);
    const [rows] = await conn.execute('SELECT 1 as ok');
    console.log('✅ Connection successful!', rows);
    await conn.end();
  } catch (err) {
    console.error('❌ Connection failed:', err.message);
  }
}
test();
