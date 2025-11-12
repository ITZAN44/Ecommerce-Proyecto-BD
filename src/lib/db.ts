import { Pool } from 'pg';
import * as dotenv from 'dotenv';

// Cargar variables de entorno
dotenv.config();

// Configuración de la conexión a PostgreSQL
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432'),
  database: process.env.DB_NAME || 'ecommerce_db',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD,
  max: 20, // Máximo de conexiones en el pool
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

console.log('🔌 Configuración de PostgreSQL:', {
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  database: process.env.DB_NAME,
  user: process.env.DB_USER
});

// Probar la conexión al iniciar
pool.on('connect', () => {
  console.log('✅ Conectado a PostgreSQL');
});

pool.on('error', (err) => {
  console.error('❌ Error inesperado en PostgreSQL:', err);
  process.exit(-1);
});

/**
 * Ejecuta una consulta SQL
 * @param text - Query SQL
 * @param params - Parámetros de la query
 */
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

/**
 * Obtiene un cliente del pool para transacciones
 */
export async function getClient() {
  const client = await pool.connect();
  const query = client.query.bind(client);
  const release = client.release.bind(client);
  
  // Agregar timeout de 5 segundos
  const timeout = setTimeout(() => {
    console.error('⚠️ Cliente no liberado después de 5 segundos');
  }, 5000);
  
  // Override release para limpiar el timeout
  client.release = () => {
    clearTimeout(timeout);
    client.release = release;
    return release();
  };
  
  return client;
}

export default pool;
