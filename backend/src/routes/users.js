const express = require('express');
const { pool } = require('../config/db');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();
router.use(requireAuth);

router.get('/me', (req, res) => {
  res.json(req.user);
});

router.put('/me/location', async (req, res) => {
  const { latitude, longitude, locationLabel } = req.body;
  if (typeof latitude !== 'number' || typeof longitude !== 'number') {
    return res.status(400).json({ error: 'latitude and longitude (numbers) are required' });
  }
  const { rows } = await pool.query(
    `UPDATE users SET latitude = $1, longitude = $2, location_label = $3 WHERE id = $4 RETURNING *`,
    [latitude, longitude, locationLabel || null, req.user.id]
  );
  res.json(rows[0]);
});

router.post('/me/device-token', async (req, res) => {
  const { fcmToken, platform } = req.body;
  if (!fcmToken) {
    return res.status(400).json({ error: 'fcmToken is required' });
  }
  await pool.query(
    `INSERT INTO device_tokens (user_id, fcm_token, platform)
     VALUES ($1, $2, $3)
     ON CONFLICT (fcm_token) DO UPDATE SET user_id = EXCLUDED.user_id, platform = EXCLUDED.platform`,
    [req.user.id, fcmToken, platform || 'android']
  );
  res.status(204).send();
});

router.get('/me/alerts', async (req, res) => {
  const { rows } = await pool.query(
    `SELECT a.id, a.severity, a.message, a.created_at,
            e.category, e.title, e.description, e.latitude, e.longitude, e.occurred_at
     FROM alerts a
     JOIN disaster_events e ON e.id = a.event_id
     WHERE a.user_id = $1
     ORDER BY a.created_at DESC`,
    [req.user.id]
  );
  res.json(rows);
});

module.exports = router;
