require('dotenv').config();
const mysql = require('mysql2/promise');

async function createDatabase(dbName) {
  const host = process.env.DB_HOST || 'localhost';
  const port = Number(process.env.DB_PORT || 3306);
  const user = process.env.DB_USER || 'root';
  const password = process.env.DB_PASSWORD || '';

  const connection = await mysql.createConnection({ host, port, user, password, multipleStatements: true });
  try {
    console.log(`🔧 Creating database if not exists: ${dbName}`);
    await connection.query(`CREATE DATABASE IF NOT EXISTS \`${dbName}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;`);
    console.log('✅ Database ready');
  } finally {
    await connection.end();
  }
}

if (require.main === module) {
  const dbName = process.env.DB_NAME || 'ebazar_local';
  createDatabase(dbName).catch(err => { console.error('❌ Failed to create database:', err); process.exit(1); });
}

module.exports = createDatabase;


