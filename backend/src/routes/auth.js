const express = require('express');
const { admin } = require('../config/firebaseAdmin');
const { pool } = require('../config/db');

const router = express.Router();

// Called once after Firebase sign-up/sign-in on the client. Verifies the
// ID token and upserts the local user row keyed by firebase_uid.
router.post('/sync', async (req, res) => {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) {
    return res.status(401).json({ error: 'Missing Authorization: Bearer <idToken> header' });
  }

  try {
    const decoded = await admin.auth().verifyIdToken(token);
    const { rows } = await pool.query(
      `INSERT INTO users (firebase_uid, email, display_name)
       VALUES ($1, $2, $3)
       ON CONFLICT (firebase_uid) DO UPDATE SET email = EXCLUDED.email
       RETURNING *`,
      [decoded.uid, decoded.email || '', decoded.name || null]
    );
    res.json(rows[0]);
  } catch (err) {
    console.error('[auth/sync] failed:', err.message);
    res.status(401).json({ error: 'Invalid or expired token' });
  }
});

module.exports = router;
