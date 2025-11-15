# Docker-Based Deployment Plan for RobynBase

> **⚠️ RECOMMENDATION**: Consider using **Kamal** instead (see [KAMAL_DEPLOYMENT_PLAN.md](./KAMAL_DEPLOYMENT_PLAN.md))
>
> Kamal is the **official Rails-recommended deployment tool** (Rails 7.1+) created by 37signals. It provides:
> - Zero-downtime deployments with built-in health checks
> - Automatic SSL via Let's Encrypt
> - Simpler configuration (similar to Capistrano)
> - Rails-native integration
> - Used in production by Hey.com and Basecamp
>
> This document covers a **manual Docker Compose approach**, which is more complex but gives you full control.

## Executive Summary

This document outlines a comprehensive plan to migrate RobynBase from Capistrano-based deployment to a Docker-based containerized deployment strategy. This migration will provide improved consistency, portability, simplified dependency management, and easier scaling options.

---

## Table of Contents

1. [Current State Analysis](#current-state-analysis)
2. [Goals and Benefits](#goals-and-benefits)
3. [Proposed Architecture](#proposed-architecture)
4. [Docker Services Overview](#docker-services-overview)
5. [Docker Image Strategy](#docker-image-strategy)
6. [Environment Configuration](#environment-configuration)
7. [Asset Building Strategy](#asset-building-strategy)
8. [Storage and Persistence](#storage-and-persistence)
9. [Deployment Workflow](#deployment-workflow)
10. [CI/CD Integration](#cicd-integration)
11. [Rollback Strategy](#rollback-strategy)
12. [Migration Path](#migration-path)
13. [Monitoring and Logging](#monitoring-and-logging)
14. [Security Considerations](#security-considerations)
15. [Timeline and Phases](#timeline-and-phases)
16. [Appendix: Sample Configurations](#appendix-sample-configurations)

---

## Current State Analysis

### Existing Capistrano Setup

**Current Deployment:**
- Single server: 66.228.36.37
- Deploy user: `ramseys`
- Deploy path: `/var/www/robynbase`
- Web server: Passenger (restart via `tmp/restart.txt`)
- Ruby: 3.4.4 via RVM
- Database: MySQL 2
- Redis: Action Cable support
- Asset pipeline: esbuild + Sass via Yarn

**Capistrano Flow:**
1. Git clone from master branch
2. Bundle install
3. Yarn install + asset builds (JS/CSS)
4. Rails asset precompilation
5. Database migrations
6. Symlink shared files/directories
7. Passenger restart

**Shared Files/Directories:**
- `config/database.yml`
- `config/master.key`
- `public/images/album-art/`
- `active-storage-files/`

**Pain Points:**
- Server-specific RVM/Ruby setup required
- Manual server provisioning
- Limited scalability
- Environment drift between deploys
- No easy local production simulation
- Deployment tied to single server

---

## Goals and Benefits

### Primary Goals

1. **Consistency**: Identical environments across development, staging, and production
2. **Portability**: Deploy to any Docker-compatible host (cloud or on-premise)
3. **Simplicity**: Simplified dependency management (no RVM, system gems, etc.)
4. **Scalability**: Easy horizontal scaling for web containers
5. **Rapid Rollback**: Quick rollback to previous images
6. **Developer Experience**: Local development matches production exactly

### Expected Benefits

- **Faster Onboarding**: New developers run `docker-compose up`
- **Consistent Builds**: Same image across all environments
- **Infrastructure as Code**: Docker Compose/orchestration configs version-controlled
- **Cloud-Ready**: Easy migration to AWS ECS, Google Cloud Run, DigitalOcean, etc.
- **Resource Isolation**: Better resource limits and monitoring
- **Zero-Downtime Deploys**: Rolling updates with orchestration tools

---

## Proposed Architecture

### Multi-Container Architecture

```
┌─────────────────────────────────────────────────┐
│                  Nginx (Reverse Proxy)          │
│                   Port 80/443                   │
└────────────────────┬────────────────────────────┘
                     │
         ┌───────────┴───────────┐
         │                       │
         ▼                       ▼
┌────────────────┐      ┌────────────────┐
│  Rails App     │      │  Rails App     │
│  (Puma)        │◄────►│  (Puma)        │
│  Port 3000     │      │  Port 3000     │
└────────┬───────┘      └────────┬───────┘
         │                       │
         └───────────┬───────────┘
                     │
         ┌───────────┴───────────┐
         │                       │
         ▼                       ▼
┌────────────────┐      ┌────────────────┐
│    MySQL       │      │     Redis      │
│    Port 3306   │      │    Port 6379   │
└────────────────┘      └────────────────┘
         │
         ▼
┌────────────────┐
│  Shared Volumes│
│  - album-art   │
│  - storage     │
└────────────────┘
```

### Service Breakdown

| Service | Purpose | Base Image | Scaling |
|---------|---------|------------|---------|
| **nginx** | Reverse proxy, SSL termination, static asset serving | nginx:alpine | 1 instance |
| **app** | Rails application (Puma web server) | ruby:3.4-slim | 2+ instances |
| **db** | MySQL database | mysql:8.0 | 1 instance (primary) |
| **redis** | Action Cable, caching (future) | redis:7-alpine | 1 instance |

---

## Docker Services Overview

### 1. Rails Application Container (`app`)

**Responsibilities:**
- Run Puma web server
- Serve Rails application
- Execute database migrations
- Handle background jobs (if configured)

**Key Points:**
- Multi-stage build (builder + runtime)
- Assets precompiled during image build
- Health checks via HTTP endpoint
- Graceful shutdown handling

### 2. Nginx Container (`nginx`)

**Responsibilities:**
- Reverse proxy to Rails app containers
- Serve static assets directly (public/ directory)
- SSL/TLS termination
- Load balancing across multiple app containers

**Key Points:**
- Mounts public/ volume from Rails container
- Custom nginx.conf for Rails
- SSL certificate management
- Gzip compression for assets

### 3. MySQL Container (`db`)

**Responsibilities:**
- MySQL database server
- Data persistence

**Key Points:**
- Named volume for data persistence
- Custom MySQL configuration (utf8mb3 charset, MyISAM support)
- Health checks via mysqladmin ping
- Backup strategy required

### 4. Redis Container (`redis`)

**Responsibilities:**
- Action Cable backend
- Future: Session store, caching, Sidekiq

**Key Points:**
- Persistent volume for Redis data (optional)
- Redis configuration tuning
- Health checks via redis-cli ping

---

## Docker Image Strategy

### Multi-Stage Dockerfile

**Stage 1: Builder**
- Install build dependencies (build-essential, Node.js, Yarn)
- Install Ruby gems via Bundler
- Install Node packages via Yarn
- Build JavaScript assets (esbuild)
- Build CSS assets (Sass)
- Precompile Rails assets

**Stage 2: Runtime**
- Use minimal ruby:3.4-slim base
- Copy compiled assets from builder
- Copy installed gems from builder
- Install runtime dependencies only (imagemagick, mysql-client)
- Set proper user permissions
- Define health check

**Benefits:**
- Smaller final image (~300-500MB vs 1GB+)
- Faster deployments
- No build tools in production image
- Security: Minimal attack surface

### Image Tagging Strategy

```bash
# Semantic versioning
robynbase:1.2.3

# Git commit SHA (recommended)
robynbase:abc1234567

# Environment + Git SHA
robynbase:production-abc1234

# Latest (for development only)
robynbase:latest
```

**Recommendation**: Use Git SHA for production deployments to enable precise rollbacks.

---

## Environment Configuration

### Environment Variables

**Database:**
```bash
DATABASE_HOST=db
DATABASE_PORT=3306
DATABASE_NAME=robynbase_production
DATABASE_USERNAME=robynbase
DATABASE_PASSWORD=<secure_password>
DATABASE_POOL=5
```

**Rails:**
```bash
RAILS_ENV=production
RAILS_LOG_TO_STDOUT=true
RAILS_SERVE_STATIC_FILES=false  # Nginx serves static files
RAILS_MASTER_KEY=<master_key_from_config>
SECRET_KEY_BASE=<generate_via_rails_secret>
```

**Redis:**
```bash
REDIS_URL=redis://redis:6379/1
CABLE_REDIS_URL=redis://redis:6379/1
```

**Puma:**
```bash
WEB_CONCURRENCY=2          # Number of Puma workers
RAILS_MAX_THREADS=5        # Threads per worker
PORT=3000
```

**Asset Host (optional):**
```bash
ASSET_HOST=https://cdn.robynbase.com
```

### Configuration Files

**Option 1: Docker Secrets (recommended for production)**
- Store `master.key` as Docker secret
- Mount at `/app/config/master.key`
- Use `docker secret create` command

**Option 2: Environment Files**
- `.env.production` (git-ignored)
- Mount via `docker-compose.yml`

**Option 3: External Secret Management**
- AWS Secrets Manager
- HashiCorp Vault
- Google Secret Manager

---

## Asset Building Strategy

### Build-Time Asset Compilation

**Approach**: Assets built during Docker image build (preferred)

**Dockerfile steps:**
```dockerfile
# Install Node.js and Yarn
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g yarn

# Install dependencies
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

# Build JavaScript and CSS
COPY app/javascript ./app/javascript
COPY app/assets ./app/assets
RUN yarn build && yarn build:css

# Precompile Rails assets
COPY . .
RUN RAILS_ENV=production SECRET_KEY_BASE=dummy \
    bundle exec rails assets:precompile
```

**Benefits:**
- Faster container startup
- No Node.js/Yarn in production image
- Assets cached in Docker layers
- Consistent builds

**Trade-offs:**
- Image rebuild required for asset changes
- Larger image size (mitigated by multi-stage builds)

### Runtime Asset Compilation (Alternative)

**Approach**: Assets built on container startup

**Use case**: Rapid development iteration

**Implementation**: Entrypoint script runs `rails assets:precompile` before starting Puma

---

## Storage and Persistence

### Docker Volumes

**Named Volumes (recommended for production):**

```yaml
volumes:
  mysql-data:           # MySQL database files
  redis-data:           # Redis persistence (optional)
  album-art:            # Public album artwork
  active-storage:       # Active Storage uploads
```

**Bind Mounts (development only):**
- Mount local code directory to `/app` for live reloading

### Storage Locations

| Data Type | Current Path | Docker Volume | Backup Priority |
|-----------|--------------|---------------|-----------------|
| MySQL data | `/var/lib/mysql` | `mysql-data` | Critical |
| Album art | `public/images/album-art/` | `album-art` | High |
| Active Storage | `active-storage-files/` | `active-storage` | High |
| Redis data | `/data` | `redis-data` | Low |
| Rails logs | `log/production.log` | (stdout preferred) | N/A |

### Backup Strategy

**Daily MySQL Backups:**
```bash
docker exec robynbase-db mysqldump \
  -u robynbase -p<password> robynbase_production \
  | gzip > backup-$(date +%Y%m%d).sql.gz
```

**Volume Backups:**
```bash
docker run --rm \
  -v robynbase_album-art:/data \
  -v $(pwd)/backups:/backup \
  alpine tar czf /backup/album-art-$(date +%Y%m%d).tar.gz /data
```

**Cloud Storage:**
- Sync volumes to S3/GCS/Azure Blob
- Use Active Storage with cloud backend in future

---

## Deployment Workflow

### Development Workflow

```bash
# 1. Clone repository
git clone https://github.com/ramseys/robynbase.git
cd robynbase

# 2. Start all services
docker-compose up

# 3. Setup database (first time)
docker-compose exec app rails db:create db:schema:load

# 4. Access application
open http://localhost:3000
```

### Production Deployment Workflow

#### Option A: Docker Compose on Single Server (simplest)

```bash
# On production server (66.228.36.37)

# 1. Pull latest code
cd /var/www/robynbase
git pull origin main

# 2. Build new image
docker-compose build app

# 3. Run database migrations
docker-compose run --rm app rails db:migrate

# 4. Restart services (zero-downtime with multiple app containers)
docker-compose up -d --no-deps --scale app=2 --no-recreate app
docker-compose restart nginx

# 5. Cleanup old images
docker image prune -f
```

#### Option B: CI/CD Pipeline (recommended)

**Workflow:**
1. Push to `main` branch
2. GitHub Actions builds Docker image
3. Push image to Docker Hub/GHCR/ECR
4. SSH to production server
5. Pull new image
6. Run migrations
7. Rolling restart of app containers
8. Health check verification

**Example GitHub Actions:**
```yaml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Build image
        run: docker build -t robynbase:${{ github.sha }} .

      - name: Push to registry
        run: docker push robynbase:${{ github.sha }}

      - name: Deploy to server
        run: |
          ssh user@66.228.36.37 \
            "cd /var/www/robynbase && \
             export IMAGE_TAG=${{ github.sha }} && \
             docker-compose pull && \
             docker-compose up -d"
```

#### Option C: Orchestration Platform (future scaling)

- **Kubernetes**: For multi-server deployments
- **Docker Swarm**: Simpler alternative to Kubernetes
- **AWS ECS/Fargate**: Managed container orchestration
- **Google Cloud Run**: Serverless container platform

---

## CI/CD Integration

### GitHub Actions Pipeline

**Stages:**

1. **Test**
   - Run RSpec tests
   - Run Rubocop linting
   - Security scans (bundler-audit, brakeman)

2. **Build**
   - Build Docker image
   - Tag with Git SHA
   - Push to container registry

3. **Deploy**
   - Pull image on production server
   - Run migrations
   - Rolling update of containers
   - Health checks
   - Notify Slack/email on success/failure

### Container Registry Options

| Registry | Pros | Cons |
|----------|------|------|
| **Docker Hub** | Free for public, easy setup | Rate limits, slower pulls |
| **GitHub Container Registry** | Free, integrated with GitHub | Newer service |
| **AWS ECR** | Fast, private, AWS integration | Requires AWS account |
| **Google Artifact Registry** | Fast, private, GCP integration | Requires GCP account |

**Recommendation**: Start with GitHub Container Registry (GHCR) for simplicity.

---

## Rollback Strategy

### Image-Based Rollback

**Previous Image Rollback:**
```bash
# List recent images
docker images robynbase

# Revert to previous SHA
export PREVIOUS_SHA=xyz789
docker-compose up -d --no-deps app
```

### Database Rollback Considerations

**Challenge**: Migrations may not be reversible

**Solutions:**
1. **Database Snapshots**: Take snapshot before migrations
   ```bash
   # Before migration
   docker exec robynbase-db mysqldump robynbase_production > pre-deploy.sql

   # Rollback if needed
   docker exec -i robynbase-db mysql robynbase_production < pre-deploy.sql
   ```

2. **Reversible Migrations**: Write `down` methods for all migrations

3. **Blue-Green Deployment**: Maintain two database instances for major changes

### Health Checks

**Application Health Endpoint:**
```ruby
# config/routes.rb
get '/health', to: 'health#index'

# app/controllers/health_controller.rb
class HealthController < ApplicationController
  def index
    render json: {
      status: 'ok',
      database: database_check,
      redis: redis_check
    }
  end
end
```

**Docker Health Check:**
```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s \
  CMD curl -f http://localhost:3000/health || exit 1
```

---

## Migration Path

### Phase 1: Preparation (Week 1)

**Tasks:**
- [ ] Create Dockerfile (multi-stage build)
- [ ] Create docker-compose.yml for development
- [ ] Create docker-compose.production.yml
- [ ] Test local Docker development environment
- [ ] Document Docker setup in README
- [ ] Train team on Docker basics

**Deliverables:**
- Working Docker development environment
- Documentation

### Phase 2: CI/CD Setup (Week 2)

**Tasks:**
- [ ] Set up GitHub Container Registry
- [ ] Create GitHub Actions workflow for building images
- [ ] Add automated tests to CI pipeline
- [ ] Configure image tagging strategy
- [ ] Set up deployment secrets

**Deliverables:**
- Automated Docker image builds
- Tagged images in registry

### Phase 3: Staging Deployment (Week 3)

**Tasks:**
- [ ] Provision staging server (or use existing)
- [ ] Install Docker and Docker Compose on staging server
- [ ] Deploy RobynBase to staging via Docker
- [ ] Migrate staging database
- [ ] Test full deployment workflow
- [ ] Load test with production-like data
- [ ] Document deployment runbook

**Deliverables:**
- Working staging environment on Docker
- Deployment runbook

### Phase 4: Production Migration (Week 4)

**Tasks:**
- [ ] Schedule maintenance window
- [ ] Back up production database and files
- [ ] Install Docker on production server (66.228.36.37)
- [ ] Copy volumes from current paths to Docker volumes
- [ ] Deploy Docker Compose stack
- [ ] Run database migrations
- [ ] Verify application functionality
- [ ] Monitor performance and logs
- [ ] Update DNS if needed (for load balancer)

**Deliverables:**
- Production running on Docker
- Capistrano deprecated

### Phase 5: Optimization (Ongoing)

**Tasks:**
- [ ] Implement blue-green deployments
- [ ] Add application performance monitoring (APM)
- [ ] Set up log aggregation (ELK, Datadog, etc.)
- [ ] Optimize Docker image size
- [ ] Add horizontal autoscaling (if using orchestration)
- [ ] Migrate to cloud provider (optional)

---

## Monitoring and Logging

### Container Logging

**Approach**: Centralize logs to stdout/stderr

**Rails Configuration:**
```ruby
# config/environments/production.rb
config.logger = ActiveSupport::Logger.new(STDOUT)
config.log_formatter = ::Logger::Formatter.new
config.log_level = ENV.fetch('RAILS_LOG_LEVEL', 'info').to_sym
```

**Docker Logging Drivers:**
- `json-file`: Default, logs to disk
- `journald`: SystemD journal integration
- `syslog`: Syslog server
- `awslogs`: AWS CloudWatch
- `gcplogs`: Google Cloud Logging

### Log Aggregation Options

**Self-Hosted:**
- ELK Stack (Elasticsearch, Logstash, Kibana)
- Grafana Loki + Promtail

**SaaS:**
- Datadog
- New Relic
- Papertrail
- Loggly

### Application Metrics

**Container Metrics:**
```bash
# Resource usage
docker stats robynbase-app

# Container health
docker ps --format "table {{.Names}}\t{{.Status}}"
```

**Rails Metrics:**
- Response times
- Error rates
- Database query performance
- Memory usage

**Tools:**
- Prometheus + Grafana
- New Relic APM
- Scout APM
- Datadog APM

---

## Security Considerations

### Image Security

**Best Practices:**
1. **Use Official Base Images**: `ruby:3.4-slim` from Docker Hub
2. **Scan for Vulnerabilities**:
   ```bash
   docker scan robynbase:latest
   ```
3. **Non-Root User**: Run app as non-root user
   ```dockerfile
   RUN useradd -m -u 1000 rails
   USER rails
   ```
4. **Minimal Dependencies**: Only install required packages
5. **Regular Updates**: Rebuild images monthly for security patches

### Secrets Management

**Never:**
- Store secrets in Dockerfile
- Commit secrets to Git
- Use default passwords

**Do:**
- Use Docker secrets (Swarm) or Kubernetes secrets
- Use environment variables from external sources
- Rotate secrets regularly
- Use read-only mounts for sensitive files

**Example:**
```yaml
# docker-compose.yml
services:
  app:
    environment:
      DATABASE_PASSWORD_FILE: /run/secrets/db_password
    secrets:
      - db_password

secrets:
  db_password:
    file: ./secrets/db_password.txt
```

### Network Security

**Isolation:**
```yaml
# docker-compose.yml
networks:
  frontend:  # Nginx <-> App
  backend:   # App <-> DB, Redis

services:
  nginx:
    networks: [frontend]

  app:
    networks: [frontend, backend]

  db:
    networks: [backend]  # Not exposed to internet
```

### SSL/TLS Configuration

**Option 1: Let's Encrypt with Certbot**
```yaml
services:
  certbot:
    image: certbot/certbot
    volumes:
      - ./certbot/conf:/etc/letsencrypt
      - ./certbot/www:/var/www/certbot
```

**Option 2: Cloudflare SSL (free)**
- Cloudflare handles SSL termination
- Nginx uses Cloudflare origin certificate

---

## Timeline and Phases

### Summary Timeline

| Phase | Duration | Key Milestone |
|-------|----------|---------------|
| **Phase 1**: Preparation | 1 week | Local Docker environment working |
| **Phase 2**: CI/CD | 1 week | Automated image builds |
| **Phase 3**: Staging | 1 week | Staging deployed on Docker |
| **Phase 4**: Production | 1 week | Production migrated to Docker |
| **Phase 5**: Optimization | Ongoing | Performance tuning, scaling |

**Total Initial Migration**: 4 weeks

### Risk Mitigation

**Risks:**
1. **Database migration issues**: Mitigate with full backups and staging tests
2. **Downtime during migration**: Mitigate with maintenance window and rollback plan
3. **Performance regressions**: Mitigate with load testing on staging
4. **Missing dependencies**: Mitigate with comprehensive Dockerfile testing
5. **Learning curve**: Mitigate with team training and documentation

---

## Appendix: Sample Configurations

### A. Dockerfile (Multi-Stage)

```dockerfile
# syntax=docker/dockerfile:1

###################
# Stage 1: Builder
###################
FROM ruby:3.4-slim AS builder

# Install build dependencies
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      build-essential \
      default-libmysqlclient-dev \
      git \
      curl \
      && rm -rf /var/lib/apt/lists/*

# Install Node.js and Yarn
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g yarn

WORKDIR /app

# Install Ruby dependencies
COPY Gemfile Gemfile.lock ./
RUN bundle config set --local deployment 'true' && \
    bundle config set --local without 'development test' && \
    bundle install -j$(nproc)

# Install Node dependencies
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile --production=false

# Copy application code
COPY . .

# Build assets
RUN yarn build && \
    yarn build:css && \
    RAILS_ENV=production SECRET_KEY_BASE=dummy \
      bundle exec rails assets:precompile

###################
# Stage 2: Runtime
###################
FROM ruby:3.4-slim

# Install runtime dependencies
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      default-mysql-client \
      imagemagick \
      curl \
      && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Create non-root user
RUN useradd -m -u 1000 rails && \
    chown -R rails:rails /app

# Copy installed gems from builder
COPY --from=builder /usr/local/bundle /usr/local/bundle

# Copy application code and compiled assets
COPY --chown=rails:rails . .
COPY --from=builder --chown=rails:rails /app/public /app/public
COPY --from=builder --chown=rails:rails /app/app/assets/builds /app/app/assets/builds

USER rails

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

# Entrypoint
COPY --chown=rails:rails docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
```

### B. docker-compose.yml (Development)

```yaml
version: '3.8'

services:
  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: root_password
      MYSQL_DATABASE: robynbase_development
      MYSQL_USER: robynbase
      MYSQL_PASSWORD: password
    ports:
      - "3306:3306"
    volumes:
      - mysql-data:/var/lib/mysql
      - ./docker/mysql/my.cnf:/etc/mysql/conf.d/custom.cnf
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis-data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5

  app:
    build:
      context: .
      dockerfile: Dockerfile
      target: builder  # Use builder stage for development
    command: bash -c "rm -f tmp/pids/server.pid && bundle exec rails server -b 0.0.0.0"
    ports:
      - "3000:3000"
    environment:
      DATABASE_HOST: db
      DATABASE_USERNAME: robynbase
      DATABASE_PASSWORD: password
      DATABASE_NAME: robynbase_development
      REDIS_URL: redis://redis:6379/1
      RAILS_ENV: development
      RAILS_MAX_THREADS: 5
    volumes:
      - .:/app  # Mount code for live reloading
      - bundle:/usr/local/bundle
      - node_modules:/app/node_modules
      - album-art:/app/public/images/album-art
      - active-storage:/app/active-storage-files
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy

volumes:
  mysql-data:
  redis-data:
  bundle:
  node_modules:
  album-art:
  active-storage:
```

### C. docker-compose.production.yml

```yaml
version: '3.8'

services:
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./docker/nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./docker/nginx/ssl:/etc/nginx/ssl:ro
      - public-assets:/usr/share/nginx/html/assets:ro
      - album-art:/usr/share/nginx/html/images/album-art:ro
    depends_on:
      - app
    restart: unless-stopped

  app:
    image: ghcr.io/ramseys/robynbase:${IMAGE_TAG:-latest}
    environment:
      DATABASE_HOST: db
      DATABASE_USERNAME: ${DATABASE_USERNAME}
      DATABASE_PASSWORD: ${DATABASE_PASSWORD}
      DATABASE_NAME: robynbase_production
      REDIS_URL: redis://redis:6379/1
      RAILS_ENV: production
      RAILS_LOG_TO_STDOUT: "true"
      RAILS_SERVE_STATIC_FILES: "false"
      SECRET_KEY_BASE: ${SECRET_KEY_BASE}
      WEB_CONCURRENCY: 2
      RAILS_MAX_THREADS: 5
    secrets:
      - master_key
    volumes:
      - album-art:/app/public/images/album-art
      - active-storage:/app/active-storage-files
      - public-assets:/app/public:ro
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy
    restart: unless-stopped
    deploy:
      replicas: 2
      resources:
        limits:
          cpus: '1'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M

  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: robynbase_production
      MYSQL_USER: ${DATABASE_USERNAME}
      MYSQL_PASSWORD: ${DATABASE_PASSWORD}
    volumes:
      - mysql-data:/var/lib/mysql
      - ./docker/mysql/my.cnf:/etc/mysql/conf.d/custom.cnf:ro
      - ./backups:/backups
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "root", "-p${MYSQL_ROOT_PASSWORD}"]
      interval: 30s
      timeout: 10s
      retries: 5
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    volumes:
      - redis-data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 5s
      retries: 5
    restart: unless-stopped

secrets:
  master_key:
    file: ./config/master.key

volumes:
  mysql-data:
  redis-data:
  album-art:
  active-storage:
  public-assets:
```

### D. docker-entrypoint.sh

```bash
#!/bin/bash
set -e

# Remove potential leftover PID file
rm -f /app/tmp/pids/server.pid

# Wait for database to be ready
echo "Waiting for database..."
until mysql -h"$DATABASE_HOST" -u"$DATABASE_USERNAME" -p"$DATABASE_PASSWORD" -e "SELECT 1" >/dev/null 2>&1; do
  echo "Database is unavailable - sleeping"
  sleep 2
done
echo "Database is up!"

# Run migrations if RAILS_ENV is production and AUTO_MIGRATE is set
if [ "$RAILS_ENV" = "production" ] && [ "$AUTO_MIGRATE" = "true" ]; then
  echo "Running database migrations..."
  bundle exec rails db:migrate
fi

# Execute the main command
exec "$@"
```

### E. Nginx Configuration

```nginx
# docker/nginx/nginx.conf

upstream app {
  least_conn;
  server app:3000 max_fails=3 fail_timeout=30s;
}

server {
  listen 80;
  server_name robynbase.com www.robynbase.com;

  # Redirect HTTP to HTTPS
  return 301 https://$server_name$request_uri;
}

server {
  listen 443 ssl http2;
  server_name robynbase.com www.robynbase.com;

  ssl_certificate /etc/nginx/ssl/certificate.crt;
  ssl_certificate_key /etc/nginx/ssl/private.key;
  ssl_protocols TLSv1.2 TLSv1.3;
  ssl_ciphers HIGH:!aNULL:!MD5;

  root /usr/share/nginx/html;

  client_max_body_size 100M;

  # Serve static assets directly
  location ~ ^/(assets|packs|images)/ {
    expires 1y;
    add_header Cache-Control "public, immutable";
    try_files $uri @app;
  }

  # Album art
  location /images/album-art {
    expires 1y;
    add_header Cache-Control "public";
  }

  # Proxy to Rails app
  location / {
    proxy_pass http://app;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_redirect off;

    # WebSocket support for Action Cable
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
  }

  location @app {
    proxy_pass http://app;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
  }
}
```

### F. GitHub Actions Workflow

```yaml
# .github/workflows/deploy.yml

name: Build and Deploy

on:
  push:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      mysql:
        image: mysql:8.0
        env:
          MYSQL_ROOT_PASSWORD: root
          MYSQL_DATABASE: robynbase_test
        options: >-
          --health-cmd="mysqladmin ping"
          --health-interval=10s
          --health-timeout=5s
          --health-retries=5
      redis:
        image: redis:7-alpine
        options: >-
          --health-cmd="redis-cli ping"
          --health-interval=10s
          --health-timeout=5s
          --health-retries=5

    steps:
      - uses: actions/checkout@v3

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.4.4
          bundler-cache: true

      - name: Run tests
        env:
          DATABASE_HOST: mysql
          DATABASE_USERNAME: root
          DATABASE_PASSWORD: root
          DATABASE_NAME: robynbase_test
          REDIS_URL: redis://redis:6379/1
          RAILS_ENV: test
        run: |
          bundle exec rails db:schema:load
          bundle exec rspec

  build-and-push:
    needs: test
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      - uses: actions/checkout@v3

      - name: Log in to Container Registry
        uses: docker/login-action@v2
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v4
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=sha,prefix=,format=long
            type=ref,event=branch
            type=semver,pattern={{version}}

      - name: Build and push Docker image
        uses: docker/build-push-action@v4
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=registry,ref=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:buildcache
          cache-to: type=registry,ref=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:buildcache,mode=max

  deploy:
    needs: build-and-push
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to production
        uses: appleboy/ssh-action@master
        env:
          IMAGE_TAG: ${{ github.sha }}
        with:
          host: ${{ secrets.PRODUCTION_HOST }}
          username: ${{ secrets.PRODUCTION_USER }}
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          envs: IMAGE_TAG
          script: |
            cd /var/www/robynbase
            export IMAGE_TAG=$IMAGE_TAG
            docker-compose -f docker-compose.production.yml pull
            docker-compose -f docker-compose.production.yml up -d
            docker image prune -f
```

### G. MySQL Configuration

```ini
# docker/mysql/my.cnf

[mysqld]
character-set-server=utf8mb3
collation-server=utf8mb3_general_ci

# MyISAM support (for legacy tables)
default-storage-engine=InnoDB
myisam-recover-options=BACKUP,FORCE

# Performance tuning
max_connections=200
innodb_buffer_pool_size=512M
innodb_log_file_size=128M

# Logging
slow_query_log=1
slow_query_log_file=/var/log/mysql/slow-query.log
long_query_time=2
```

---

## Conclusion

This Docker-based deployment plan provides a comprehensive roadmap for migrating RobynBase from Capistrano to a modern containerized infrastructure. The migration will improve deployment consistency, developer experience, and scalability while maintaining backward compatibility with existing production data.

### Next Steps

1. **Review this plan** with the team
2. **Create a GitHub issue** to track migration progress
3. **Start Phase 1** by creating the Dockerfile and docker-compose.yml
4. **Schedule weekly check-ins** to track progress
5. **Document learnings** as you progress through each phase

### Questions or Concerns?

- Docker learning curve for team members?
- Performance concerns with containerization?
- Database migration strategy?
- Backup and disaster recovery plans?
- Cost implications of container registry?

Please address these before proceeding with the migration.

---

**Document Version**: 1.0
**Last Updated**: 2025-11-15
**Author**: Claude (AI Assistant)
**Status**: Draft for Review
