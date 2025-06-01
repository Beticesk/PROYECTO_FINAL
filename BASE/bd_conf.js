// db_config.js
const { Pool } = require('pg');

// Configura los detalles de tu conexión a PostgreSQL
// Es MEJOR usar variables de entorno para esto en producción
const pool = new Pool({
  user: 'postgres',      // Reemplaza con tu usuario de PostgreSQL
  host: 'localhost',                // O la IP de tu servidor de BD
  database: 'pos_proyecto',     // Reemplaza con el nombre de tu BD
  password: '159753', // Reemplaza con tu contraseña
  port: 5432,                       // Puerto por defecto de PostgreSQL
});

pool.on('connect', () => {
  console.log('Conectado a la base de datos PostgreSQL!');
});

pool.on('error', (err) => {
  console.error('Error inesperado en el cliente de la base de datos', err);
  process.exit(-1);
});

module.exports = {
  query: (text, params) => pool.query(text, params),
};