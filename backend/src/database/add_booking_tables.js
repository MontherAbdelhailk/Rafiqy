require('dotenv').config();
const { query, pool } = require('./connection');


const migration = `
-- ============================================================
-- Booking System Enum Types (safe creation)
-- ============================================================
DO $$ BEGIN
  CREATE TYPE booking_status AS ENUM ('pending_payment', 'confirmed', 'cancelled', 'completed', 'no_show');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE payment_status AS ENUM ('pending', 'success', 'failed', 'refunded');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE session_status AS ENUM ('scheduled', 'active', 'completed', 'cancelled');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- update_updated_at_column function (if not already exists)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- TABLE: consultation_slots
-- ============================================================
CREATE TABLE IF NOT EXISTS consultation_slots (
  id              UUID          NOT NULL DEFAULT gen_random_uuid(),
  start_time      TIMESTAMPTZ   NOT NULL,
  end_time        TIMESTAMPTZ   NOT NULL,
  duration_mins   INTEGER       NOT NULL DEFAULT 60,
  price           DECIMAL(10,2) NOT NULL DEFAULT 45.00,
  is_available    BOOLEAN       NOT NULL DEFAULT TRUE,
  is_booked       BOOLEAN       NOT NULL DEFAULT FALSE,
  notes           TEXT,
  created_by      UUID          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),

  CONSTRAINT consultation_slots_pkey PRIMARY KEY (id),
  CONSTRAINT slot_times_valid CHECK (end_time > start_time)
);

CREATE INDEX IF NOT EXISTS consultation_slots_start_time_idx ON consultation_slots (start_time);
CREATE INDEX IF NOT EXISTS consultation_slots_available_idx  ON consultation_slots (is_available, is_booked);

DROP TRIGGER IF EXISTS consultation_slots_updated_at ON consultation_slots;
CREATE TRIGGER consultation_slots_updated_at
  BEFORE UPDATE ON consultation_slots
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- TABLE: bookings
-- ============================================================
CREATE TABLE IF NOT EXISTS bookings (
  id                  UUID          NOT NULL DEFAULT gen_random_uuid(),
  user_id             UUID          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  slot_id             UUID          NOT NULL REFERENCES consultation_slots(id) ON DELETE RESTRICT,
  status              booking_status NOT NULL DEFAULT 'pending_payment',
  amount              DECIMAL(10,2) NOT NULL,
  notes               TEXT,
  cancellation_reason TEXT,
  cancelled_at        TIMESTAMPTZ,
  confirmed_at        TIMESTAMPTZ,
  completed_at        TIMESTAMPTZ,
  created_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW(),

  CONSTRAINT bookings_pkey PRIMARY KEY (id)
);

CREATE INDEX IF NOT EXISTS bookings_user_id_idx    ON bookings (user_id);
CREATE INDEX IF NOT EXISTS bookings_slot_id_idx    ON bookings (slot_id);
CREATE INDEX IF NOT EXISTS bookings_status_idx     ON bookings (status);
CREATE INDEX IF NOT EXISTS bookings_created_at_idx ON bookings (created_at DESC);

DROP TRIGGER IF EXISTS bookings_updated_at ON bookings;
CREATE TRIGGER bookings_updated_at
  BEFORE UPDATE ON bookings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- TABLE: payments
-- ============================================================
CREATE TABLE IF NOT EXISTS payments (
  id                    UUID          NOT NULL DEFAULT gen_random_uuid(),
  booking_id            UUID          NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
  user_id               UUID          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  paymob_order_id       TEXT,
  paymob_transaction_id TEXT,
  paymob_payment_key    TEXT,
  amount                DECIMAL(10,2) NOT NULL,
  currency              VARCHAR(5)    NOT NULL DEFAULT 'EGP',
  status                payment_status NOT NULL DEFAULT 'pending',
  payment_method        VARCHAR(50),
  raw_webhook_payload   JSONB,
  processed_at          TIMESTAMPTZ,
  created_at            TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ   NOT NULL DEFAULT NOW(),

  CONSTRAINT payments_pkey PRIMARY KEY (id)
);

CREATE UNIQUE INDEX IF NOT EXISTS payments_transaction_id_uidx ON payments (paymob_transaction_id) WHERE paymob_transaction_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS payments_booking_id_idx  ON payments (booking_id);
CREATE INDEX IF NOT EXISTS payments_user_id_idx     ON payments (user_id);
CREATE INDEX IF NOT EXISTS payments_status_idx      ON payments (status);

DROP TRIGGER IF EXISTS payments_updated_at ON payments;
CREATE TRIGGER payments_updated_at
  BEFORE UPDATE ON payments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- TABLE: sessions
-- ============================================================
CREATE TABLE IF NOT EXISTS sessions (
  id              UUID          NOT NULL DEFAULT gen_random_uuid(),
  booking_id      UUID          NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
  user_id         UUID          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  jitsi_room_name TEXT          NOT NULL,
  status          session_status NOT NULL DEFAULT 'scheduled',
  started_at      TIMESTAMPTZ,
  ended_at        TIMESTAMPTZ,
  admin_joined_at TIMESTAMPTZ,
  user_joined_at  TIMESTAMPTZ,
  notes           TEXT,
  created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),

  CONSTRAINT sessions_pkey PRIMARY KEY (id)
);

CREATE UNIQUE INDEX IF NOT EXISTS sessions_booking_id_uidx  ON sessions (booking_id);
CREATE UNIQUE INDEX IF NOT EXISTS sessions_jitsi_room_uidx  ON sessions (jitsi_room_name);
CREATE INDEX IF NOT EXISTS sessions_user_id_idx      ON sessions (user_id);
CREATE INDEX IF NOT EXISTS sessions_status_idx       ON sessions (status);

DROP TRIGGER IF EXISTS sessions_updated_at ON sessions;
CREATE TRIGGER sessions_updated_at
  BEFORE UPDATE ON sessions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
`;

async function runMigration() {
  const client = await pool.connect();
  try {
    console.log('🚀 Running booking system migration...');
    await client.query('BEGIN');
    await client.query(migration);
    await client.query('COMMIT');
    console.log('✅ Booking system tables created successfully!');
    console.log('  - consultation_slots');
    console.log('  - bookings');
    console.log('  - payments');
    console.log('  - sessions');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('❌ Migration failed:', err.message);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

runMigration();
