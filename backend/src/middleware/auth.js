const { admin } = require('../config/firebaseAdmin');
const { pool } = require('../config/db');

async function requireAuth(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;

  if (!token) {
    return res.status(401).json({ error: 'Missing Authorization: Bearer <idToken> header' });
  }

  try {
    const decoded = await admin.auth().verifyIdToken(token);
    const { rows } = await pool.query('SELECT * FROM users WHERE firebase_uid = $1', [decoded.uid]);

    if (rows.length === 0) {
      return res.status(403).json({ error: 'User not registered. Call /api/auth/sync first.' });
    }

    req.firebaseUser = decoded;
    req.user = rows[0];
    next();
  } catch (err) {
    console.error('[auth] token verification failed:', err.message);
    res.status(401).json({ error: 'Invalid or expired token' });
  }
}

module.exports = { requireAuth };
