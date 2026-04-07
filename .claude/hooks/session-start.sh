#!/bin/bash
set -euo pipefail

# Only run in remote (Claude Code on the web) environments
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

echo '{"async": true, "asyncTimeout": 300000}'

# Install system dependencies required for native gems and MySQL server
apt-get install -y libmariadb-dev mariadb-server > /dev/null 2>&1

# Start MariaDB if not already running
if ! mysqladmin ping --socket=/var/run/mysqld/mysqld.sock 2>/dev/null; then
  mysqld_safe --skip-grant-tables --skip-networking &
  # Wait for MySQL to be ready
  for i in $(seq 1 15); do
    if mysqladmin ping --socket=/var/run/mysqld/mysqld.sock 2>/dev/null; then
      break
    fi
    sleep 1
  done
fi

# Create development and test databases if they don't exist
mysql -u root --socket=/var/run/mysqld/mysqld.sock -e "
  CREATE DATABASE IF NOT EXISTS robynbase_development;
  CREATE DATABASE IF NOT EXISTS robynbase_test;
" 2>/dev/null

# Install the bundler version declared in Gemfile.lock
BUNDLER_VERSION=$(grep -A1 "BUNDLED WITH" "$CLAUDE_PROJECT_DIR/Gemfile.lock" | tail -1 | tr -d ' ')
gem install bundler -v "$BUNDLER_VERSION" --no-document

# Install gems using the correct bundler version
cd "$CLAUDE_PROJECT_DIR"
bundle "_${BUNDLER_VERSION}_" install

# Create database.yml for local development if it doesn't exist
if [ ! -f "$CLAUDE_PROJECT_DIR/config/database.yml" ]; then
  cat > "$CLAUDE_PROJECT_DIR/config/database.yml" <<'EOF'
default: &default
  adapter: mysql2
  encoding: utf8mb4
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  socket: /var/run/mysqld/mysqld.sock
  username: root
  password:

development:
  <<: *default
  database: robynbase_development

test:
  <<: *default
  database: robynbase_test
EOF
fi

# Load schema if the main tables don't exist yet
TABLE_COUNT=$(mysql -u root --socket=/var/run/mysqld/mysqld.sock robynbase_development -e "SHOW TABLES;" 2>/dev/null | wc -l)
if [ "$TABLE_COUNT" -lt 5 ]; then
  cd "$CLAUDE_PROJECT_DIR"
  # MariaDB doesn't support the utf8mb4_0900_ai_ci collation (MySQL 8.0+),
  # so replace it with the equivalent MariaDB collation before loading.
  sed -i 's/utf8mb4_0900_ai_ci/utf8mb4_unicode_ci/g' db/schema.rb
  bin/rails db:schema:load
  git checkout db/schema.rb
fi
