#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/wendyliga/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: wendyliga
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/DonutWare/Fladder

APP="Fladder"
var_tags="${var_tags:-media}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  update_os
  if [[ ! -d /opt/fladder ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -fsSL https://api.github.com/repos/DonutWare/Fladder/releases/latest | grep -m1 '"tag_name"' | sed -E 's/.*"tag_name"\s*:\s*"([^"]+)".*/\1/')
  if [[ -z "$RELEASE" ]]; then
    msg_error "Failed to fetch latest release version from GitHub"
    exit 1
  fi
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "Stopping Service"
    systemctl stop fladder
    msg_ok "Stopped Service"

    msg_info "Updating ${APP} to ${RELEASE}"
    temp_file=$(mktemp)
    URL="https://github.com/DonutWare/Fladder/releases/download/${RELEASE}/Fladder-Linux-${RELEASE#v}.zip"
    msg_info "Downloading from $URL"

    if ! $STD curl -fSL "$URL" -o "$temp_file"; then
      msg_error "Download failed: $URL"
      rm -f "$temp_file"
      exit 1
    fi
    rm -rf /opt/fladder/*
    if ! $STD unzip -o "$temp_file" -d /opt/fladder; then
      msg_error "Extraction failed from $temp_file"
      rm -f "$temp_file"
      exit 1
    fi
    rm -f "$temp_file"
    chmod +x /opt/fladder/Fladder
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated ${APP} to ${RELEASE}"

    msg_info "Starting Service"
    systemctl start fladder
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  else
    msg_ok "No update required. ${APP} is already at v${RELEASE}"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following IP:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
