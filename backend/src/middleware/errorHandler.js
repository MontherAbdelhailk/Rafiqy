'use strict';

const logger = require('../utils/logger');

/**
 * Global error handler middleware.
 * Must be registered LAST in app.js.
 */
const errorHandler = (err, req, res, next) => {
  // Determine status code
  let statusCode = err.statusCode || err.status || 500;
  let message = err.message || 'Internal Server Error';
  let errorCode = err.errorCode || 'INTERNAL_ERROR';

  // Handle specific PostgreSQL errors
  if (err.code === '23505') {
    statusCode = 409;
    errorCode = 'DUPLICATE_ENTRY';
    message = 'A record with this value already exists';
  } else if (err.code === '23503') {
    statusCode = 400;
    errorCode = 'FOREIGN_KEY_VIOLATION';
    message = 'Referenced record does not exist';
  } else if (err.code === '22P02') {
    statusCode = 400;
    errorCode = 'INVALID_UUID';
    message = 'Invalid ID format';
  }

  // Don't leak internal details in production
  const isProduction = process.env.NODE_ENV === 'production';
  const isOperational = err.isOperational || false;

  if (statusCode >= 500 && !isOperational) {
    logger.error('Unexpected error:', {
      error: err.message,
      stack: err.stack,
      path: req.path,
      method: req.method,
      ip: req.ip,
    });
  }

  const response = {
    success: false,
    error: {
      code: errorCode,
      message: isProduction && !isOperational && statusCode >= 500
        ? 'Something went wrong. Please try again later.'
        : message,
    },
  };

  // Include stack trace in development
  if (!isProduction && err.stack) {
    response.error.stack = err.stack;
  }

  res.status(statusCode).json(response);
};

/**
 * 404 Not Found handler
 */
const notFoundHandler = (req, res) => {
  res.status(404).json({
    success: false,
    error: {
      code: 'NOT_FOUND',
      message: `Route ${req.method} ${req.path} not found`,
    },
  });
};

module.exports = { errorHandler, notFoundHandler };
