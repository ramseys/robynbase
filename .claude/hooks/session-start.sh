#!/bin/bash
set -euo pipefail

# Only run in remote (Claude Code on the web) environments
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

echo '{"async": true, "asyncTimeout": 300000}'

# Install system dependencies required for native gems
apt-get install -y libmariadb-dev > /dev/null 2>&1

# Install the bundler version declared in Gemfile.lock
BUNDLER_VERSION=$(grep -A1 "BUNDLED WITH" "$CLAUDE_PROJECT_DIR/Gemfile.lock" | tail -1 | tr -d ' ')
gem install bundler -v "$BUNDLER_VERSION" --no-document

# Install gems using the correct bundler version
cd "$CLAUDE_PROJECT_DIR"
bundle "_${BUNDLER_VERSION}_" install
