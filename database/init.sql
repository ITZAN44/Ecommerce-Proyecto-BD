-- ============================================
-- SCRIPT DE INICIALIZACIÓN AUTOMÁTICA
-- Se ejecuta cuando Docker crea el contenedor
-- ============================================

\echo '🚀 Iniciando configuración de base de datos...'

-- CARGAR TUS DATOS REALES COMPLETOS
\echo '📦 Cargando tu base de datos completa...'
\i /docker-entrypoint-initdb.d/backup_bd_real.sql

\echo '✅ ¡Base de datos configurada exitosamente!'
\echo '🎉 E-commerce con tus datos reales listos'
