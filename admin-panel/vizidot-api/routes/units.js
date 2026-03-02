const express = require('express');
const router = express.Router();
const { Unit } = require('../models');
const { authenticateToken } = require('../middleware/authWithRoles');

// Get all units with optional search
router.get('/', authenticateToken, async (req, res) => {
  try {
    const { search, category, limit = 50 } = req.query;
    
    let whereClause = { is_active: true };
    
    if (search) {
      whereClause.name = {
        [require('sequelize').Op.like]: `%${search}%`
      };
    }
    
    if (category) {
      whereClause.category = category;
    }
    
    const units = await Unit.findAll({
      where: whereClause,
      order: [
        ['usage_count', 'DESC'],
        ['name', 'ASC']
      ],
      limit: parseInt(limit)
    });
    
    res.json({
      success: true,
      data: units
    });
  } catch (error) {
    console.error('Error fetching units:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch units'
    });
  }
});

// Create a new unit
router.post('/', authenticateToken, async (req, res) => {
  try {
    const { name, display_name, category } = req.body;
    
    if (!name) {
      return res.status(400).json({
        success: false,
        error: 'Unit name is required'
      });
    }
    
    const [unit, created] = await Unit.findOrCreate({
      where: { name: name.toLowerCase().trim() },
      defaults: {
        name: name.toLowerCase().trim(),
        display_name: display_name || name,
        category: category || 'other'
      }
    });
    
    if (!created) {
      return res.status(409).json({
        success: false,
        error: 'Unit already exists'
      });
    }
    
    res.status(201).json({
      success: true,
      data: unit
    });
  } catch (error) {
    console.error('Error creating unit:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to create unit'
    });
  }
});

// Increment usage count for a unit
router.post('/:id/increment-usage', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    
    const unit = await Unit.findByPk(id);
    if (!unit) {
      return res.status(404).json({
        success: false,
        error: 'Unit not found'
      });
    }
    
    await unit.incrementUsage();
    
    res.json({
      success: true,
      data: unit
    });
  } catch (error) {
    console.error('Error incrementing unit usage:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to increment unit usage'
    });
  }
});

// Get unit by name
router.get('/by-name/:name', authenticateToken, async (req, res) => {
  try {
    const { name } = req.params;
    
    const unit = await Unit.findOne({
      where: { 
        name: name.toLowerCase().trim(),
        is_active: true 
      }
    });
    
    if (!unit) {
      return res.status(404).json({
        success: false,
        error: 'Unit not found'
      });
    }
    
    res.json({
      success: true,
      data: unit
    });
  } catch (error) {
    console.error('Error fetching unit by name:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch unit'
    });
  }
});

module.exports = router;
