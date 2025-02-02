#!/bin/bash


echo "FullcheckAPP Webhook Heartbeat Service Install"
echo "--------------------------"

# Kullanıcıdan URL al
read -p Please enter the WebhookID you want to send a live signal to: " WebhookID

# if WebhookID is null, exit
if [ -z "$WebhookID" ]; then
    echo "Error: Webhook ID cannot be empty. Installation was cancelled."
    exit 1
fi
read -p Please enter INTERVAL you want to send a live signal to: " INTERVAL

if [ -z "$INTERVAL" ]; then
    echo "Error: Webhook ID cannot be empty. Installation was cancelled."
    exit 1
fi
if [ "$INTERVAL" -lt 30 ]; then
    echo "Error: Interval cannot be less than 30 seconds."
    exit 1
fi

# Script file create
URL="https://fullcheckapp.com/webhook/$WebhookID"
SCRIPT_PATH="/usr/local/bin/heartbeat.sh"
echo "#!/bin/bash" | sudo tee "$SCRIPT_PATH" > /dev/null
echo "URL=\"$URL\"" | sudo tee -a "$SCRIPT_PATH" > /dev/null
echo "INTERVAL= $INTERVAL" | sudo tee -a "$SCRIPT_PATH" > /dev/null
cat << 'EOF' | sudo tee -a "$SCRIPT_PATH" > /dev/null
while true; do
    response=$(curl -s -o /dev/null -w "%{http_code}" "$URL")
    if [ "$response" -eq 200 ]; then
        echo "Heartbeat sent successfully at $(date)"
    else
        echo "Heartbeat failed with status code: $response"
    fi
    sleep "$INTERVAL"
done
EOF

# Script running permission
sudo chmod +x "$SCRIPT_PATH"

# Service file create
SERVICE_PATH="/etc/systemd/system/fullcheckapp.service"
echo "[Unit]" | sudo tee "$SERVICE_PATH" > /dev/null
echo "Description=Fullcheckapp Service" | sudo tee -a "$SERVICE_PATH" > /dev/null
echo "After=network.target" | sudo tee -a "$SERVICE_PATH" > /dev/null
echo "" | sudo tee -a "$SERVICE_PATH" > /dev/null
echo "[Service]" | sudo tee -a "$SERVICE_PATH" > /dev/null
echo "ExecStart=$SCRIPT_PATH" | sudo tee -a "$SERVICE_PATH" > /dev/null
echo "Restart=always" | sudo tee -a "$SERVICE_PATH" > /dev/null
echo "User=nobody" | sudo tee -a "$SERVICE_PATH" > /dev/null
echo "Group=nogroup" | sudo tee -a "$SERVICE_PATH" > /dev/null
echo "" | sudo tee -a "$SERVICE_PATH" > /dev/null
echo "[Install]" | sudo tee -a "$SERVICE_PATH" > /dev/null
echo "WantedBy=multi-user.target" | sudo tee -a "$SERVICE_PATH" > /dev/null

# Systemd reload again
sudo systemctl daemon-reload

# Service enable and start
sudo systemctl enable fullcheckapp.service
sudo systemctl start fullcheckapp.service

# Install finished
echo "The FullcheckAPP Webhook Heartbeat Service  was successfully installed and started.."
echo "To check service status: sudo systemctl status fullcheckapp.service"