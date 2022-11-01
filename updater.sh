#!/bin/bash

set -e


SCRIPT_VERSION="v0.0.2"
SCRIPT_NAME="Pterodactyl & Wings Updater"
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
output "Donate: https://revox.link/donate"
output "This script is not associated with the official Pterodactyl Project."

output

output "This script will update your Pterodactyl & Wings installation."


install_options(){
    output "Please select your upgrade option:"
    output "[1] Upgrade panel "
    output "[2] Upgrade wings"
    output "[3] Upgrade panel & wings"
    read -r choice
    case $choice in
        1 ) installoption=1
            output "You have selected the Panel upgrade option."
            ;;
        2 ) installoption=2
            output "You have selected the Wings upgrade option."
            ;;
        3 ) installoption=3
            output "You have selected the Panel and Wings upgrade option."
            ;;
    esac
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
         OS=ubuntu
        fi
    elif [ "$lsb_dist" = "debian" ]; then
        OS=debian
        fi
    elif [ "$lsb_dist" = "centos" ]; then
        OS=centos
        fi
        fi
    elif [ "$lsb_dist" != "ubuntu" ] && [ "$lsb_dist" != "debian" ] && [ "$lsb_dist" != "centos" ]; then
        output "Unsupported operating system."
        output ""
        output "Supported OS:"
        output "Ubuntu"
        output "Debian"
        output "CentOS"
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
  update_panel
  goodbey_ptero
}


update_wings(){
    detect_distro
    echo "Detected $lsb_dist $dist_version"
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