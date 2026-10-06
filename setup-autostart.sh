#!/usr/bin/env bash

# Kickbacks Fleet - Boot Autostart Configuration Manager
# Enables or disables automatic startup of the fleet upon system boot

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ACTION="${1:---enable}"

SERVICE_DIR="$HOME/.config/systemd/user"
SERVICE_FILE="$SERVICE_DIR/kickbacks-fleet.service"
CRON_MARKER="# kickbacks-fleet-autostart"
CRON_CMD="@reboot sleep 15 && $DIR/start.sh >> $DIR/logs/autostart.log 2>&1 $CRON_MARKER"

mkdir -p "$DIR/logs"

case "$ACTION" in
  --enable|enable)
    echo "========================================================"
    echo "⚙️  Configuring Boot Autostart for Kickbacks Fleet..."
    echo "========================================================"

    # 1. Systemd User Service
    if command -v systemctl >/dev/null 2>&1; then
      mkdir -p "$SERVICE_DIR"
      cat <<EOF > "$SERVICE_FILE"
[Unit]
Description=Kickbacks Fleet Simulator and Dashboard
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
KillMode=process
WorkingDirectory=$DIR
ExecStart=$DIR/start.sh
ExecStop=$DIR/stop.sh
StandardOutput=append:$DIR/logs/autostart.log
StandardError=append:$DIR/logs/autostart.log

[Install]
WantedBy=default.target
EOF

      systemctl --user daemon-reload >/dev/null 2>&1 || true
      systemctl --user enable kickbacks-fleet.service >/dev/null 2>&1 || true
      echo "✅ Enabled systemd user service: kickbacks-fleet.service"

      # Enable user lingering so service launches before graphical login
      if command -v loginctl >/dev/null 2>&1; then
        loginctl enable-linger "$(whoami)" >/dev/null 2>&1 || true
        echo "✅ Enabled user lingering via loginctl"
      fi
    fi

    # 2. Crontab @reboot fallback
    if command -v crontab >/dev/null 2>&1; then
      CURRENT_CRON=$(crontab -l 2>/dev/null || true)
      if ! echo "$CURRENT_CRON" | grep -Fq "$CRON_MARKER"; then
        (echo "$CURRENT_CRON"; echo "$CRON_CMD") | grep -v '^$' | crontab -
        echo "✅ Configured universal crontab @reboot fallback"
      else
        echo "ℹ️  Crontab @reboot entry already present"
      fi
    fi

    echo "========================================================"
    echo "🎉 Fleet will now automatically start on every boot!"
    echo "   Logs will be written to: $DIR/logs/autostart.log"
    echo "========================================================"
    ;;

  --disable|disable)
    echo "========================================================"
    echo "🛑 Disabling Boot Autostart for Kickbacks Fleet..."
    echo "========================================================"

    # 1. Disable systemd user service
    if command -v systemctl >/dev/null 2>&1; then
      systemctl --user disable kickbacks-fleet.service >/dev/null 2>&1 || true
      rm -f "$SERVICE_FILE"
      systemctl --user daemon-reload >/dev/null 2>&1 || true
      echo "✅ Removed systemd user service"
    fi

    # 2. Remove crontab entry
    if command -v crontab >/dev/null 2>&1; then
      CURRENT_CRON=$(crontab -l 2>/dev/null || true)
      if echo "$CURRENT_CRON" | grep -Fq "$CRON_MARKER"; then
        echo "$CURRENT_CRON" | grep -v "$CRON_MARKER" | crontab -
        echo "✅ Removed crontab entry"
      fi
    fi

    echo "========================================================"
    echo "✅ Boot autostart disabled."
    echo "========================================================"
    ;;

  --status|status)
    echo "========================================================"
    echo "📊 Boot Autostart Status"
    echo "========================================================"
    if command -v systemctl >/dev/null 2>&1 && [ -f "$SERVICE_FILE" ]; then
      echo "Systemd Service: Installed ($SERVICE_FILE)"
      systemctl --user is-enabled kickbacks-fleet.service 2>/dev/null || echo "Systemd Status: Disabled"
    else
      echo "Systemd Service: Not installed"
    fi

    if command -v crontab >/dev/null 2>&1; then
      if crontab -l 2>/dev/null | grep -Fq "$CRON_MARKER"; then
        echo "Crontab @reboot: Active"
      else
        echo "Crontab @reboot: Inactive"
      fi
    fi

    if command -v loginctl >/dev/null 2>&1; then
      LINGER_STATUS=$(loginctl show-user "$(whoami)" 2>/dev/null | grep Linger || echo "Unknown")
      echo "User Lingering: $LINGER_STATUS"
    fi
    echo "========================================================"
    ;;

  *)
    echo "Usage: $0 [--enable | --disable | --status]"
    exit 1
    ;;
esac
