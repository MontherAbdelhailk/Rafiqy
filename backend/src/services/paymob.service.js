'use strict';

const https = require('https');
const crypto = require('crypto');
const logger = require('../utils/logger');

const PAYMOB_BASE_URL = 'https://accept.paymob.com/api';

/**
 * Make an HTTP request to Paymob API
 */
function paymobRequest(path, body = null, method = 'POST') {
  return new Promise((resolve, reject) => {
    const url = new URL(`${PAYMOB_BASE_URL}${path}`);
    const bodyData = body ? JSON.stringify(body) : null;

    const options = {
      hostname: url.hostname,
      port: 443,
      path: url.pathname + url.search,
      method,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...(bodyData ? { 'Content-Length': Buffer.byteLength(bodyData) } : {}),
      },
    };

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        try {
          const parsed = JSON.parse(data);
          if (res.statusCode >= 200 && res.statusCode < 300) {
            resolve(parsed);
          } else {
            reject(new Error(`Paymob API error ${res.statusCode}: ${JSON.stringify(parsed)}`));
          }
        } catch {
          reject(new Error(`Failed to parse Paymob response: ${data}`));
        }
      });
    });

    req.on('error', reject);
    if (bodyData) req.write(bodyData);
    req.end();
  });
}

/**
 * Step 1: Authenticate with Paymob and get auth_token
 */
async function getAuthToken() {
  const apiKey = process.env.PAYMOB_API_KEY;
  if (!apiKey) throw new Error('PAYMOB_API_KEY not configured');

  const response = await paymobRequest('/auth/tokens', { api_key: apiKey });

  if (!response.token) {
    throw new Error('Paymob authentication failed: no token returned');
  }
  logger.info('✅ Paymob auth token obtained');
  return response.token;
}

/**
 * Step 2: Create a Paymob order and get order_id
 */
async function createOrder({ authToken, amountCents, currency = 'EGP', merchantOrderId, items = [] }) {
  const response = await paymobRequest('/ecommerce/orders', {
    auth_token: authToken,
    delivery_needed: false,
    amount_cents: amountCents,
    currency,
    merchant_order_id: merchantOrderId,
    items: items.length > 0 ? items : [
      {
        name: 'Consultation Session',
        amount_cents: amountCents,
        description: 'Online Family Counseling Session with Dr. Yehia',
        quantity: 1,
      },
    ],
  });

  if (!response.id) {
    throw new Error('Paymob order creation failed: no order ID returned');
  }
  logger.info(`✅ Paymob order created: ${response.id}`);
  return response;
}

/**
 * Step 3: Create a payment key for the iframe
 */
async function createPaymentKey({
  authToken,
  amountCents,
  currency = 'EGP',
  orderId,
  integrationId,
  billingData,
}) {
  const response = await paymobRequest('/acceptance/payment_keys', {
    auth_token: authToken,
    amount_cents: amountCents,
    expiration: 3600, // 1 hour
    order_id: orderId,
    billing_data: billingData,
    currency,
    integration_id: parseInt(integrationId),
    lock_order_when_paid: true,
  });

  if (!response.token) {
    throw new Error('Paymob payment key creation failed');
  }
  logger.info('✅ Paymob payment key created');
  return response.token;
}

/**
 * Full initiation flow: auth → create order → create payment key
 * Returns: { paymentKey, orderId, iframeUrl }
 */
async function initiatePayment({ amountEGP, merchantOrderId, billingData, integrationId, paymentMethod = 'card', walletNumber = '01000000000' }) {
  const amountCents = Math.round(parseFloat(amountEGP) * 100);
  
  // Set integration ID based on paymentMethod
  let integId = integrationId;
  if (!integId) {
    if (paymentMethod === 'wallet') {
      integId = process.env.PAYMOB_WALLET_INTEGRATION_ID;
    } else if (paymentMethod === 'meeza') {
      integId = process.env.PAYMOB_MEEZA_INTEGRATION_ID || process.env.PAYMOB_CARD_INTEGRATION_ID || process.env.PAYMOB_INTEGRATION_ID;
    } else {
      integId = process.env.PAYMOB_CARD_INTEGRATION_ID || process.env.PAYMOB_INTEGRATION_ID;
    }
  }

  const iframeId = process.env.PAYMOB_IFRAME_ID;

  if (!integId) throw new Error('PAYMOB_INTEGRATION_ID not configured');
  if (!iframeId) throw new Error('PAYMOB_IFRAME_ID not configured');

  const authToken = await getAuthToken();
  const order = await createOrder({ authToken, amountCents, merchantOrderId });
  const paymentKey = await createPaymentKey({
    authToken,
    amountCents,
    orderId: order.id,
    integrationId: integId,
    billingData: billingData || {
      apartment: 'NA',
      email: 'user@rafiq.app',
      floor: 'NA',
      first_name: 'Rafiq',
      street: 'NA',
      building: 'NA',
      phone_number: '+20100000000',
      shipping_method: 'NA',
      postal_code: 'NA',
      city: 'Cairo',
      country: 'EG',
      last_name: 'User',
      state: 'NA',
    },
  });

  let iframeUrl = `https://accept.paymob.com/api/acceptance/iframes/${iframeId}?payment_token=${paymentKey}`;

  // If mobile wallet, get checkout redirect URL from Paymob
  if (paymentMethod === 'wallet') {
    try {
      const walletResponse = await paymobRequest('/acceptance/payments/pay', {
        source: {
          identifier: walletNumber,
          subtype: 'WALLET'
        },
        payment_token: paymentKey
      });
      if (walletResponse.iframe_redirection_url || walletResponse.redirect_url) {
        iframeUrl = walletResponse.iframe_redirection_url || walletResponse.redirect_url;
      } else {
        logger.warn('Paymob wallet API did not return redirection URL, falling back to standard iframe');
      }
    } catch (walletErr) {
      logger.error('Failed to get Paymob wallet redirection:', walletErr.message);
    }
  }

  return {
    paymentKey,
    orderId: order.id,
    iframeUrl,
    amountCents,
  };
}

/**
 * Verify Paymob webhook HMAC-SHA512 signature
 * @param {string} hmacSecret - From PAYMOB_HMAC_SECRET env var
 * @param {object} callbackData - The processed_callback object from Paymob
 * @param {string} receivedHmac - The HMAC from the request query param (?hmac=...)
 * @returns {boolean} true if valid
 */
function verifyWebhookHmac(hmacSecret, callbackData, receivedHmac) {
  if (!hmacSecret || !receivedHmac) return false;

  // Paymob concatenates specific fields in this exact order
  const fields = [
    'amount_cents',
    'created_at',
    'currency',
    'error_occured',
    'has_parent_transaction',
    'id',
    'integration_id',
    'is_3d_secure',
    'is_auth',
    'is_capture',
    'is_refunded',
    'is_standalone_payment',
    'is_voided',
    'order.id',
    'owner',
    'pending',
    'source_data.pan',
    'source_data.sub_type',
    'source_data.type',
    'success',
  ];

  const concatenated = fields
    .map((field) => {
      const parts = field.split('.');
      let val = callbackData;
      for (const part of parts) {
        val = val?.[part];
      }
      return val !== undefined && val !== null ? String(val) : '';
    })
    .join('');

  const calculatedHmac = crypto
    .createHmac('sha512', hmacSecret)
    .update(concatenated)
    .digest('hex');

  return crypto.timingSafeEqual(
    Buffer.from(calculatedHmac, 'hex'),
    Buffer.from(receivedHmac, 'hex')
  );
}

module.exports = {
  initiatePayment,
  verifyWebhookHmac,
  getAuthToken,
  createOrder,
  createPaymentKey,
};
