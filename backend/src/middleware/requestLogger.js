'use strict';

const logger = require('../utils/logger');

/**
 * HTTP request logger middleware
 */
const requestLogger = (req, res, next) => {
  const start = Date.now();
  const { method, path: reqPath, ip } = req;

  res.on('finish', () => {
    const duration = Date.now() - start;
    const { statusCode } = res;

    const level =
      statusCode >= 500 ? 'error' :
      statusCode >= 400 ? 'warn' :
      'info';

    logger[level](
      `${method} ${reqPath} ${statusCode} ${duration}ms — ${ip}`
    );
  });

  next();
};

module.exports = requestLogger;
