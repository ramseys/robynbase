# Kamal Deployment Plan for RobynBase

## Executive Summary

This document outlines a deployment plan using **Kamal** (formerly MRSK), the official Rails-recommended tool for zero-downtime Docker deployments. Kamal was created by 37signals and is the spiritual successor to Capistrano for the containerized era.

**Why Kamal?**
- ✅ Official Rails recommendation (ships with Rails 7.1+)
- ✅ Zero-downtime deployments built-in
- ✅ Automatic SSL via Let's Encrypt
- ✅ Simple `config/deploy.yml` configuration (like Capistrano)
- ✅ No orchestration complexity (no Kubernetes needed)
- ✅ Perfect for single-server or multi-server deployments
- ✅ Rails-native with built-in asset handling

---

## Table of Contents

1. [What is Kamal?](#what-is-kamal)
2. [Architecture Overview](#architecture-overview)
3. [Installation](#installation)
4. [Configuration Files](#configuration-files)
5. [Dockerfile for Kamal](#dockerfile-for-kamal)
6. [Deployment Workflow](#deployment-workflow)
7. [Accessories (MySQL, Redis)](#accessories-mysql-redis)
8. [Storage and Volumes](#storage-and-volumes)
9. [SSL/TLS with Let's Encrypt](#ssltls-with-lets-encrypt)
10. [CI/CD Integration](#cicd-integration)
11. [Migration from Capistrano](#migration-from-capistrano)
12. [Common Commands](#common-commands)
13. [Rollback Strategy](#rollback-strategy)
14. [Monitoring and Logging](#monitoring-and-logging)
15. [Timeline and Phases](#timeline-and-phases)
16. [Appendix: Complete Configurations](#appendix-complete-configurations)

---

## What is Kamal?

### Overview

**Kamal** is a deployment tool that uses Docker containers to deploy Rails applications with zero downtime. It was created by DHH and 37signals, and is the deployment method used for Hey.com and Basecamp.

### Key Features

1. **Zero-Downtime Deployments**: Uses health checks and rolling restarts
2. **Traefik Integration**: Built-in reverse proxy with automatic SSL
3. **Simple Config**: Single `config/deploy.yml` file (familiar to Capistrano users)
4. **Accessories**: Manages MySQL, Redis, and other services
5. **Multi-Server**: Deploy across multiple servers easily
6. **Asset Handling**: Rails asset precompilation built-in
7. **Secrets Management**: Secure environment variable handling

### How It Works

```
┌─────────────────────────────────────────────┐
│  Developer Machine                          │
│  $ kamal deploy                             │
└────────────────┬────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────┐
│  Container Registry (GHCR/Docker Hub)       │
│  Stores Docker images                       │
└────────────────┬────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────┐
│  Production Server (66.228.36.37)           │
│  ┌─────────────────────────────────────┐   │
│  │  Traefik (Reverse Proxy)            │   │
│  │  - Port 80/443                      │   │
│  │  - Automatic SSL (Let's Encrypt)    │   │
│  └──────────────┬──────────────────────┘   │
│                 │                           │
│  ┌──────────────┴──────────────────────┐   │
│  │  RobynBase App Containers           │   │
│  │  (Rolling deployment, health checks)│   │
│  └──────────────┬──────────────────────┘   │
│                 │                           │
│  ┌──────────────┴──────────────────────┐   │
│  │  Accessories                        │   │
│  │  - MySQL (container)                │   │
│  │  - Redis (container)                │   │
│  └─────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
```

---

## Architecture Overview

### Services

| Service | Type | Purpose |
|---------|------|---------|
| **Traefik** | Kamal-managed | Reverse proxy, SSL termination, load balancing |
| **Rails App** | Primary service | Puma web server, application logic |
| **MySQL** | Accessory | Database server |
| **Redis** | Accessory | Action Cable, caching (future) |

### Deployment Flow

1. **Build**: Kamal builds Docker image locally (or via CI)
2. **Push**: Image pushed to container registry (GHCR recommended)
3. **Deploy**: Kamal SSHs to server and:
   - Pulls new image
   - Starts new container
   - Waits for health check to pass
   - Routes traffic to new container
   - Stops old container (zero downtime!)
4. **Cleanup**: Prunes old images

---

## Installation

### Prerequisites

**On Your Development Machine:**
```bash
# Install Kamal gem
gem install kamal

# Or add to Gemfile (Rails 7.1+ includes it)
bundle add kamal
```

**On Production Server (66.228.36.37):**
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add deploy user to docker group
sudo usermod -aG docker ramseys

# Install Docker Compose plugin
sudo apt-get update
sudo apt-get install docker-compose-plugin

# Verify installation
docker --version
docker compose version
```

### Initial Setup

```bash
# In your Rails app directory
kamal init

# This creates:
# - config/deploy.yml
# - .env.sample (for secrets)
```

---

## Configuration Files

### 1. config/deploy.yml

This is the main Kamal configuration file (similar to Capistrano's `config/deploy.rb`):

```yaml
# config/deploy.yml

# Application name
service: robynbase

# Docker image configuration
image: ramseys/robynbase

# Container registry
registry:
  server: ghcr.io
  username: ramseys
  password:
    - KAMAL_REGISTRY_PASSWORD

# Servers configuration
servers:
  web:
    hosts:
      - 66.228.36.37
    labels:
      traefik.http.routers.robynbase.rule: Host(`robynbase.com`) || Host(`www.robynbase.com`)
      traefik.http.routers.robynbase.entrypoints: websecure
      traefik.http.routers.robynbase.tls.certresolver: letsencrypt
    options:
      # Mount persistent volumes
      volume:
        - "/var/lib/robynbase/album-art:/rails/public/images/album-art"
        - "/var/lib/robynbase/storage:/rails/active-storage-files"

# SSH configuration
ssh:
  user: ramseys

# Builder configuration (for multi-platform builds)
builder:
  arch: amd64
  remote:
    arch: amd64

# Traefik reverse proxy configuration
traefik:
  options:
    publish:
      - "443:443"
    volume:
      - "/letsencrypt:/letsencrypt"
  args:
    entryPoints.web.address: ":80"
    entryPoints.websecure.address: ":443"
    entryPoints.web.http.redirections.entryPoint.to: websecure
    entryPoints.web.http.redirections.entryPoint.scheme: https
    entryPoints.web.http.redirections.entrypoint.permanent: true
    certificatesResolvers.letsencrypt.acme.email: "admin@robynbase.com"
    certificatesResolvers.letsencrypt.acme.storage: "/letsencrypt/acme.json"
    certificatesResolvers.letsencrypt.acme.httpchallenge: true
    certificatesResolvers.letsencrypt.acme.httpchallenge.entrypoint: web

# Environment variables
env:
  clear:
    RAILS_LOG_TO_STDOUT: "1"
    RAILS_SERVE_STATIC_FILES: "false"
  secret:
    - RAILS_MASTER_KEY
    - SECRET_KEY_BASE
    - DATABASE_PASSWORD

# Health check configuration
healthcheck:
  path: /up
  port: 3000
  max_attempts: 10
  interval: 10s

# Accessories (databases, Redis, etc.)
accessories:
  mysql:
    image: mysql:8.0
    host: 66.228.36.37
    port: 3306
    env:
      clear:
        MYSQL_DATABASE: robynbase_production
      secret:
        - MYSQL_ROOT_PASSWORD
    directories:
      - data:/var/lib/mysql
    options:
      health-cmd: "mysqladmin ping -h localhost"
      health-interval: 10s
      health-timeout: 5s
      health-retries: 5

  redis:
    image: redis:7-alpine
    host: 66.228.36.37
    port: 6379
    directories:
      - data:/data
    options:
      health-cmd: "redis-cli ping"
      health-interval: 10s
      health-timeout: 3s
      health-retries: 5

# Asset path for precompilation
asset_path: /rails/public/assets

# Boot command (migrations, etc.)
boot:
  limit: 10 # Maximum boot time in seconds
  wait: 2   # Seconds between checks

# Retain last 5 versions for rollback
retain_containers: 5
```

### 2. .env (Git-ignored)

Create `.env` file with your secrets (never commit this!):

```bash
# .env

# Container registry
KAMAL_REGISTRY_PASSWORD=ghp_your_github_token

# Rails secrets
RAILS_MASTER_KEY=your_master_key_from_config
SECRET_KEY_BASE=generate_with_rails_secret

# Database
DATABASE_PASSWORD=secure_database_password
MYSQL_ROOT_PASSWORD=secure_root_password
```

### 3. .kamal/secrets (Alternative)

For more complex secret management:

```bash
# .kamal/secrets

#!/bin/bash

# Load from password manager, AWS Secrets Manager, etc.
echo "KAMAL_REGISTRY_PASSWORD=$(op read op://vault/github-token/password)"
echo "RAILS_MASTER_KEY=$(cat config/master.key)"
echo "SECRET_KEY_BASE=$(rails secret)"
echo "DATABASE_PASSWORD=$(op read op://vault/mysql/password)"
```

Make it executable:
```bash
chmod +x .kamal/secrets
```

---

## Dockerfile for Kamal

Kamal works best with a **multi-stage Dockerfile** that produces a lean production image:

```dockerfile
# Dockerfile

# syntax=docker/dockerfile:1

#############
# Stage 1: Base
#############
ARG RUBY_VERSION=3.4.4
FROM ruby:$RUBY_VERSION-slim AS base

WORKDIR /rails

# Install base dependencies
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      curl \
      libjemalloc2 \
      default-mysql-client \
      imagemagick && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Set production environment
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test"

#############
# Stage 2: Build
#############
FROM base AS build

# Install build dependencies
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential \
      default-libmysqlclient-dev \
      git \
      pkg-config \
      curl && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install Node.js and Yarn
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g yarn && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install Ruby gems
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

# Install Node packages
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

# Copy application code
COPY . .

# Build JavaScript and CSS assets
RUN yarn build && \
    yarn build:css

# Precompile Rails assets (bootsnap for faster boot)
RUN SECRET_KEY_BASE=DUMMY bundle exec bootsnap precompile --gemfile app/ lib/ && \
    SECRET_KEY_BASE=DUMMY bundle exec rails assets:precompile

#############
# Stage 3: Final
#############
FROM base

# Copy built artifacts from build stage
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /rails /rails

# Create non-root user
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp
USER rails:rails

# Entrypoint prepares database
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Expose port 3000
EXPOSE 3000

# Start Puma server
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
```

### bin/docker-entrypoint

Create an entrypoint script for database preparation:

```bash
#!/bin/bash
# bin/docker-entrypoint

set -e

# Remove pre-existing puma/passenger server PID
rm -f /rails/tmp/pids/server.pid

# Run database migrations if needed (for first web container only)
if [ "${KAMAL_ROLE}" = "web" ] && [ "${KAMAL_CONTAINER_NAME}" = "robynbase-web-1" ]; then
  echo "Running database migrations..."
  bundle exec rails db:migrate 2>/dev/null || echo "No migrations to run"
fi

# Execute the main command
exec "$@"
```

Make it executable:
```bash
chmod +x bin/docker-entrypoint
```

---

## Deployment Workflow

### First-Time Setup

```bash
# 1. Initialize Kamal configuration
kamal init

# 2. Edit config/deploy.yml with your settings
# (see Configuration Files section above)

# 3. Set up environment secrets
# Create .env file with your secrets

# 4. Setup server (installs Docker, creates directories)
kamal server bootstrap

# 5. Setup accessories (MySQL, Redis)
kamal accessory boot mysql
kamal accessory boot redis

# 6. Deploy application for the first time
kamal setup

# 7. Create and migrate database
kamal app exec --reuse 'bin/rails db:create db:migrate'
```

### Regular Deployments

```bash
# Single command deployment with zero downtime!
kamal deploy

# What happens:
# 1. Builds Docker image locally
# 2. Pushes to container registry (GHCR)
# 3. Pulls image on server
# 4. Starts new container
# 5. Waits for health check (/up endpoint)
# 6. Routes traffic to new container
# 7. Stops old container
# 8. Cleans up old images
```

### Deployment with Pre-checks

```bash
# Build image first (test build locally)
kamal build

# Push image to registry
kamal push

# Run pre-deployment commands (migrations, etc.)
kamal deploy --skip-push

# Or do it all in one step
kamal deploy
```

---

## Accessories (MySQL, Redis)

### MySQL Accessory

Kamal manages MySQL as an "accessory" - a separate container that persists across deployments.

**Configuration** (already in `config/deploy.yml` above):
```yaml
accessories:
  mysql:
    image: mysql:8.0
    host: 66.228.36.37
    port: 3306
    env:
      clear:
        MYSQL_DATABASE: robynbase_production
      secret:
        - MYSQL_ROOT_PASSWORD
    directories:
      - data:/var/lib/mysql
```

**Commands:**
```bash
# Start MySQL
kamal accessory boot mysql

# Stop MySQL
kamal accessory stop mysql

# Restart MySQL
kamal accessory restart mysql

# View MySQL logs
kamal accessory logs mysql

# Execute MySQL commands
kamal accessory exec mysql mysql -u root -p

# Backup database
kamal accessory exec mysql \
  mysqldump -u root -p robynbase_production > backup.sql
```

### Redis Accessory

**Configuration** (already in `config/deploy.yml` above):
```yaml
accessories:
  redis:
    image: redis:7-alpine
    host: 66.228.36.37
    port: 6379
    directories:
      - data:/data
```

**Commands:**
```bash
# Start Redis
kamal accessory boot redis

# View Redis logs
kamal accessory logs redis

# Execute Redis commands
kamal accessory exec redis redis-cli ping
```

### Database Configuration

Update `config/database.yml` to use Docker networking:

```yaml
# config/database.yml

production:
  adapter: mysql2
  encoding: utf8mb3
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  database: robynbase_production
  username: root
  password: <%= ENV['DATABASE_PASSWORD'] %>
  host: <%= ENV.fetch('DATABASE_HOST', '66.228.36.37') %>
  port: 3306
```

### Redis Configuration

Update `config/cable.yml`:

```yaml
# config/cable.yml

production:
  adapter: redis
  url: <%= ENV.fetch("REDIS_URL", "redis://66.228.36.37:6379/1") %>
  channel_prefix: robynbase_production
```

---

## Storage and Volumes

### Persistent Storage Strategy

Kamal uses **host volumes** for persistent data:

**Volumes to Create on Server:**
```bash
# SSH to server
ssh ramseys@66.228.36.37

# Create directories
sudo mkdir -p /var/lib/robynbase/album-art
sudo mkdir -p /var/lib/robynbase/storage
sudo chown -R ramseys:ramseys /var/lib/robynbase
```

**Volume Mounts** (in `config/deploy.yml`):
```yaml
servers:
  web:
    options:
      volume:
        - "/var/lib/robynbase/album-art:/rails/public/images/album-art"
        - "/var/lib/robynbase/storage:/rails/active-storage-files"
```

### Migrating Existing Data

```bash
# On production server, copy from Capistrano paths to Kamal paths
sudo cp -a /var/www/robynbase/shared/public/images/album-art/* \
  /var/lib/robynbase/album-art/

sudo cp -a /var/www/robynbase/shared/active-storage-files/* \
  /var/lib/robynbase/storage/
```

### Active Storage Configuration

Update `config/storage.yml` for production:

```yaml
# config/storage.yml

production:
  service: Disk
  root: <%= ENV.fetch("ACTIVE_STORAGE_ROOT", "/rails/active-storage-files") %>
```

---

## SSL/TLS with Let's Encrypt

### Automatic SSL Configuration

Kamal uses **Traefik** with automatic Let's Encrypt SSL:

**Configuration** (already in `config/deploy.yml`):
```yaml
traefik:
  args:
    certificatesResolvers.letsencrypt.acme.email: "admin@robynbase.com"
    certificatesResolvers.letsencrypt.acme.storage: "/letsencrypt/acme.json"
    certificatesResolvers.letsencrypt.acme.httpchallenge: true
    certificatesResolvers.letsencrypt.acme.httpchallenge.entrypoint: web

servers:
  web:
    labels:
      traefik.http.routers.robynbase.tls.certresolver: letsencrypt
```

**What Happens:**
1. Traefik automatically requests SSL cert from Let's Encrypt
2. Certificate stored in `/letsencrypt/acme.json`
3. Auto-renewal every 60 days
4. HTTP automatically redirects to HTTPS

**DNS Requirements:**
- Point `robynbase.com` and `www.robynbase.com` to `66.228.36.37`
- Wait for DNS propagation before first deployment

---

## CI/CD Integration

### GitHub Actions with Kamal

Create `.github/workflows/deploy.yml`:

```yaml
# .github/workflows/deploy.yml

name: Deploy with Kamal

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.4.4
          bundler-cache: true

      - name: Install Kamal
        run: gem install kamal

      - name: Set up SSH
        uses: webfactory/ssh-agent@v0.8.0
        with:
          ssh-private-key: ${{ secrets.SSH_PRIVATE_KEY }}

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Login to GitHub Container Registry
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Deploy with Kamal
        env:
          KAMAL_REGISTRY_PASSWORD: ${{ secrets.GITHUB_TOKEN }}
          RAILS_MASTER_KEY: ${{ secrets.RAILS_MASTER_KEY }}
          SECRET_KEY_BASE: ${{ secrets.SECRET_KEY_BASE }}
          DATABASE_PASSWORD: ${{ secrets.DATABASE_PASSWORD }}
          MYSQL_ROOT_PASSWORD: ${{ secrets.MYSQL_ROOT_PASSWORD }}
        run: |
          kamal deploy

      - name: Notify on success
        if: success()
        run: echo "Deployment successful!"

      - name: Notify on failure
        if: failure()
        run: echo "Deployment failed!"
```

### Required GitHub Secrets

Add these to your GitHub repository settings (Settings → Secrets and variables → Actions):

- `SSH_PRIVATE_KEY` - SSH private key for server access
- `RAILS_MASTER_KEY` - Rails master key
- `SECRET_KEY_BASE` - Rails secret key base
- `DATABASE_PASSWORD` - MySQL password
- `MYSQL_ROOT_PASSWORD` - MySQL root password

---

## Migration from Capistrano

### Migration Strategy

**Phase 1: Parallel Running** (Recommended)
1. Keep Capistrano running
2. Set up Kamal on a new subdomain or staging server
3. Test thoroughly
4. Switch DNS to Kamal server
5. Decommission Capistrano setup

**Phase 2: In-Place Migration** (Riskier)
1. Take full backup of production server
2. Stop Capistrano/Passenger
3. Install Docker and Kamal
4. Migrate data to Kamal volumes
5. Deploy with Kamal
6. Test and verify

### Step-by-Step Migration

#### 1. Backup Everything

```bash
# On production server
ssh ramseys@66.228.36.37

# Backup database
mysqldump -u root -p robynbase_production | gzip > ~/robynbase_backup_$(date +%Y%m%d).sql.gz

# Backup files
tar czf ~/robynbase_files_$(date +%Y%m%d).tar.gz \
  /var/www/robynbase/shared/public/images/album-art \
  /var/www/robynbase/shared/active-storage-files

# Download backups to local machine
scp ramseys@66.228.36.37:~/robynbase_*.gz ~/backups/
```

#### 2. Install Docker on Server

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker ramseys

# Log out and back in for group changes to take effect
exit
ssh ramseys@66.228.36.37

# Verify Docker
docker --version
```

#### 3. Setup Kamal Locally

```bash
# In your Rails app
gem install kamal
kamal init

# Edit config/deploy.yml (see Configuration section)
# Create .env with secrets
```

#### 4. Bootstrap Server

```bash
# Setup server with Docker containers
kamal server bootstrap

# Setup accessories (MySQL, Redis)
kamal accessory boot mysql
kamal accessory boot redis
```

#### 5. Migrate Data

```bash
# Create volume directories
ssh ramseys@66.228.36.37 "mkdir -p /var/lib/robynbase/{album-art,storage}"

# Copy data from Capistrano paths to Kamal paths
ssh ramseys@66.228.36.37 << 'ENDSSH'
  cp -a /var/www/robynbase/shared/public/images/album-art/* /var/lib/robynbase/album-art/
  cp -a /var/www/robynbase/shared/active-storage-files/* /var/lib/robynbase/storage/
ENDSSH

# Import database to MySQL accessory
gunzip -c robynbase_backup_20251115.sql.gz | \
  kamal accessory exec mysql mysql -u root -p robynbase_production
```

#### 6. First Deployment

```bash
# Deploy application
kamal setup

# This will:
# - Build Docker image
# - Push to registry
# - Pull on server
# - Start Traefik
# - Start app containers
# - Request SSL cert
```

#### 7. Verify Deployment

```bash
# Check all containers are running
kamal app details

# Check logs
kamal app logs

# Test the application
curl https://robynbase.com/health
```

#### 8. Decommission Capistrano (After Verification)

```bash
# Stop Passenger
sudo systemctl stop passenger

# Disable Passenger from starting on boot
sudo systemctl disable passenger

# Optionally remove old deployment directory
# (ONLY after verifying Kamal works!)
# sudo rm -rf /var/www/robynbase
```

### Rollback Plan

If something goes wrong:

```bash
# Stop Kamal services
kamal app stop
kamal traefik stop

# Restart Passenger/Capistrano
sudo systemctl start passenger

# Restore database if needed
gunzip -c robynbase_backup_20251115.sql.gz | mysql -u root -p robynbase_production
```

---

## Common Commands

### Deployment Commands

```bash
# Full deployment (build, push, deploy)
kamal deploy

# Deploy without building (use existing image)
kamal deploy --skip-push

# Build image only
kamal build

# Push image to registry
kamal push

# Setup everything (first time)
kamal setup
```

### App Management

```bash
# Check app status
kamal app details

# View logs
kamal app logs
kamal app logs --since 1h
kamal app logs --follow

# Execute commands in app container
kamal app exec 'rails console'
kamal app exec 'rails db:migrate'
kamal app exec --reuse 'bin/rails db:seed'

# Restart app
kamal app restart

# Stop app
kamal app stop

# Start app
kamal app start

# SSH into app container
kamal app exec --interactive bash
```

### Accessory Management

```bash
# Boot accessory
kamal accessory boot mysql
kamal accessory boot redis

# Restart accessory
kamal accessory restart mysql

# Stop accessory
kamal accessory stop mysql

# View accessory logs
kamal accessory logs mysql

# Execute commands in accessory
kamal accessory exec mysql mysql -u root -p
```

### Server Management

```bash
# Bootstrap server (install Docker)
kamal server bootstrap

# View server details
kamal details

# Prune old images and containers
kamal prune
```

### Traefik Management

```bash
# Boot Traefik
kamal traefik boot

# Restart Traefik
kamal traefik restart

# View Traefik logs
kamal traefik logs

# Stop Traefik
kamal traefik stop
```

---

## Rollback Strategy

### Image-Based Rollback

Kamal keeps the last 5 container images (configurable):

```bash
# List recent deployments
kamal app containers

# Rollback to previous version
kamal rollback [VERSION]

# Example:
kamal rollback 20251115123456
```

### Manual Rollback

```bash
# 1. Stop current version
kamal app stop

# 2. List available images
docker images | grep robynbase

# 3. Start specific version
kamal app start --version abc123def456

# 4. Verify health check
kamal app details
```

### Database Rollback

**Important**: Rollbacks with database migrations require special care.

**Best Practice:**
1. Always backup database before migrations
2. Write reversible migrations (`up` and `down` methods)
3. Test rollbacks in staging first

**Rollback with Migrations:**
```bash
# Rollback last migration
kamal app exec 'rails db:rollback'

# Rollback multiple migrations
kamal app exec 'rails db:rollback STEP=3'

# Rollback to specific version
kamal app exec 'rails db:migrate:down VERSION=20231001125824'
```

---

## Monitoring and Logging

### Application Logs

```bash
# View recent logs
kamal app logs

# Follow logs in real-time
kamal app logs --follow

# View logs from last hour
kamal app logs --since 1h

# View logs from specific container
kamal app logs --container robynbase-web-1
```

### Accessory Logs

```bash
# MySQL logs
kamal accessory logs mysql --follow

# Redis logs
kamal accessory logs redis --follow
```

### Traefik Logs

```bash
# View Traefik access logs
kamal traefik logs

# Monitor traffic
kamal traefik logs --follow
```

### Health Checks

Kamal uses the `/up` endpoint for health checks.

**Create Health Check Endpoint:**

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # Health check endpoint for Kamal
  get "up" => "rails/health#show", as: :rails_health_check

  # ... rest of your routes
end
```

Rails 7.1+ includes this endpoint by default. If you're on an older version, create it:

```ruby
# app/controllers/health_controller.rb
class HealthController < ApplicationController
  def show
    # Check database connectivity
    ActiveRecord::Base.connection.execute("SELECT 1")

    # Check Redis connectivity (optional)
    Redis.new(url: ENV['REDIS_URL']).ping if ENV['REDIS_URL']

    render json: { status: "ok" }, status: :ok
  rescue => e
    render json: { status: "error", message: e.message }, status: :service_unavailable
  end
end
```

### Metrics and Monitoring

**Built-in Monitoring:**
```bash
# Container stats
ssh ramseys@66.228.36.37 "docker stats"

# Disk usage
ssh ramseys@66.228.36.37 "docker system df"
```

**External Monitoring (Recommended):**
- **AppSignal** - Rails APM
- **Scout APM** - Application performance
- **Datadog** - Infrastructure and APM
- **New Relic** - Full-stack observability

---

## Timeline and Phases

### Week 1: Preparation

**Goals:**
- [x] Install Kamal locally
- [x] Create `config/deploy.yml`
- [x] Create Dockerfile
- [x] Test local Docker build
- [x] Set up GitHub Container Registry

**Tasks:**
```bash
# Day 1-2: Setup
gem install kamal
kamal init
# Edit config/deploy.yml

# Day 3-4: Docker
# Create Dockerfile
docker build -t robynbase:test .

# Day 5: Registry
# Setup GHCR, test push/pull
```

### Week 2: Staging Deployment

**Goals:**
- [x] Deploy to staging server (or subdomain)
- [x] Test full deployment workflow
- [x] Verify SSL, accessories, volumes
- [x] Load test

**Tasks:**
```bash
# Setup staging server
kamal server bootstrap -d staging

# Deploy to staging
kamal setup -d staging

# Test thoroughly
```

### Week 3: Production Migration

**Goals:**
- [x] Backup production
- [x] Install Docker on production server
- [x] Migrate data to Kamal volumes
- [x] Deploy with Kamal
- [x] Verify all functionality

**Tasks:**
```bash
# Backup everything
# Install Docker
# Migrate data
# Deploy
kamal setup
```

### Week 4: Optimization & Monitoring

**Goals:**
- [x] Set up CI/CD pipeline
- [x] Configure monitoring
- [x] Optimize performance
- [x] Document runbooks
- [x] Train team

---

## Appendix: Complete Configurations

### A. Complete config/deploy.yml

```yaml
# config/deploy.yml

service: robynbase
image: ramseys/robynbase

registry:
  server: ghcr.io
  username: ramseys
  password:
    - KAMAL_REGISTRY_PASSWORD

servers:
  web:
    hosts:
      - 66.228.36.37
    labels:
      traefik.http.routers.robynbase.rule: Host(`robynbase.com`) || Host(`www.robynbase.com`)
      traefik.http.routers.robynbase.entrypoints: websecure
      traefik.http.routers.robynbase.tls.certresolver: letsencrypt
    options:
      volume:
        - "/var/lib/robynbase/album-art:/rails/public/images/album-art"
        - "/var/lib/robynbase/storage:/rails/active-storage-files"
      network: "robynbase"

ssh:
  user: ramseys

builder:
  arch: amd64
  remote:
    arch: amd64

traefik:
  options:
    publish:
      - "443:443"
      - "80:80"
    volume:
      - "/letsencrypt:/letsencrypt"
    network: "robynbase"
  args:
    entryPoints.web.address: ":80"
    entryPoints.websecure.address: ":443"
    entryPoints.web.http.redirections.entryPoint.to: websecure
    entryPoints.web.http.redirections.entryPoint.scheme: https
    entryPoints.web.http.redirections.entrypoint.permanent: true
    certificatesResolvers.letsencrypt.acme.email: "admin@robynbase.com"
    certificatesResolvers.letsencrypt.acme.storage: "/letsencrypt/acme.json"
    certificatesResolvers.letsencrypt.acme.httpchallenge: true
    certificatesResolvers.letsencrypt.acme.httpchallenge.entrypoint: web
    accesslog: true
    accesslog.format: json

env:
  clear:
    RAILS_LOG_TO_STDOUT: "1"
    RAILS_SERVE_STATIC_FILES: "false"
    DATABASE_HOST: "66.228.36.37"
    DATABASE_NAME: "robynbase_production"
    DATABASE_USERNAME: "root"
    REDIS_URL: "redis://66.228.36.37:6379/1"
    ACTIVE_STORAGE_ROOT: "/rails/active-storage-files"
  secret:
    - RAILS_MASTER_KEY
    - SECRET_KEY_BASE
    - DATABASE_PASSWORD

healthcheck:
  path: /up
  port: 3000
  max_attempts: 10
  interval: 10s

accessories:
  mysql:
    image: mysql:8.0
    host: 66.228.36.37
    port: 3306
    env:
      clear:
        MYSQL_DATABASE: robynbase_production
        MYSQL_CHARSET: utf8mb3
        MYSQL_COLLATION: utf8mb3_general_ci
      secret:
        - MYSQL_ROOT_PASSWORD
    files:
      - config/mysql/my.cnf:/etc/mysql/conf.d/custom.cnf
    directories:
      - data:/var/lib/mysql
    options:
      health-cmd: "mysqladmin ping -h localhost -u root -p$MYSQL_ROOT_PASSWORD"
      health-interval: 10s
      health-timeout: 5s
      health-retries: 5
      network: "robynbase"

  redis:
    image: redis:7-alpine
    host: 66.228.36.37
    port: 6379
    cmd: "redis-server --appendonly yes"
    directories:
      - data:/data
    options:
      health-cmd: "redis-cli ping"
      health-interval: 10s
      health-timeout: 3s
      health-retries: 5
      network: "robynbase"

asset_path: /rails/public/assets

retain_containers: 5

# Run database migrations before deploying
hooks:
  pre-deploy:
    - bundle exec rails db:migrate
```

### B. MySQL Configuration File

```ini
# config/mysql/my.cnf

[mysqld]
# Character set
character-set-server=utf8mb3
collation-server=utf8mb3_general_ci

# Storage engines
default-storage-engine=InnoDB
myisam-recover-options=BACKUP,FORCE

# Performance
max_connections=200
innodb_buffer_pool_size=512M
innodb_log_file_size=128M
innodb_flush_log_at_trx_commit=2
innodb_flush_method=O_DIRECT

# Logging
slow_query_log=1
slow_query_log_file=/var/log/mysql/slow-query.log
long_query_time=2
log_queries_not_using_indexes=1

# Binary logging (for backups/replication)
log_bin=/var/lib/mysql/mysql-bin
binlog_expire_logs_seconds=604800  # 7 days
max_binlog_size=100M

[client]
default-character-set=utf8mb3
```

### C. Complete Dockerfile

(See "Dockerfile for Kamal" section above for the complete multi-stage Dockerfile)

### D. Puma Configuration

```ruby
# config/puma.rb

# Number of worker processes
workers ENV.fetch("WEB_CONCURRENCY") { 2 }

# Number of threads per worker
max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
threads min_threads_count, max_threads_count

# Specifies the `port` that Puma will listen on
port ENV.fetch("PORT") { 3000 }

# Specifies the `environment`
environment ENV.fetch("RAILS_ENV") { "production" }

# Specifies the `pidfile`
pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }

# Allow puma to be restarted by `bin/rails restart`
plugin :tmp_restart

# Preload application for better performance
preload_app!

# Use jemalloc for better memory management
ENV['MALLOC_ARENA_MAX'] = '2'

before_fork do
  ActiveRecord::Base.connection_pool.disconnect! if defined?(ActiveRecord)
end

on_worker_boot do
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
end
```

### E. .dockerignore

```
# .dockerignore

.git
.github
.kamal
.env*
.bundle
log/*
tmp/*
.DS_Store
node_modules
coverage
*.swp
*.swo
*.log
.byebug_history
.rspec
.rubocop.yml
Capfile
config/deploy.rb
config/deploy/
lib/capistrano/
```

### F. Sample .env

```bash
# .env (NEVER COMMIT THIS FILE)

# Container Registry
KAMAL_REGISTRY_PASSWORD=ghp_yourgithubtoken

# Rails
RAILS_MASTER_KEY=your_master_key_from_config_master_key
SECRET_KEY_BASE=generate_with_rails_secret_command

# Database
DATABASE_PASSWORD=secure_database_password_here
MYSQL_ROOT_PASSWORD=secure_mysql_root_password_here
```

---

## Comparison: Kamal vs Docker Compose vs Capistrano

| Feature | Capistrano | Docker Compose | Kamal |
|---------|------------|----------------|-------|
| **Deployment method** | Git + SSH | Manual docker-compose | `kamal deploy` |
| **Zero-downtime** | Manual setup | Manual setup | Built-in |
| **SSL/TLS** | Manual Nginx | Manual setup | Automatic (Let's Encrypt) |
| **Config file** | deploy.rb | docker-compose.yml | deploy.yml |
| **Container support** | No | Yes | Yes |
| **Multi-server** | Yes | Complex | Native |
| **Rails integration** | Excellent | Manual | Excellent |
| **Learning curve** | Medium | Medium | Low (if you know Capistrano) |
| **Asset handling** | Built-in | Manual | Built-in |
| **Rollback** | Built-in | Manual | Built-in |
| **Health checks** | Manual | Manual | Built-in |
| **Secrets** | Manual | Docker secrets | Built-in |
| **Production ready** | Yes | Yes | Yes |
| **Recommended by Rails** | Previously | No | **Currently** |

---

## Conclusion

Kamal provides a **Rails-native, zero-downtime deployment solution** that replaces Capistrano while embracing Docker containers. It's the official Rails recommendation and used by 37signals for Hey.com and Basecamp.

### Key Benefits for RobynBase

1. **Simplicity**: Single `kamal deploy` command
2. **Zero-downtime**: Built-in health checks and rolling deploys
3. **Automatic SSL**: Let's Encrypt integration
4. **Familiar**: Similar to Capistrano (deploy.yml vs deploy.rb)
5. **Rails-native**: Built by Rails core team
6. **Future-proof**: Container-based, cloud-ready

### Next Steps

1. **Week 1**: Set up Kamal locally, create configurations
2. **Week 2**: Deploy to staging/subdomain
3. **Week 3**: Migrate production
4. **Week 4**: Set up CI/CD, monitoring

### Resources

- **Official Docs**: https://kamal-deploy.org
- **GitHub**: https://github.com/basecamp/kamal
- **Rails Guide**: https://guides.rubyonrails.org/kamal.html
- **Community**: https://discuss.rubyonrails.org/c/deployment/kamal

---

**Document Version**: 1.0
**Last Updated**: 2025-11-15
**Author**: Claude (AI Assistant)
**Status**: Ready for Implementation
