'use strict';

const crypto = require('crypto');

const ALGORITHM = 'aes-256-cbc';
// Derive a secure 32-byte key from CHAT_ENCRYPTION_KEY using SHA-256
const ENCRYPTION_KEY = crypto
  .createHash('sha256')
  .update(process.env.CHAT_ENCRYPTION_KEY || 'default_super_secure_key_rafiq_2026')
  .digest();

/**
 * Encrypt plain text using AES-256-CBC
 * @param {string} text Plain text to encrypt
 * @returns {string} Encrypted string in format iv:ciphertext
 */
function encrypt(text) {
  if (!text) return '';
  try {
    const iv = crypto.randomBytes(16);
    const cipher = crypto.createCipheriv(ALGORITHM, ENCRYPTION_KEY, iv);
    let encrypted = cipher.update(text, 'utf8', 'hex');
    encrypted += cipher.final('hex');
    return iv.toString('hex') + ':' + encrypted;
  } catch (error) {
    throw new Error('Encryption failed: ' + error.message);
  }
}

/**
 * Decrypt ciphertext in format iv:ciphertext using AES-256-CBC
 * @param {string} encryptedText Encrypted text to decrypt
 * @returns {string} Decrypted plain text
 */
function decrypt(encryptedText) {
  if (!encryptedText) return '';
  try {
    const parts = encryptedText.split(':');
    if (parts.length !== 2) {
      // Return original if it doesn't match the expected format (possibly pre-existing or unencrypted)
      return encryptedText;
    }
    const iv = Buffer.from(parts[0], 'hex');
    const encrypted = Buffer.from(parts[1], 'hex');
    const decipher = crypto.createDecipheriv(ALGORITHM, ENCRYPTION_KEY, iv);
    let decrypted = decipher.update(encrypted, 'hex', 'utf8');
    decrypted += decipher.final('utf8');
    return decrypted;
  } catch (error) {
    // Return original or error fallback if decryption fails
    console.error('Decryption failed:', error.message);
    return '[Decryption Error]';
  }
}

module.exports = {
  encrypt,
  decrypt,
};
