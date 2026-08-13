const express = require('express');
const crypto = require('crypto');
const { pool } = require('../config/db');
const { requireAuth } = require('../middleware/auth');
const { adminOnly } = require('../middleware/adminOnly');
const { processEvent } = require('../services/alertEngine');

const router = express.Router();
router.use(requireAuth, adminOnly);

const CATEGORIES = ['earthquake', 'flood', 'cyclone', 'wildfire', 'landslide', 'other'];
const SEVERITIES = ['low', 'moderate', 'high', 'critical'];

// Creates a manual disaster event and immediately runs it through the same
// region-matching + alert + push pipeline as the external feed poller.
router.post('/disasters/simulate', async (req, res) => {
  const { category, severity, title, description, latitude, longitude, affectedRadiusKm } = req.body;

  if (!CATEGORIES.includes(category)) {
    return res.status(400).json({ error: `category must be one of: ${CATEGORIES.join(', ')}` });
  }
  if (!SEVERITIES.includes(severity)) {
    return res.status(400).json({ error: `severity must be one of: ${SEVERITIES.join(', ')}` });
  }
  if (typeof latitude !== 'number' || typeof longitude !== 'number') {
    return res.status(400).json({ error: 'latitude and longitude (numbers) are required' });
  }
  if (!title) {
    return res.status(400).json({ error: 'title is required' });
  }

  const result = await processEvent({
    source: 'manual',
    external_id: crypto.randomUUID(),
    category,
    severity,
    title,
    description,
    latitude,
    longitude,
    affected_radius_km: affectedRadiusKm || 25,
  });

  res.status(201).json(result);
});

router.get('/disasters', async (req, res) => {
  const { rows } = await pool.query('SELECT * FROM disaster_events ORDER BY occurred_at DESC');
  res.json(rows);
});

router.get('/users', async (req, res) => {
  const { rows } = await pool.query(
    'SELECT id, email, display_name, role, latitude, longitude, location_label, created_at FROM users ORDER BY created_at DESC'
  );
  res.json(rows);
});

router.get('/notifications', async (req, res) => {
  const { rows } = await pool.query(
    `SELECT n.id, n.delivery_status, n.fcm_message_id, n.error, n.sent_at,
            a.message, a.severity, u.email, e.category, e.title
     FROM notifications n
     JOIN alerts a ON a.id = n.alert_id
     JOIN users u ON u.id = a.user_id
     JOIN disaster_events e ON e.id = a.event_id
     ORDER BY n.id DESC`
  );
  res.json(rows);
});

module.exports = router;
