#!/usr/bin/env bash

# Kickbacks Simulator - Single Account Fleet Startup Script
# Starts 1 Backend (port 3001, 5 clients) and 1 Frontend Dashboard (port 5174)

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR"

# Auto-install dependencies if missing
if [ ! -d "$DIR/backend/node_modules" ]; then
  echo "📦 Installing backend dependencies..."
  (cd "$DIR/backend" && npm install)
fi

if [ ! -d "$DIR/frontend/node_modules" ]; then
  echo "📦 Installing frontend dependencies..."
  (cd "$DIR/frontend" && npm install)
fi

NUM_ACCOUNTS=$(node -e 'try { const fs=require("fs"); const c=JSON.parse(fs.readFileSync("./backend/config.json")); console.log(Math.max(1, Array.isArray(c) ? c.length : 1)); } catch(e) { console.log(1); }')
TOTAL_INSTANCES=${TOTAL_INSTANCES:-$NUM_ACCOUNTS}
CLIENTS_PER_INSTANCE=${CLIENTS_PER_INSTANCE:-5}
TOTAL_CLIENTS=$((TOTAL_INSTANCES * CLIENTS_PER_INSTANCE))

echo "========================================================"
echo "🚀 Starting Kickbacks Simulator Fleet ($TOTAL_INSTANCES Backend(s), $TOTAL_CLIENTS clients total)..."
echo "========================================================"

# Make log directory
mkdir -p "$DIR/logs"

# Function to stop existing processes on target ports
cleanup_port() {
  local port=$1
  local pid=$(lsof -ti :$port 2>/dev/null)
  if [ -n "$pid" ]; then
    echo "⚠️  Cleaning up old process on port $port (PID: $pid)..."
    kill -9 $pid 2>/dev/null || true
  fi
}

echo "1. Checking and cleaning existing ports..."
for p in $(seq 3001 3010); do
  cleanup_port $p
done
cleanup_port 5174
pkill -9 -f "simulator.js" 2>/dev/null || true
pkill -9 -f "server.js" 2>/dev/null || true
echo "2. Starting $TOTAL_INSTANCES dedicated backend instances ($CLIENTS_PER_INSTANCE clients each, $TOTAL_CLIENTS clients total)..."
for i in $(seq 1 $TOTAL_INSTANCES); do
  port=$((3000 + i))
  account_idx=$((i - 1))
  account_name=$(node -e "try { const fs=require('fs'); const c=JSON.parse(fs.readFileSync('./backend/config.json')); console.log(c[$account_idx]?.name || 'account_$i'); } catch(e) { console.log('account_$i'); }")

  (
    PORT=$port \
    INSTANCE_NAME="inst_${i} · ${account_name}" \
    ACCOUNT_INDEX=$account_idx \
    DEDICATED_ACCOUNT=true \
    CLIENTS_PER_INSTANCE=$CLIENTS_PER_INSTANCE \
    TOTAL_INSTANCES=$TOTAL_INSTANCES \
    nohup node "$DIR/backend/server.js" </dev/null >> "$DIR/logs/backend_$i.log" 2>&1 &
  )
  echo "   -> [Backend $i] Dedicated to '$account_name' ($CLIENTS_PER_INSTANCE clients) on http://localhost:$port"
done

echo "3. Starting React Frontend Dashboard..."
(
  cd "$DIR/frontend" && \
  nohup ./node_modules/.bin/vite --port 5174 --host 0.0.0.0 </dev/null >> "$DIR/logs/frontend.log" 2>&1 &
)
echo "   -> [Frontend] Dashboard starting on http://localhost:5174"

sleep 2

echo ""
echo "========================================================"
echo "✨ Fleet of $TOTAL_INSTANCES dedicated backends is live and running!"
echo "   - Dashboard: http://localhost:5174"
for i in $(seq 1 $TOTAL_INSTANCES); do
  port=$((3000 + i))
  account_idx=$((i - 1))
  account_name=$(node -e "try { const fs=require('fs'); const c=JSON.parse(fs.readFileSync('./backend/config.json')); console.log(c[$account_idx]?.name || 'account_$i'); } catch(e) { console.log('account_$i'); }")
  echo "   - Backend $i ($account_name): http://localhost:$port"
done
echo "========================================================"
