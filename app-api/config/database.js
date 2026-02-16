const { Sequelize } = require('sequelize');
require('dotenv').config();

// Debug: Log database configuration (without password)
console.log('📊 Database Configuration:');
console.log('  DB_HOST:', process.env.DB_HOST || 'NOT SET (using default)');
console.log('  DB_PORT:', process.env.DB_PORT || 'NOT SET (using default)');
console.log('  DB_NAME:', process.env.DB_NAME || 'NOT SET (using default)');
console.log('  DB_USER:', process.env.DB_USER || 'NOT SET (using default)');
console.log('  DB_PASSWORD:', process.env.DB_PASSWORD ? '***SET***' : 'NOT SET (using default)');

// Database configuration
// Resolve hostname to IP if it's resolving to localhost
let dbHost = process.env.DB_HOST || 'c1109547.sgvps.net';

// If DB_HOST_IP is set, use it directly (for Docker containers where hostname resolves incorrectly)
if (process.env.DB_HOST_IP) {
  dbHost = process.env.DB_HOST_IP;
  console.log('🌐 Using DB_HOST_IP:', dbHost);
}

const baseSequelizeConfig = {
  host: dbHost,
  port: parseInt(process.env.DB_PORT || '3306', 10),
  dialect: 'mysql',
  logging: process.env.NODE_ENV === 'development' ? console.log : false,
  pool: {
    max: 10,
    min: 0,
    acquire: 30000,
    idle: 10000
  },
  define: {
    timestamps: true,
    underscored: true,
    freezeTableName: true
  },
  timezone: '+05:00', // Pakistan Standard Time
  dialectOptions: {
    // Enable SSL for remote connections (if required)
    ssl: process.env.DB_SSL === 'true' ? {
      rejectUnauthorized: false
    } : false
  },
  dialectModule: require('mysql2')
};

// Only use socketPath if explicitly provided via env
if (process.env.DB_SOCKET) {
  baseSequelizeConfig.dialectOptions = {
    ...baseSequelizeConfig.dialectOptions,
    socketPath: process.env.DB_SOCKET
  };
}

const sequelize = new Sequelize(
  process.env.DB_NAME || 'dbvwnuu5gdchot',
  process.env.DB_USER || 'u84b1oa3bdbvu',
  process.env.DB_PASSWORD || 'oi_-DR!b1GCh2qsip4',
  {
    ...baseSequelizeConfig,
    // Force TCP connection instead of socket
    dialectOptions: {
      ...baseSequelizeConfig.dialectOptions,
      socketPath: undefined, // Explicitly disable socket path
    }
  }
);

// Log the actual connection config being used
console.log('🔌 Sequelize Connection Config:', {
  host: sequelize.config.host,
  port: sequelize.config.port,
  database: sequelize.config.database,
  username: sequelize.config.username,
  hasPassword: !!sequelize.config.password
});

// Test database connection
const testConnection = async () => {
  try {
    await sequelize.authenticate();
    console.log('✅ Database connection has been established successfully.');
  } catch (error) {
    console.error('❌ Unable to connect to the database:', error);
    throw error;
  }
};

module.exports = {
  sequelize,
  testConnection
};
