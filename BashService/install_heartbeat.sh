#!/bin/bash

echo "FullcheckAPP Webhook Heartbeat Service Install"
echo "--------------------------"

read -p "Please enter the WebhookID you want to send a live signal to: " WebhookID
if [ -z "$WebhookID" ]; then
    echo "Error: Webhook ID cannot be empty. Installation was cancelled."
    exit 1
fi

read -p "Please enter INTERVAL (>=30 seconds): " INTERVAL
if [ -z "$INTERVAL" ] || [ "$INTERVAL" -lt 30 ]; then
    echo "Error: Interval must be at least 30 seconds."
    exit 1
fi

URL="https://fullcheckapp.com/webhook/$WebhookID"
SCRIPT_PATH="/usr/local/bin/heartbeat.sh"

sudo tee "$SCRIPT_PATH" > /dev/null <<EOF
#!/bin/bash
URL="$URL"
INTERVAL=$INTERVAL
while true; do
    response=\$(curl -s -o /dev/null -w "%{http_code}" "\$URL")
    echo "Heartbeat response at \$(date): \$response"
    sleep \$INTERVAL
done
EOF

sudo chmod +x "$SCRIPT_PATH"

SERVICE_PATH="/etc/systemd/system/fullcheckapp.service"
sudo tee "$SERVICE_PATH" > /dev/null <<EOF
[Unit]
Description=Fullcheckapp Heartbeat Service
After=network.target

[Service]
ExecStart=$SCRIPT_PATH
Restart=always
User=$(whoami)

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable fullcheckapp.service
sudo systemctl start fullcheckapp.service

echo "✅ The FullcheckAPP Webhook Heartbeat Service was successfully installed and started."
echo "ℹ️  To check service status: sudo systemctl status fullcheckapp.service"
