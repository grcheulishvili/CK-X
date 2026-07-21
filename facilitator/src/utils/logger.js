const winston = require('winston');
const config = require('../config');

// Safe JSON stringify that tolerates circular references (e.g. an Error whose
// metadata contains a TLSSocket/ClientRequest, which crashes JSON.stringify).
function safeStringify(obj) {
  const seen = new WeakSet();
  try {
    return JSON.stringify(obj, (key, value) => {
      if (typeof value === 'object' && value !== null) {
        if (seen.has(value)) return '[Circular]';
        seen.add(value);
      }
      return value;
    });
  } catch (e) {
    return `[Unserializable metadata: ${e.message}]`;
  }
}

// Define log format
const logFormat = winston.format.combine(
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
  winston.format.errors({ stack: true }),
  winston.format.splat(),
  winston.format.json()
);

// Create the logger instance
const logger = winston.createLogger({
  level: config.logging.level,
  format: logFormat,
  defaultMeta: { service: 'facilitator-service' },
  transports: [
    // Write all logs to console
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.printf(
          ({ level, message, timestamp, ...metadata }) => {
            let msg = `${timestamp} [${level}]: ${message}`;
            
            // Add metadata if exists (circular-safe)
            if (Object.keys(metadata).length > 0 && metadata.service) {
              msg += ' ' + safeStringify(metadata);
            }
            
            return msg;
          }
        )
      )
    }),
    
    // Write logs to file in production
    ...(config.env === 'production' ? [
      new winston.transports.File({ filename: 'logs/error.log', level: 'error' }),
      new winston.transports.File({ filename: 'logs/combined.log' })
    ] : [])
  ]
});

module.exports = logger; 