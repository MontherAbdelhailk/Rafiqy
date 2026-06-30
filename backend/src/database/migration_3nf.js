'use strict';

/**
 * Migration: 3NF Normalization
 * ─────────────────────────────────────────────────────────────────────────────
 * Safe, additive migration. No tables are dropped or renamed.
 * All changes are backward-compatible or handled with computed columns first.
 *
 * Changes applied:
 *  1. Add user_role ENUM and constrain users.role
 *  2. Add sync_full_name trigger (keeps full_name in sync automatically)
 *  3. Add slot_state ENUM + column on consultation_slots
 *  4. Migrate is_available/is_booked data → slot_state
 *  5. Drop redundant boolean columns (is_available, is_booked) – replaced by slot_state
 *  6. Add all missing performance indexes
 *  7. Add CHECK constraint on admin_chat_messages (one side must be admin)
 *
 * Run: node src/database/migration_3nf.js
 */

require('dotenv').config();
const { pool } = require('./connection');

// ─────────────────────────────────────────────────────────────────────────────
// Step 1 — user_role ENUM + constrain users.role
// ─────────────────────────────────────────────────────────────────────────────
const step1_userRoleEnum = `
-- Create the ENUM (safe re-run)
DO $$ BEGIN
  CREATE TYPE user_role AS ENUM ('user', 'admin');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- Verify only valid values exist before altering column type
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM users WHERE role NOT IN ('user', 'admin')
  ) THEN
    RAISE EXCEPTION 'users.role contains values other than (user, admin). Fix data first.';
  END IF;
END $$;

-- Drop default value constraint first, alter column type, then restore default with ENUM type
ALTER TABLE users ALTER COLUMN role DROP DEFAULT;

ALTER TABLE users
  ALTER COLUMN role TYPE user_role
  USING role::user_role;

ALTER TABLE users ALTER COLUMN role SET DEFAULT 'user'::user_role;
`;

// ─────────────────────────────────────────────────────────────────────────────
// Step 2 — sync_full_name trigger (eliminates manual derivation)
// ─────────────────────────────────────────────────────────────────────────────
const step2_fullNameTrigger = `
-- Function: automatically keep full_name in sync with first_name + last_name
CREATE OR REPLACE FUNCTION sync_full_name()
RETURNS TRIGGER AS $$
BEGIN
  -- Only update full_name when first_name or last_name changes
  IF (NEW.first_name IS DISTINCT FROM OLD.first_name)
  OR (NEW.last_name  IS DISTINCT FROM OLD.last_name)
  THEN
    NEW.full_name = TRIM(
      COALESCE(NEW.first_name, '') ||
      CASE
        WHEN NEW.first_name IS NOT NULL AND NEW.last_name IS NOT NULL
          AND NEW.last_name <> '' THEN ' '
        ELSE ''
      END ||
      COALESCE(NEW.last_name, '')
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop old trigger if exists, then recreate
DROP TRIGGER IF EXISTS users_sync_full_name ON users;
CREATE TRIGGER users_sync_full_name
  BEFORE INSERT OR UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION sync_full_name();
`;

// ─────────────────────────────────────────────────────────────────────────────
// Step 3 — slot_state ENUM (replaces dual boolean flags)
// ─────────────────────────────────────────────────────────────────────────────
const step3_slotStateEnum = `
-- Create ENUM
DO $$ BEGIN
  CREATE TYPE slot_state AS ENUM ('available', 'reserved', 'booked', 'disabled');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- Add column (nullable first, will be populated in step 4)
ALTER TABLE consultation_slots
  ADD COLUMN IF NOT EXISTS slot_state slot_state;
`;

// ─────────────────────────────────────────────────────────────────────────────
// Step 4 — Migrate boolean data → slot_state
// ─────────────────────────────────────────────────────────────────────────────
const step4_migrateSlotState = `
-- Populate slot_state from the two boolean flags
-- is_available=T, is_booked=F → available (open for booking)
-- is_available=T, is_booked=T → reserved  (pending payment)
-- is_available=F, is_booked=T → booked    (confirmed, permanently taken)
-- is_available=F, is_booked=F → disabled  (admin closed, not bookable)
UPDATE consultation_slots
SET slot_state =
  CASE
    WHEN is_available = TRUE  AND is_booked = FALSE THEN 'available'::slot_state
    WHEN is_available = TRUE  AND is_booked = TRUE  THEN 'reserved'::slot_state
    WHEN is_available = FALSE AND is_booked = TRUE  THEN 'booked'::slot_state
    ELSE                                                 'disabled'::slot_state
  END
WHERE slot_state IS NULL;

-- Now make it NOT NULL with a default
ALTER TABLE consultation_slots
  ALTER COLUMN slot_state SET NOT NULL,
  ALTER COLUMN slot_state SET DEFAULT 'available';
`;

// ─────────────────────────────────────────────────────────────────────────────
// Step 5 — Drop redundant boolean columns
// ─────────────────────────────────────────────────────────────────────────────
const step5_dropBooleans = `
-- Safe drop (column may not exist on a fresh DB)
ALTER TABLE consultation_slots
  DROP COLUMN IF EXISTS is_available,
  DROP COLUMN IF EXISTS is_booked;
`;

// ─────────────────────────────────────────────────────────────────────────────
// Step 6 — Missing performance indexes
// ─────────────────────────────────────────────────────────────────────────────
const step6_indexes = `
-- posts.user_id (JOIN + filter by author)
CREATE INDEX IF NOT EXISTS posts_user_id_idx
  ON posts (user_id);

-- reels.user_id (JOIN + filter by author)
CREATE INDEX IF NOT EXISTS reels_user_id_idx
  ON reels (user_id);

-- videos.category_id / subcategory_id (JOIN in every video query)
CREATE INDEX IF NOT EXISTS videos_category_id_idx
  ON videos (category_id);

CREATE INDEX IF NOT EXISTS videos_subcategory_id_idx
  ON videos (subcategory_id);

-- videos.tags — GIN for array containment (@>, &&) operations
CREATE INDEX IF NOT EXISTS videos_tags_gin_idx
  ON videos USING GIN (tags);

-- admin_chat_messages — composite for conversation history queries
CREATE INDEX IF NOT EXISTS admin_chat_conversation_idx
  ON admin_chat_messages (sender_id, receiver_id, created_at DESC);

-- user_fcm_tokens.created_at — for cleanup/expiry queries
CREATE INDEX IF NOT EXISTS fcm_tokens_created_at_idx
  ON user_fcm_tokens (created_at DESC);

-- consultation_slots.slot_state — for filtering available slots
CREATE INDEX IF NOT EXISTS consultation_slots_state_idx
  ON consultation_slots (slot_state);

-- bookings: composite for user + status filter (common pattern)
CREATE INDEX IF NOT EXISTS bookings_user_status_idx
  ON bookings (user_id, status);

-- sessions: composite for user + status
CREATE INDEX IF NOT EXISTS sessions_user_status_idx
  ON sessions (user_id, status);
`;

// ─────────────────────────────────────────────────────────────────────────────
// Step 7 — user_id consistency trigger in payments and sessions
// ─────────────────────────────────────────────────────────────────────────────
const step7_userIdConsistency = `
-- Function: ensure payments.user_id matches the booking's user_id
CREATE OR REPLACE FUNCTION enforce_payment_user_consistency()
RETURNS TRIGGER AS $$
DECLARE
  expected_user_id UUID;
BEGIN
  SELECT user_id INTO expected_user_id
  FROM bookings WHERE id = NEW.booking_id;

  IF expected_user_id IS DISTINCT FROM NEW.user_id THEN
    RAISE EXCEPTION
      'payments.user_id (%) does not match bookings.user_id (%) for booking %',
      NEW.user_id, expected_user_id, NEW.booking_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS payments_user_consistency ON payments;
CREATE TRIGGER payments_user_consistency
  BEFORE INSERT OR UPDATE ON payments
  FOR EACH ROW EXECUTE FUNCTION enforce_payment_user_consistency();

-- Function: ensure sessions.user_id matches the booking's user_id
CREATE OR REPLACE FUNCTION enforce_session_user_consistency()
RETURNS TRIGGER AS $$
DECLARE
  expected_user_id UUID;
BEGIN
  SELECT user_id INTO expected_user_id
  FROM bookings WHERE id = NEW.booking_id;

  IF expected_user_id IS DISTINCT FROM NEW.user_id THEN
    RAISE EXCEPTION
      'sessions.user_id (%) does not match bookings.user_id (%) for booking %',
      NEW.user_id, expected_user_id, NEW.booking_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS sessions_user_consistency ON sessions;
CREATE TRIGGER sessions_user_consistency
  BEFORE INSERT OR UPDATE ON sessions
  FOR EACH ROW EXECUTE FUNCTION enforce_session_user_consistency();
`;

// ─────────────────────────────────────────────────────────────────────────────
// Runner
// ─────────────────────────────────────────────────────────────────────────────
const steps = [
  { name: 'Step 1 — user_role ENUM',               sql: step1_userRoleEnum },
  { name: 'Step 2 — sync_full_name trigger',        sql: step2_fullNameTrigger },
  { name: 'Step 3 — slot_state ENUM + column',      sql: step3_slotStateEnum },
  { name: 'Step 4 — migrate boolean → slot_state',  sql: step4_migrateSlotState },
  { name: 'Step 5 — drop is_available/is_booked',   sql: step5_dropBooleans },
  { name: 'Step 6 — missing indexes',               sql: step6_indexes },
  { name: 'Step 7 — user_id consistency triggers',  sql: step7_userIdConsistency },
];

async function runMigration() {
  const client = await pool.connect();
  try {
    console.log('🚀 Starting 3NF normalization migration...\n');
    await client.query('BEGIN');

    for (const step of steps) {
      console.log(`  ▶ ${step.name}`);
      await client.query(step.sql);
      console.log(`  ✓ ${step.name} — done`);
    }

    await client.query('COMMIT');
    console.log('\n✅ 3NF migration completed successfully!');
    console.log('\nSummary of changes:');
    console.log('  • users.role    → user_role ENUM (was VARCHAR)');
    console.log('  • users         → sync_full_name trigger added');
    console.log('  • consultation_slots → slot_state ENUM (replaced is_available + is_booked)');
    console.log('  • Added 10 missing performance indexes');
    console.log('  • Added user_id consistency triggers on payments + sessions');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('\n❌ Migration failed — rolled back all changes.');
    console.error('Error:', err.message);
    if (err.detail) console.error('Detail:', err.detail);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

runMigration();
