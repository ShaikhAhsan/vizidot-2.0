const { Sequelize } = require('sequelize');
require('dotenv').config();

// Database configuration
const baseSequelizeConfig = {
  host: process.env.DB_HOST || 'c1109547.sgvps.net',
  port: process.env.DB_PORT || 3306,
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
  baseSequelizeConfig
);

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
