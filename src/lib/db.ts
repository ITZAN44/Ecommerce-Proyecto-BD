import { Pool } from 'pg';
import * as dotenv from 'dotenv';

dotenv.config();

// TLS opcional. Los proveedores gestionados (Neon, Render, RDS) exigen conexion cifrada;
// el Postgres local en Docker no tiene TLS, por eso el valor por defecto es desactivado.
// DB_SSL=true                        -> activa TLS validando el certificado del servidor.
// DB_SSL_REJECT_UNAUTHORIZED=false   -> escotilla para certificados autofirmados.
const sslEnabled = process.env.DB_SSL === 'true';
const ssl = sslEnabled
  ? { rejectUnauthorized: process.env.DB_SSL_REJECT_UNAUTHORIZED !== 'false' }
  : undefined;

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432'),
  database: process.env.DB_NAME || 'ecommerce_db',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD,
  ssl,
  max: 20,
  idleTimeoutMillis: 30000,
  // Los proveedores con suspension por inactividad tardan varios segundos en despertar,
  // muy por encima de los 2s que bastaban contra el Postgres local.
  connectionTimeoutMillis: parseInt(process.env.DB_CONNECTION_TIMEOUT_MS || '15000'),
});

console.log('🔌 Configuración de PostgreSQL:', {
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  ssl: sslEnabled
});

pool.on('connect', () => {
  console.log('✅ Conectado a PostgreSQL');
});

// Este handler se dispara con clientes ociosos del pool (p. ej. cuando el proveedor
// cierra la conexion por inactividad). Matar el proceso aqui tumbaba el servidor SSR
// entero por un error recuperable: el pool descarta el cliente roto y abre otro.
pool.on('error', (err) => {
  console.error('❌ Error inesperado en un cliente ocioso de PostgreSQL:', err);
});

export async function query(text: string, params?: any[]) {
  const start = Date.now();
  try {
    const res = await pool.query(text, params);
    const duration = Date.now() - start;
    console.log('📊 Query ejecutada', { text, duration, rows: res.rowCount });
    return res;
  } catch (error) {
    console.error('❌ Error en query:', { text, error });
    throw error;
  }
}

export async function getClient() {
  const client = await pool.connect();
  const query = client.query.bind(client);
  const release = client.release.bind(client);

  const timeout = setTimeout(() => {
    console.error('⚠️ Cliente no liberado después de 5 segundos');
  }, 5000);

  client.release = () => {
    clearTimeout(timeout);
    client.release = release;
    return release();
  };

  return client;
}

export default pool;
