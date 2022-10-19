#!/bin/bash

set -e


SCRIPT_VERSION="v0.0.1"
SCRIPT_NAME="Pterodactyl Wings Updater"

if [[ $EUID -ne 0 ]]; then
  echo "* This script must be executed with root privileges (sudo)." 1>&2
  exit 1
fi


if ! [ -x "$(command -v curl)" ]; then
  echo "* curl is required in order for this script to work."
  echo "* install using apt (Debian and derivatives) or yum/dnf (CentOS)"
  exit 1
fi

output() {
  echo -e "* ${1}"
}

execute() {
  echo -e "\n\n* pterodactyl-installer $(date) \n\n" >>$LOG_PATH

  bash <(curl -s "$1") | tee -a $LOG_PATH
  [[ -n $2 ]] && execute "$2"
}

done=false

output "$SCRIPT_NAME @ $SCRIPT_VERSION"
output
output "Copyright (C) 2022, revoX-Development"
output "https://github.com/revoX-development/pterodactyl-updater"
output
output "Donations: https://revox.linK/donate"
output "This script is not associated with the official Pterodactyl Project."

output

PANEL_LATEST_UPDATER="$GITHUB_BASE_URL/$SCRIPT_VERSION/update-panel.sh"

WINGS_LATEST_UPDATER="$GITHUB_BASE_URL/$SCRIPT_VERSION/update_wings.sh"


while [ "$done" == false ]; do
  options=(
    "Update the panel"
    "update Wings"
    "Update both [0] and [1] on the same machine (wings script runs after panel)"
  )

  actions=(
    "$PANEL_LATEST_UPDATER"
    "$WINGS_LATEST_UPDATER"
    "$PANEL_LATEST_UDPATER;$WINGS_LATEST_UPDATER"
  )

  output "Choose what you want to do:"

  for i in "${!options[@]}"; do
    output "[$i] ${options[$i]}"
  done

  echo -n "* Input 0-$((${#actions[@]} - 1)): "
  read -r action

  [ -z "$action" ] && error "Input is required" && continue

  valid_input=("$(for ((i = 0; i <= ${#actions[@]} - 1; i += 1)); do echo "${i}"; done)")
  [[ ! " ${valid_input[*]} " =~ ${action} ]] && error "Invalid option"
  [[ " ${valid_input[*]} " =~ ${action} ]] && done=true && IFS=";" read -r i1 i2 <<<"${actions[$action]}" && execute "$i1" "$i2"
done