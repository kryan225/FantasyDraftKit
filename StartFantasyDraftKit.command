#!/bin/bash

# FantasyDraftKit - One-Click Launcher
# Double-click this file to start the app. Close the window or press Ctrl+C to stop.

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKEND_DIR="$PROJECT_DIR/backend"
RAILS_PID=""

cleanup() {
  echo ""
  echo "Shutting down FantasyDraftKit..."

  if [ -n "$RAILS_PID" ] && kill -0 "$RAILS_PID" 2>/dev/null; then
    echo "Stopping Rails server (PID $RAILS_PID)..."
    kill "$RAILS_PID"
    wait "$RAILS_PID" 2>/dev/null
  fi

  echo "Stopping database container..."
  docker-compose -f "$PROJECT_DIR/docker-compose.yml" stop db

  echo "FantasyDraftKit stopped. You can close this window."
  exit 0
}

trap cleanup EXIT INT TERM

echo "========================================="
echo "  Starting FantasyDraftKit"
echo "========================================="
echo ""

# 1. Start PostgreSQL
echo "[1/3] Starting PostgreSQL on port 5434..."
docker-compose -f "$PROJECT_DIR/docker-compose.yml" up -d db

# Wait for Postgres to be ready
echo "       Waiting for database to be ready..."
for i in $(seq 1 15); do
  if docker-compose -f "$PROJECT_DIR/docker-compose.yml" exec -T db pg_isready -U fantasy_draft_kit -q 2>/dev/null; then
    echo "       Database is ready."
    break
  fi
  if [ "$i" -eq 15 ]; then
    echo "       WARNING: Database may not be ready yet. Continuing anyway..."
  fi
  sleep 1
done

# 2. Start Rails server
echo "[2/3] Starting Rails server on port 3639..."
cd "$BACKEND_DIR"
bundle exec rails server -p 3639 &
RAILS_PID=$!

# Wait for Rails to start
echo "       Waiting for Rails to start..."
for i in $(seq 1 20); do
  if curl -s -o /dev/null http://localhost:3639 2>/dev/null; then
    echo "       Rails is ready."
    break
  fi
  if [ "$i" -eq 20 ]; then
    echo "       WARNING: Rails may not be ready yet. Opening browser anyway..."
  fi
  sleep 1
done

# 3. Open browser
echo "[3/3] Opening browser..."
open http://localhost:3639

echo ""
echo "========================================="
echo "  FantasyDraftKit is running!"
echo "  Web UI: http://localhost:3639"
echo ""
echo "  Press Ctrl+C or close this window"
echo "  to shut everything down."
echo "========================================="
echo ""

# Keep the script alive, waiting for the Rails process
wait "$RAILS_PID"
