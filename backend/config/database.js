const { Sequelize } = require('sequelize');
require('dotenv').config();

// Database configuration
const baseSequelizeConfig = {
  host: process.env.DB_HOST || 'localhost',
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
  timezone: '+05:00' // Pakistan Standard Time
};

// Only use socketPath if explicitly provided via env
if (process.env.DB_SOCKET) {
  baseSequelizeConfig.dialectOptions = {
    socketPath: process.env.DB_SOCKET
  };
}

const sequelize = new Sequelize(
  process.env.DB_NAME || 'ebazar',
  process.env.DB_USER || 'root',
  process.env.DB_PASSWORD || '',
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
