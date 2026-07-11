FROM node:20-alpine AS base

WORKDIR /app

COPY package.json ./
RUN npm install --omit=dev

COPY src ./src

RUN addgroup -g 1001 -S app && adduser -S app -u 1001 -G app
USER app

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/api/health',r=>process.exit(r.statusCode===200?0:1)).on('error',()=>process.exit(1))"

CMD ["node", "src/server.js"]
