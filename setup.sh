
#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
echo "🚀 [1/5] Updating & Installing Base..."
apt-get update && apt-get install -y -qq curl wget git unzip jq gnupg2 build-essential pkg-config libssl-dev cmake make gcc python3-pip openjdk-21-jre-headless 2>/dev/null | tail -3
echo "🐳 [2/5] Docker Ready (DinD enabled)."
echo "⚔️ [3/5] Installing Sliver C2..."
curl -sSL https://sliver.sh/install | bash -s -- -y 2>&1 | tail -2
echo 'export PATH=$PATH:/root/.sliver/bin:/home/vscode/.sliver/bin' >> /etc/profile.d/sliver.sh
echo "🛡️ [4/5] Launching Wazuh SIEM..."
mkdir -p /workspaces/purple-lab/wazuh
cat > /workspaces/purple-lab/wazuh/docker-compose.yml <<'EOF'
version: '3.8'
services:
  wazuh.manager:
    image: wazuh/wazuh:4.9.0
    hostname: wazuh.manager
    ports: ["5601:5601", "1514:1514/udp", "1515:1515", "514:514/udp", "8443:8443"]
    environment:
      - WAZUH_DASHBOARD_USERNAME=admin
      - WAZUH_DASHBOARD_PASSWORD=SecretPassword123!
      - WAZUH_API_USER=wazuh-wui
      - WAZUH_API_PASSWORD=SecretPassword123!
    ulimits: { memlock: { soft: -1, hard: -1 }, nofile: { soft: 65536, hard: 65536 } }
    deploy: { resources: { limits: { memory: 3G } } }
    volumes: [ "wazuh_data:/var/ossec/data", "wazuh_logs:/var/ossec/logs" ]
volumes: { wazuh_data: {}, wazuh_logs: {} }
EOF
cd /workspaces/purple-lab/wazuh && docker compose up -d 2>&1 | tail -3
echo "🧪 [5/5] Installing Stratus Red Team & Sigma..."
go install github.com/DataDog/stratus-red-team/v2@latest 2>&1 | tail -1
go install github.com/SigmaHQ/sigma/cmd/sigmac@latest 2>&1 | tail -1
echo 'export PATH=$PATH:$(go env GOPATH)/bin' >> /etc/profile.d/stratus.sh
apt-get clean && rm -rf /var/lib/apt/lists/*
echo "✅ LAB READY. Run: sliver-client  |  Open Port 5601 for Wazuh  |  Attack: stratus detonate linux.credential-access.dump-linux-passwords"
