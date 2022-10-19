#!/bin/bash

set -e


SCRIPT_VERSION="v0.0.1"
SCRIPT_NAME="Pterodactyl Wings Updater"
LOG_PATH="/var/log/pterodactyl-updater.log"
GITHUB_BASE_URL="https://raw.githubusercontent.com/revoX-Development/pterodactyl-updater/"



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
    echo -e "\n\n* $SCRIPT_NAME $(date) \n\n" >>$LOG_PATH

  bash <(curl -s "$1") | tee -a $LOG_PATH
  [[ -n $2 ]] && execute "$2"
}

done=false

output "$SCRIPT_NAME  $SCRIPT_VERSION"
output
output "Copyright (C) 2022, revoX-Development"
output "https://github.com/revoX-development/pterodactyl-updater"
output
output "Donations: https://revox.link/donate"
output "This script is not associated with the official Pterodactyl Project."

output

output "This script will update your Pterodactyl Wings installation."


install_options(){
    output "Please select your upgrade option:"
    output "[1] Upgrade panel to the latest version"
    output "[2] Upgrade wings to the latest version."
    output "[3] Upgrade panel and wings to the latest version."
    read -r choice
    case $choice in
        1 ) installoption=1
            output "You have selected the pterodactyl panel upgrade option."
            ;;
        2 ) installoption=2
            output "You have selected the pterodactyl wings upgrade option."
            ;;
        3 ) installoption=3
            output "You have selected the pterodactyl panel and wings upgrade option."
            ;;
    esac
}

get_latest_release() {
  curl --silent "https://api.github.com/repos/pterodactyl/panel/releases/latest" | 
    grep '"tag_name":' |                                            
    sed -E 's/.*"([^"]+)".*/\1/'                                    
}


PTERODACTYL_VERSION="$(get_latest_release "pterodactyl/panel")"

getting_rightversion_ptero(){
    if [ $PTERODACTYL_VERSION = $PTERODACTYL_VERSION ]; then
        echo "Pterodactyl is up to date. Exiting Updating Script"
        exit 2
    else
        echo "Update from Pterodactyl avaible. Update Pterodactyl"
    fi
}

lsb_dist="$(. /etc/os-release && echo "$ID")"
dist_version="$(. /etc/os-release && echo "$VERSION_ID")"

detect_distro() {
  if [ -r /etc/os-release ]; then
        lsb_dist="$(. /etc/os-release && echo "$ID")"
        dist_version="$(. /etc/os-release && echo "$VERSION_ID")"
        if [ "$lsb_dist" = "rhel" ] || [ "$lsb_dist" = "rocky" ] || [ "$lsb_dist" = "almalinux" ]; then
            dist_version="$(echo $dist_version | awk -F. '{print $1}')"
        fi
    else
        exit 1
    fi
    
    if [ "$lsb_dist" =  "ubuntu" ]; then
        if  [ "$dist_version" != "20.04" ]; then
            output "Unsupported Ubuntu version. Only Ubuntu 20.04 is supported."
            exit 2
        fi
    elif [ "$lsb_dist" = "debian" ]; then
        if [ "$dist_version" < "10" ]; then
            output "Unsupported Debian version. Only Debian 10 & 11 is supported."
            exit 2
        fi
    elif [ "$lsb_dist" = "centos" ]; then
        if [ "$dist_version" != "8" ]; then
            output "Unsupported CentOS version. Only CentOS Stream 8 is supported."
            exit 2
        fi
    elif [ "$lsb_dist" != "ubuntu" ] && [ "$lsb_dist" != "debian" ] && [ "$lsb_dist" != "centos" ]; then
        output "Unsupported operating system."
        output ""
        output "Supported OS:"
        output "Ubuntu: 20.04"
        output "Debian: 11"
        output "CentOS Stream: 8"
        exit 2
    fi
}

detecting_webserver(){
if [ $lsb_dist == "debian "]; then
 echo "You're using $OS"
  echo "Set Permissions for webserver"
  chown -R www-data:www-data /var/www/pterodactyl/*
if [ $lsb_dist == "centos" ]; then
    echo "You're using $OS"
    echo "Detecting nginx or apache2"
    if [ -f /etc/apache2]; then
    echo "using apache2 on $OS" 
    chown -R apache:apache /var/www/pterodactyl/*
    if  [ -f /etc/nginx]; then
    echo "using nginx on $OS"
    chown -R nginx:nginx /var/www/pterodactyl/*
else 
 echo "No webserver detected"
fi
fi
fi
fi
}

update_panel(){
    echo "Detecting OS..."
    detect_distro
    echo "Detected $lsb_dist $dist_version"
    echo "Updating Pterodactyl Panel"
    echo "Enable Maintanance Mode"
    ch /var/www/pterodactyl
    php artisan down
    echo "Donwloading latest panel update ..."
    curl -L https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz | tar -xzv
    echo "Downloding completed"
    echo "Set correct permissions"
    chmod -R 755 storage/* bootstrap/cache
    echo "Permissions set correctly"
    echo "Updating depencies"
    composer install --no-dev --optimize-autoloader
    echo "Depencies upated"
    echo "Clearing cache"
    php artisan view:clear
    php artisan config:clear
    echo "Cache cleared"
    echo "Upating database"
    php artisan migrate --seed --force
    echo "Updated Database"
    echo "Detecting OS and getting webserver"
    detecting_webserver
    echo "Restarting Queue Workers"
    php artisan queue:restart
    echo "Disable Maintanance Mode"
    php artisan up
    echo "Panel is now updated to the latest version. Now $PTERODACTYL_VERSION"
}

goodbey_ptero(){
    echo "Thanks for using this script"
    echo "Goodbye"
    exit 0
}

upgrade_pterodactyl(){
  getting_rightversion_ptero
  update_panel
  goodbey_ptero
}

get_latest_release_wings() {
  curl --silent "https://api.github.com/repos/pterodactyl/wings/releases/latest" | 
    grep '"tag_name":' |                                            
    sed -E 's/.*"([^"]+)".*/\1/'                                    
}


WINGS_VERSION="$(get_latest_release_wings "pterodactyl/wings")"

getting_rightversion_wings(){
    if [ $WINGS_VERSION == $WINGS_VERSION ]; then
        echo "Wings is up to date"
    else
        echo "Wings is not up to date"
        echo "Updating Wings"
    fi
}


update_wings(){
    detect_distro
    output "Detected $lsb_dist $dist_version"
    echo "Updating Wings"
    echo "Stop wings"
    systemctl stop wings
    echo "Stoppend wings"
    echo "Downloading latest wings update ..."
    curl -L -o /usr/local/bin/wings "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_$([[ "$(uname -m)" == "x86_64" ]] && echo "amd64" || echo "arm64")"
    echo "Download completed"
    echo "Set wings to executable"
    chmod u+x /usr/local/bin/wings
    echo "Completed"
    echo "Start wings"
    systemctl start wings
   
}

goodbey_wings(){
    echo "Wings is now updated to $WINGS_VERSION"
    echo "Thanks for using this script"
    echo "Goodbye"
    exit 0
}

upgrade_wings(){
  getting_rightversion_wings
  update_wings
  goodbey_wings
}

install_options
case $installoption in 
    1)  upgrade_pterodactyl
        ;;
    2)  upgrade_wings
        ;;
    3)  upgrade_pterodactyl
	      upgrade_wings
esac