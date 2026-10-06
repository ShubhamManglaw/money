# 💰 Money · Kickbacks Multi-Client Fleet Simulator & Dashboard

A self-contained, enterprise-grade local simulator and real-time dashboard for [Kickbacks.ai](https://kickbacks.ai/). Simulate concurrent virtual clients, auto-consent to Boosted earnings, and monitor telemetry, view metrics, and real-time revenues through an interactive React dashboard.

---

## ⚡ Quick Start (Run Locally)

You can clone and run the entire stack on any local machine in 3 simple commands:

```bash
# 1. Clone the repository
git clone https://github.com/ShubhamManglaw/money.git
cd money

# 2. Start the entire fleet (auto-installs dependencies on first run)
./start.sh
```

Once started:
1. Open **[http://localhost:5174](http://localhost:5174)** in your web browser.
2. Enter the dashboard password: **`Ankitsin`**
3. Click **`+ Connect Account`** in the top navigation or dashboard.
4. Click **`Log in via kickbacks.ai`** to authenticate with Google:
   - A secure Google sign-in window opens.
   - Complete Google login for your Kickbacks account.
   - The dashboard automatically captures tokens, accepts Kickbacks Terms of Service & Boosted consent scopes, saves the account, and starts the simulation worker fleet immediately.
5. Watch your live metrics, view ticks, and real earnings update in real-time!

---

## 🛠️ Features

- **One-Click Account Connection**: In-dashboard Google OAuth integration directly connected to `kickbacks.ai`. No manual token hunting required.
- **Auto-Consent Engine**: Automatically executes TOS agreement (`tos_accepted_version: "2026-03-01"`) and Boosted Mode permissions (`boosted_ack: true`) upon login.
- **Manual Token Import**: Option to import existing Google refresh tokens or configure virtual client scales manually.
- **Multi-Client Concurrency**: Run scalable concurrent virtual client instances per account with randomized user-agents, realistic browsing sessions, and metric ping cadences.
- **Real-Time Analytics Dashboard**: Live graphs, micros conversion, revenue run-rate projections, health status, and raw terminal log streaming.
- **Zero Configuration Setup**: `./start.sh` automatically installs dependencies, cleans up conflicting ports, handles missing configs gracefully, and boots the backend + frontend.

---

## 📋 Available Commands

| Command | Description |
| :--- | :--- |
| `./start.sh` | Cleanly boots backend instance(s) and Vite React frontend |
| `./stop.sh` | Terminates all running simulator worker processes and backends |
| `npm run setup` | Installs dependencies across both `backend` and `frontend` |
| `npm run backend` | Runs the standalone backend server on port 3001 |
| `npm run frontend` | Runs the Vite development server on port 5174 |
| `npm run build` | Compiles the production React dashboard bundle |

---

## ⚙️ Configuration File (`backend/config.json`)

When you connect accounts through the dashboard UI, they are automatically written to `backend/config.json`:

```json
[
  {
    "name": "account_1_7fb87c",
    "clientId": "7fb87cd937d4961ed0a5c1f1",
    "refreshToken": "aqtOC8-QUFeig...",
    "scale": 10
  }
]
```

You can add, edit, or delete accounts anytime directly from the dashboard **Config** tab.

---

## 🔒 Security & Privacy

- All credentials and refresh tokens remain strictly on your local machine (`backend/config.json` is gitignored).
- Dashboard access is protected with local token authentication.
- All requests communicate directly with Kickbacks endpoints over TLS.
