'use strict';

const { Router } = require('express');
const { pool } = require('../database/connection');

const router = Router();

/**
 * GET /api/health
 * Basic liveness check
 */
router.get('/', async (req, res) => {
  const uptime = process.uptime();

  res.status(200).json({
    success: true,
    status: 'healthy',
    environment: process.env.NODE_ENV || 'development',
    uptime: `${Math.floor(uptime)}s`,
    timestamp: new Date().toISOString(),
  });
});

/**
 * GET /api/health/db
 * Database connectivity check
 */
router.get('/db', async (req, res) => {
  try {
    const start = Date.now();
    await pool.query('SELECT 1');
    const latency = Date.now() - start;

    res.status(200).json({
      success: true,
      status: 'healthy',
      database: {
        connected: true,
        latency: `${latency}ms`,
      },
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    res.status(503).json({
      success: false,
      status: 'unhealthy',
      database: {
        connected: false,
        error: error.message,
      },
      timestamp: new Date().toISOString(),
    });
  }
});

module.exports = router;
