'use strict';

/**
 * Rate limiting middleware using a simple in-memory store.
 * For production, replace with express-rate-limit + redis store.
 */

// Simple in-memory rate limiter factory
function createLimiter({ windowMs, max, message, skipSuccessfulRequests = false }) {
  const store = new Map();

  // Clean up old entries every windowMs
  setInterval(() => {
    const now = Date.now();
    for (const [key, data] of store.entries()) {
      if (data.resetAt <= now) store.delete(key);
    }
  }, windowMs);

  return (req, res, next) => {
    const key = req.ip;
    const now = Date.now();

    let data = store.get(key);
    if (!data || data.resetAt <= now) {
      data = { count: 0, resetAt: now + windowMs };
      store.set(key, data);
    }

    data.count++;

    res.setHeader('X-RateLimit-Limit', max);
    res.setHeader('X-RateLimit-Remaining', Math.max(0, max - data.count));
    res.setHeader('X-RateLimit-Reset', new Date(data.resetAt).toISOString());

    if (data.count > max) {
      return res.status(429).json({
        success: false,
        error: {
          code: 'RATE_LIMIT_EXCEEDED',
          message,
          retryAfter: Math.ceil((data.resetAt - now) / 1000),
        },
      });
    }

    next();
  };
}

const generalLimiter = createLimiter({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS, 10) || 15 * 60 * 1000,
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS, 10) || 100,
  message: 'Too many requests, please try again later.',
});

const authLimiter = createLimiter({
  windowMs: 15 * 60 * 1000,
  max: parseInt(process.env.AUTH_RATE_LIMIT_MAX, 10) || 5,
  message: 'Too many authentication attempts. Please wait 15 minutes and try again.',
});

module.exports = { generalLimiter, authLimiter, createLimiter };
