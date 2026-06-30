'use strict';

require('dotenv').config();
const app = require('./app');
const { testConnection } = require('./database/connection');
const logger = require('./utils/logger');
const { initSocket } = require('./socket');

const PORT = process.env.PORT || 5000;

async function startServer() {
  try {
    // Test database connection before starting
    await testConnection();
    logger.info('✅ Database connection established successfully');

    const server = app.listen(PORT, () => {
      logger.info(`🚀 Rafiq Auth Backend running on port ${PORT}`);
      logger.info(`📍 Environment: ${process.env.NODE_ENV || 'development'}`);
      logger.info(`🔗 Health check: http://localhost:${PORT}/api/health`);
    });

    // Initialize Socket.IO server
    initSocket(server);

    // Graceful shutdown
    const shutdown = (signal) => {
      logger.info(`\n${signal} received. Shutting down gracefully...`);
      server.close(() => {
        logger.info('HTTP server closed.');
        process.exit(0);
      });

      // Force close after 10s
      setTimeout(() => {
        logger.error('Forced shutdown after timeout.');
        process.exit(1);
      }, 10000);
    };

    process.on('SIGTERM', () => shutdown('SIGTERM'));
    process.on('SIGINT', () => shutdown('SIGINT'));

    process.on('unhandledRejection', (reason, promise) => {
      logger.error('Unhandled Rejection at:', promise, 'reason:', reason);
    });

    process.on('uncaughtException', (error) => {
      logger.error('Uncaught Exception:', error);
      process.exit(1);
    });

  } catch (error) {
    logger.error('❌ Failed to start server:', error.message);
    process.exit(1);
  }
}

startServer();
