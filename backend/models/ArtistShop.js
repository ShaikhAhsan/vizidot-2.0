const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const ArtistShop = sequelize.define('ArtistShop', {
  shop_id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
    field: 'shop_id'
  },
  artist_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    field: 'artist_id'
  },
  branding_id: {
    type: DataTypes.INTEGER,
    allowNull: true,
    field: 'branding_id'
  },
  shop_name: {
    type: DataTypes.STRING(255),
    allowNull: false,
    field: 'shop_name'
  },
  shop_url: {
    type: DataTypes.STRING(500),
    allowNull: false,
    field: 'shop_url'
  },
  description: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  is_deleted: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
    field: 'is_deleted'
  },
  deleted_at: {
    type: DataTypes.DATE,
    allowNull: true,
    field: 'deleted_at'
  }
}, {
  tableName: 'artist_shops',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at',
  underscored: true,
  defaultScope: {
    where: { is_deleted: false }
  },
  scopes: {
    withDeleted: {
      where: {}
    },
    deleted: {
      where: { is_deleted: true }
    }
  }
});

module.exports = ArtistShop;

