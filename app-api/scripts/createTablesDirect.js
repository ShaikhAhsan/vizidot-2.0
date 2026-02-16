require('dotenv').config();
const mysql = require('mysql2/promise');
const fs = require('fs');
const path = require('path');

async function createTables() {
  // Direct connection values (remembered choice - using mysql2 directly)
  const dbConfig = {
    host: 'c1109547.sgvps.net',
    port: 3306,
    user: 'u84b1oa3bdbvu',
    password: 'oi_-DR!b1GCh2qsip4',
    database: 'dbvwnuu5gdchot',
    multipleStatements: true
  };

  console.log(`🔌 Connecting to ${dbConfig.host}:${dbConfig.port}/${dbConfig.database}...`);
  
  const connection = await mysql.createConnection(dbConfig);

  try {
    console.log('🔌 Connected to database successfully');

    // Read and execute SQL file
    const sqlPath = path.join(__dirname, 'createLoginTables.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');

    console.log('🔄 Creating tables...');
    await connection.query(sql);
    console.log('✅ Tables created successfully!');

    // Verify tables were created
    const [tables] = await connection.query(`
      SELECT TABLE_NAME 
      FROM information_schema.TABLES 
      WHERE TABLE_SCHEMA = ? 
      AND TABLE_NAME IN ('users', 'roles', 'user_roles')
    `, [process.env.DB_NAME || 'dbvwnuu5gdchot']);

    console.log('\n📊 Created tables:');
    tables.forEach(table => {
      console.log(`   ✓ ${table.TABLE_NAME}`);
    });

  } catch (error) {
    console.error('❌ Error creating tables:', error.message);
    throw error;
  } finally {
    await connection.end();
    console.log('\n🔌 Connection closed');
  }
}

if (require.main === module) {
  createTables()
    .then(() => {
      console.log('\n🎉 All done!');
      process.exit(0);
    })
    .catch((error) => {
      console.error('\n❌ Failed:', error);
      process.exit(1);
    });
}

module.exports = createTables;

