const { pool } = require('../config/db');
const { haversineDistanceKm } = require('./geo');
const { sendPush } = require('./fcm');

// Ingests one normalized disaster event and, if it's genuinely new, matches it
// against users' registered locations, creates alert rows, and pushes
// notifications. Used by both the admin "simulate disaster" endpoint and the
// (future) external feed poller, so both paths share identical dedup and
// notification behavior.
async function processEvent(event) {
  const {
    source,
    external_id: externalId,
    category,
    severity,
    title,
    description,
    latitude,
    longitude,
    affected_radius_km: radiusKm,
    occurred_at: occurredAt,
  } = event;

  const insertEvent = await pool.query(
    `INSERT INTO disaster_events
       (source, external_id, category, severity, title, description, latitude, longitude, affected_radius_km, occurred_at)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, COALESCE($10, now()))
     ON CONFLICT (source, external_id) DO NOTHING
     RETURNING *`,
    [source, externalId, category, severity, title, description || null, latitude, longitude, radiusKm, occurredAt || null]
  );

  if (insertEvent.rows.length === 0) {
    return { newEvent: false, event: null, alertsCreated: 0 };
  }

  const dbEvent = insertEvent.rows[0];

  const { rows: candidateUsers } = await pool.query(
    'SELECT id, latitude, longitude FROM users WHERE latitude IS NOT NULL AND longitude IS NOT NULL'
  );

  const affectedUsers = candidateUsers.filter(
    (u) => haversineDistanceKm(dbEvent.latitude, dbEvent.longitude, u.latitude, u.longitude) <= radiusKm
  );

  const message = `${severity.toUpperCase()} ${category} alert: ${title}`;
  let alertsCreated = 0;

  for (const user of affectedUsers) {
    const insertAlert = await pool.query(
      `INSERT INTO alerts (event_id, user_id, severity, message)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (event_id, user_id) DO NOTHING
       RETURNING id`,
      [dbEvent.id, user.id, severity, message]
    );

    if (insertAlert.rows.length === 0) continue; // duplicate-alert prevention
    alertsCreated += 1;
    const alertId = insertAlert.rows[0].id;

    const { rows: tokens } = await pool.query(
      'SELECT fcm_token FROM device_tokens WHERE user_id = $1',
      [user.id]
    );

    if (tokens.length === 0) {
      await pool.query(
        `INSERT INTO notifications (alert_id, delivery_status, error) VALUES ($1, 'failed', $2)`,
        [alertId, 'No device token registered']
      );
      continue;
    }

    for (const { fcm_token: token } of tokens) {
      const notif = await pool.query(
        `INSERT INTO notifications (alert_id, delivery_status) VALUES ($1, 'pending') RETURNING id`,
        [alertId]
      );
      const notifId = notif.rows[0].id;

      try {
        const messageId = await sendPush(token, {
          title: dbEvent.title,
          body: message,
          data: { eventId: String(dbEvent.id), category, severity },
        });
        await pool.query(
          `UPDATE notifications SET delivery_status = 'sent', fcm_message_id = $1, sent_at = now() WHERE id = $2`,
          [messageId, notifId]
        );
      } catch (err) {
        await pool.query(
          `UPDATE notifications SET delivery_status = 'failed', error = $1 WHERE id = $2`,
          [err.message, notifId]
        );
      }
    }
  }

  return { newEvent: true, event: dbEvent, alertsCreated };
}

module.exports = { processEvent };
