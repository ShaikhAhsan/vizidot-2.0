#!/usr/bin/env node
/**
 * Reads CREATE TABLE definitions from the connected MySQL database
 * and writes them to a file. Uses the same .env DB config as the app.
 *
 * Usage: node scripts/getCreateTables.js [output-file]
 * Example: node scripts/getCreateTables.js
 * Example: node scripts/getCreateTables.js schema.sql
 *
 * If no output file is given, prints to stdout.
 */

require('dotenv').config();
const fs = require('fs');
const path = require('path');

// Use same config as app but with minimal logging
process.env.NODE_ENV = process.env.NODE_ENV || 'development';
const { sequelize } = require('../config/database');

async function getTableNames() {
  const [rows] = await sequelize.query(
    `SELECT TABLE_NAME FROM information_schema.TABLES 
     WHERE TABLE_SCHEMA = :schema AND TABLE_TYPE = 'BASE TABLE' 
     ORDER BY TABLE_NAME`,
    { replacements: { schema: sequelize.config.database } }
  );
  return rows.map((r) => r.TABLE_NAME);
}

async function getCreateTable(tableName) {
  const [rows] = await sequelize.query(`SHOW CREATE TABLE \`${tableName}\``);
  return rows[0] ? rows[0]['Create Table'] : null;
}

async function main() {
  const outputPath = process.argv[2] || null;

  try {
    await sequelize.authenticate();
  } catch (err) {
    console.error('Database connection failed:', err.message);
    process.exit(1);
  }

  const dbName = sequelize.config.database;
  const tables = await getTableNames();

  const lines = [
    `-- CREATE TABLE definitions for database: ${dbName}`,
    `-- Generated at ${new Date().toISOString()}`,
    `-- Total tables: ${tables.length}`,
    '',
    `USE \`${dbName}\`;`,
    ''
  ];

  for (const tableName of tables) {
    const ddl = await getCreateTable(tableName);
    if (ddl) {
      lines.push(`-- ------------------------------`);
      lines.push(`-- Table: ${tableName}`);
      lines.push(`-- ------------------------------`);
      lines.push(ddl + ';');
      lines.push('');
    }
  }

  const out = lines.join('\n');

  if (outputPath) {
    const fullPath = path.isAbsolute(outputPath) ? outputPath : path.join(__dirname, '..', outputPath);
    fs.writeFileSync(fullPath, out, 'utf8');
    console.log(`Wrote ${tables.length} table(s) to ${fullPath}`);
  } else {
    console.log(out);
  }

  await sequelize.close();
  process.exit(0);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
