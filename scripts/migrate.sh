#!/bin/bash

# D1 Migration Script for i18n Tags
# Usage: ./migrate.sh [local|remote] [database_name]

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(dirname "$SCRIPT_DIR")/backend"
MIGRATION_FILE="$SCRIPT_DIR/002_migrate_i18n_tags.sql"

# Default values
ENV="${1:-remote}"
DB_NAME="${2:-langmap}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Check if migration file exists
if [ ! -f "$MIGRATION_FILE" ]; then
    print_error "Migration file not found: $MIGRATION_FILE"
    exit 1
fi

# Check if wrangler is installed
if ! command -v npx &> /dev/null; then
    print_error "npx is not installed. Please install Node.js and npm."
    exit 1
fi

# Change to backend directory
cd "$BACKEND_DIR" || {
    print_error "Cannot change to backend directory: $BACKEND_DIR"
    exit 1
}

# Display migration info
echo "======================================"
echo "D1 Migration: i18n Tags Update"
echo "======================================"
echo "Environment: $ENV"
echo "Database: $DB_NAME"
echo "Migration File: $MIGRATION_FILE"
echo ""

# Ask for confirmation
if [ "$ENV" = "remote" ]; then
    print_warning "You are about to apply migration to REMOTE database"
    echo "This will update tags in all expressions."
    echo ""
    read -p "Are you sure? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "Migration cancelled."
        exit 0
    fi
fi

# Apply migration
echo ""
echo "Applying migration..."
if [ "$ENV" = "local" ]; then
    npx wrangler d1 execute "$DB_NAME" --file="$MIGRATION_FILE" --local
else
    npx wrangler d1 execute "$DB_NAME" --file="$MIGRATION_FILE"
fi

# Check result
if [ $? -eq 0 ]; then
    print_success "Migration completed successfully!"
    echo ""
    echo "To verify the migration:"
    echo "  npx wrangler d1 execute $DB_NAME --command=\"SELECT COUNT(*) FROM expressions WHERE tags LIKE '%\"login_failed\"%'\""
else
    print_error "Migration failed!"
    exit 1
fi
