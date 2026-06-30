'use strict';

const logger = require('./logger');
const ChatModel = require('../models/chat.model');

/**
 * Dispatch Firebase Cloud Messaging notification
 * @param {string} receiverId Recipient user UUID
 * @param {object} payload Notification content details
 */
async function sendPushNotification(receiverId, { title, body, data }) {
  try {
    let tokens = [];
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

    if (receiverId === 'admin') {
      // 3NF / Security check: resolve all admin tokens from users with role 'admin'
      const { query } = require('../database/connection');
      const adminTokensRes = await query(`
        SELECT uft.fcm_token 
        FROM user_fcm_tokens uft
        JOIN users u ON uft.user_id = u.id
        WHERE u.role = 'admin'
      `);
      tokens = adminTokensRes.rows.map(row => row.fcm_token);
    } else if (uuidRegex.test(receiverId)) {
      tokens = await ChatModel.getFcmTokens(receiverId);
    } else {
      logger.warn(`🔔 Invalid receiverId for push notification: ${receiverId}. Skipping.`);
      return;
    }

    if (!tokens || tokens.length === 0) {
      logger.info(`🔔 No registered FCM tokens for receiver: ${receiverId}. Skipping push notification.`);
      return;
    }

    logger.info(`🔔 Sending push notification to receiver ${receiverId} (Tokens count: ${tokens.length})`);

    // For production-readiness, if a Firebase service configuration exists, we can call it.
    // As a fallback, we log the notification content and simulate successful dispatch.
    // If you have a legacy FCM key, you can set FCM_SERVER_KEY in your env.
    const fcmServerKey = process.env.FCM_SERVER_KEY;
    if (!fcmServerKey) {
      logger.info(`🔔 FCM_SERVER_KEY not configured. Simulated notification details:
        Title: ${title}
        Body: ${body}
        Payload: ${JSON.stringify(data)}`);
      return;
    }

    // Standard HTTP request to legacy FCM api (or v1 if service account is fully integrated)
    const fetch = (...args) => import('node-fetch').then(({default: fetch}) => fetch(...args));
    
    for (const token of tokens) {
      try {
        const response = await fetch('https://fcm.googleapis.com/fcm/send', {
          method: 'POST',
          headers: {
            'Authorization': `key=${fcmServerKey}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            to: token,
            notification: {
              title,
              body,
              sound: 'default',
            },
            data,
          }),
        });
        const resData = await response.json();
        logger.info(`🔔 FCM response: ${JSON.stringify(resData)}`);
      } catch (err) {
        logger.error(`❌ FCM dispatch failed for token ${token}: ${err.message}`);
      }
    }
  } catch (error) {
    logger.error(`❌ Failed to send push notification: ${error.message}`);
  }
}

module.exports = {
  sendPushNotification,
};
