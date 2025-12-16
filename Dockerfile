# ============================================
# STAGE 1: Build - Compilar la aplicación
# ============================================
FROM node:20-alpine AS builder

WORKDIR /app

# Copiar solo package files primero (aprovecha cache de Docker)
COPY package*.json ./

# Instalar TODAS las dependencias (incluidas devDependencies para build)
RUN npm ci

# Copiar el código fuente
COPY . .

# Compilar la aplicación Astro para producción
RUN npm run build

# ============================================
# STAGE 2: Production - Imagen final ligera
# ============================================
FROM node:20-alpine AS production

# Crear usuario no-root por seguridad
RUN addgroup -g 1001 -S nodejs && \
    adduser -S astro -u 1001

WORKDIR /app

# Copiar solo package files
COPY package*.json ./

# Instalar SOLO dependencias de producción
RUN npm ci --only=production && \
    npm cache clean --force

# Copiar el build desde la etapa anterior
COPY --from=builder --chown=astro:nodejs /app/dist ./dist

# Cambiar a usuario no-root
USER astro

# Exponer puerto
EXPOSE 4321

# Variables de entorno por defecto (serán sobrescritas)
ENV NODE_ENV=production \
    HOST=0.0.0.0 \
    PORT=4321

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD node -e "require('http').get('http://localhost:4321/api/analytics/dashboard', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Comando para producción
CMD ["node", "./dist/server/entry.mjs"]
