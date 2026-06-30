'use strict';

const LEVELS = { error: 0, warn: 1, info: 2, debug: 3 };
const currentLevel = process.env.NODE_ENV === 'production' ? 2 : 3;

const colorize = (level, text) => {
  if (process.env.NODE_ENV === 'production') return text;
  const colors = {
    error: '\x1b[31m', // red
    warn:  '\x1b[33m', // yellow
    info:  '\x1b[36m', // cyan
    debug: '\x1b[90m', // grey
  };
  return `${colors[level] || ''}${text}\x1b[0m`;
};

const format = (level, ...args) => {
  const timestamp = new Date().toISOString();
  const label = level.toUpperCase().padEnd(5);
  const message = args
    .map((a) => (typeof a === 'object' ? JSON.stringify(a, null, 2) : String(a)))
    .join(' ');
  return `[${timestamp}] ${colorize(level, label)} ${message}`;
};

const logger = {
  error: (...args) => {
    if (LEVELS.error <= currentLevel) console.error(format('error', ...args));
  },
  warn: (...args) => {
    if (LEVELS.warn <= currentLevel) console.warn(format('warn', ...args));
  },
  info: (...args) => {
    if (LEVELS.info <= currentLevel) console.log(format('info', ...args));
  },
  debug: (...args) => {
    if (LEVELS.debug <= currentLevel) console.log(format('debug', ...args));
  },
};

module.exports = logger;
