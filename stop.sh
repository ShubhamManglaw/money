#!/usr/bin/env bash

# Kickbacks Simulator - Fleet Shutdown Script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

echo "========================================================"
echo "🛑 Stopping Kickbacks Distributed Simulator Fleet..."
echo "========================================================"

cleanup_port() {
  local port=$1
  local pids=""
  if command -v lsof >/dev/null 2>&1; then
    pids=$(lsof -ti :$port 2>/dev/null || true)
  elif command -v fuser >/dev/null 2>&1; then
    pids=$(fuser $port/tcp 2>/dev/null | tr -s ' ' '\n' | grep -v '^$' || true)
  elif command -v ss >/dev/null 2>&1; then
    pids=$(ss -lptn "sport = :$port" 2>/dev/null | grep -o 'pid=[0-9]*' | cut -d'=' -f2 | sort -u || true)
  fi

  if [ -n "$pids" ]; then
    echo "   -> Stopping process on port $port (PID: $pids)..."
    for p in $pids; do
      kill -9 "$p" 2>/dev/null || true
    done
  fi
}

for p in $(seq 3001 3010); do
  cleanup_port $p
done
cleanup_port 5174

# Kill any leftover node simulator, server, and vite processes
pkill -9 -f "simulator.js" 2>/dev/null || true
pkill -9 -f "server.js" 2>/dev/null || true
pkill -9 -f "vite" 2>/dev/null || true

echo "========================================================"
echo "✅ Backend instance(s) and dashboard stopped successfully."
echo "========================================================"
