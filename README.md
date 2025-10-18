# My Website

A personal website built with D (vibe.d framework).

## Tech Stack

- **Backend**: [D language](https://dlang.org/) with [vibe.d](https://github.com/vibe-d/vibe.d) framework
- **Database**: MongoDB
- **Frontend**: HTML, CSS (Bootstrap), JavaScript
- **Template Engine**: Diet templates
- **Deployment**: Docker & Docker Compose

## Quick Start

### 1. Clone the repository

```bash
git clone https://github.com/kirillsaidov/mywebsite
cd mywebsite
```

### 2. Configure environment variables

Copy the example environment file and configure it:

```bash
cp .env.example .env
```

Edit `.env` with your settings:

```env
# API Configuration
API_KEY=your-secret-api-key-here

# Web Server Configuration
BIND_PORT=8081
BIND_ADDRESS=0.0.0.0

# MongoDB Configuration
MONGO_PORT=27018
MONGO_URI=mongodb://admin:password@mongo:27017/mywebsite?authSource=admin
MONGO_ROOT_USERNAME=admin
MONGO_ROOT_PASSWORD=change-this-password
MONGO_DB_NAME=mywebsite
```

### 3. Deploy with Docker Compose

```bash
# build and start all services
docker compose up -d

# view logs
docker compose logs -f

# check status
docker compose ps

# stop services
docker compose down

# stop and remove volumes (deletes database data)
docker compose down -v
```

## API Documentation

Full API documentation is available in [API.md](API.md).

## Using with Nginx reverse proxy

Example nginx configuration:

```nginx
server {
    listen 80;
    server_name yourdomain.com;

    location / {
        proxy_pass http://localhost:8081;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## Database Backup

### Backup MongoDB

```bash
# Create backup
docker exec mywebsite-mongo mongodump \
  --username admin \
  --password your-password \
  --authenticationDatabase admin \
  --out /data/backup

# Copy backup to host
docker cp mywebsite-mongo:/data/backup ./mongodb-backup
```

### Restore MongoDB

```bash
# Copy backup to container
docker cp ./mongodb-backup mywebsite-mongo:/data/backup

# Restore
docker exec mywebsite-mongo mongorestore \
  --username admin \
  --password your-password \
  --authenticationDatabase admin \
  /data/backup
```

## LICENSE
MIT.

