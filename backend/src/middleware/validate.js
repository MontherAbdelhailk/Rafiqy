'use strict';

const { validationResult } = require('express-validator');

/**
 * Middleware to check express-validator results.
 * Attach AFTER your validation chain in routes.
 */
const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (errors.isEmpty()) return next();

  const formattedErrors = errors.array().map((err) => ({
    field: err.path,
    message: err.msg,
  }));

  return res.status(422).json({
    success: false,
    error: {
      code: 'VALIDATION_ERROR',
      message: 'Input validation failed',
      details: formattedErrors,
    },
  });
};

module.exports = { validate };
