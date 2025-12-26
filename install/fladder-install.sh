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
  unzip \
  libmpv-dev
msg_ok "Installed Dependencies"

msg_info "Installing ${APPLICATION}"
mkdir -p /opt/fladder
RELEASE=$(curl -fsSL https://api.github.com/repos/DonutWare/Fladder/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
if [[ -z "$RELEASE" ]]; then
  msg_error "Failed to fetch latest release version from GitHub"
  exit 1
fi
msg_info "Installing Fladder ${RELEASE}"
temp_file=$(mktemp)
URL="https://github.com/DonutWare/Fladder/releases/download/${RELEASE}/Fladder-Linux-${RELEASE#v}.zip"
msg_info "Downloading from $URL"

curl -fsSL "$URL" -o "$temp_file"
$STD unzip -o "$temp_file" -d /opt/fladder
rm -f "$temp_file"
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
