'use strict';

/**
 * Operational error class for known/expected errors.
 * These are exposed to the client safely.
 */
class AppError extends Error {
  /**
   * @param {string} message   - Human-readable message
   * @param {number} statusCode - HTTP status code
   * @param {string} errorCode  - Machine-readable code (e.g. 'USER_NOT_FOUND')
   */
  constructor(message, statusCode = 500, errorCode = 'INTERNAL_ERROR') {
    super(message);
    this.name = 'AppError';
    this.statusCode = statusCode;
    this.errorCode = errorCode;
    this.isOperational = true; // Marks safe-to-expose errors

    if (Error.captureStackTrace) {
      Error.captureStackTrace(this, this.constructor);
    }
  }
}

module.exports = { AppError };
