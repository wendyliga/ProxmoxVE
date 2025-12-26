#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: wendyliga
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/DonutWare/Fladder

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  curl \
  wget \
  unzip \
  libmpv-dev \
  jq
msg_ok "Installed Dependencies"

msg_info "Installing ${APPLICATION}"
RELEASE=$(curl -fsSL https://api.github.com/repos/DonutWare/Fladder/releases/latest | jq -r '.tag_name')

cd /opt
$STD wget -q "https://github.com/DonutWare/Fladder/releases/download/${RELEASE}/Fladder-Linux-${RELEASE#v}.zip"
$STD unzip -o "Fladder-Linux-${RELEASE#v}.zip" -d fladder

rm -f "Fladder-Linux-${RELEASE#v}.zip"
chmod +x /opt/fladder/Fladder
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
msg_ok "Installed ${APPLICATION}"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/fladder.service
[Unit]
Description=Fladder - Jellyfin Frontend
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/fladder
ExecStart=/opt/fladder/Fladder
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now fladder
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
