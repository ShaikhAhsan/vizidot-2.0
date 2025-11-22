const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const ArtistBranding = sequelize.define('ArtistBranding', {
  branding_id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
    field: 'branding_id'
  },
  artist_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    field: 'artist_id'
  },
  branding_name: {
    type: DataTypes.STRING(255),
    allowNull: false,
    field: 'branding_name'
  },
  logo_url: {
    type: DataTypes.STRING(500),
    allowNull: true,
    field: 'logo_url'
  },
  tagline: {
    type: DataTypes.STRING(255),
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
  tableName: 'artist_brandings',
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

module.exports = ArtistBranding;

