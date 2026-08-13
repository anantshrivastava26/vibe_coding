CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  firebase_uid TEXT UNIQUE NOT NULL,
  email TEXT NOT NULL,
  display_name TEXT,
  role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'admin')),
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  location_label TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS device_tokens (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  fcm_token TEXT UNIQUE NOT NULL,
  platform TEXT NOT NULL DEFAULT 'android',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS disaster_events (
  id SERIAL PRIMARY KEY,
  source TEXT NOT NULL CHECK (source IN ('usgs', 'eonet', 'manual')),
  external_id TEXT NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('earthquake', 'flood', 'cyclone', 'wildfire', 'landslide', 'other')),
  severity TEXT NOT NULL CHECK (severity IN ('low', 'moderate', 'high', 'critical')),
  title TEXT NOT NULL,
  description TEXT,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  affected_radius_km DOUBLE PRECISION NOT NULL,
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (source, external_id)
);

CREATE TABLE IF NOT EXISTS alerts (
  id SERIAL PRIMARY KEY,
  event_id INTEGER NOT NULL REFERENCES disaster_events(id) ON DELETE CASCADE,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  severity TEXT NOT NULL CHECK (severity IN ('low', 'moderate', 'high', 'critical')),
  message TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (event_id, user_id)
);

CREATE TABLE IF NOT EXISTS notifications (
  id SERIAL PRIMARY KEY,
  alert_id INTEGER NOT NULL REFERENCES alerts(id) ON DELETE CASCADE,
  delivery_status TEXT NOT NULL DEFAULT 'pending' CHECK (delivery_status IN ('pending', 'sent', 'failed')),
  fcm_message_id TEXT,
  error TEXT,
  sent_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS emergency_instructions (
  category TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  instructions TEXT NOT NULL
);

INSERT INTO emergency_instructions (category, title, instructions) VALUES
  ('earthquake', 'Earthquake Safety', 'Drop, cover, and hold on. Stay away from windows and heavy furniture. If indoors, stay inside until shaking stops. If outdoors, move to an open area away from buildings and power lines.'),
  ('flood', 'Flood Safety', 'Move to higher ground immediately. Avoid walking or driving through flood waters. Disconnect electrical appliances. Keep emergency supplies and important documents ready to go.'),
  ('cyclone', 'Cyclone / Severe Storm Safety', 'Stay indoors, away from windows. Secure loose outdoor objects. Keep an emergency kit with water, food, flashlight, and radio. Follow evacuation orders if issued.'),
  ('wildfire', 'Wildfire Safety', 'Evacuate immediately if instructed. Close all windows and doors to slow smoke infiltration. Wear an N95 mask if smoke is present. Keep a "go bag" ready with essentials.'),
  ('landslide', 'Landslide Safety', 'Move away from the path of a landslide as quickly as possible. Watch for signs of ground movement, cracking, or tilting trees/poles. Avoid river valleys and low-lying areas during heavy rain.'),
  ('other', 'General Emergency Safety', 'Stay informed via official channels. Keep an emergency kit ready. Follow instructions from local authorities and evacuate if advised.')
ON CONFLICT (category) DO NOTHING;
