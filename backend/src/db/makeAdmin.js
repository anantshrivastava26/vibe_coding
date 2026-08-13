require('dotenv').config();
const { pool } = require('../config/db');

// Usage: npm run make-admin -- someone@example.com
async function makeAdmin() {
  const email = process.argv[2];
  if (!email) {
    console.error('Usage: npm run make-admin -- <email>');
    process.exit(1);
  }

  const { rows } = await pool.query(
    `UPDATE users SET role = 'admin' WHERE email = $1 RETURNING id, email, role`,
    [email]
  );

  if (rows.length === 0) {
    console.error(`No user found with email ${email}. Register in the app first.`);
    process.exit(1);
  }

  console.log(`Promoted ${rows[0].email} to ${rows[0].role}.`);
  await pool.end();
}

makeAdmin().catch((err) => {
  console.error(err);
  process.exit(1);
});
