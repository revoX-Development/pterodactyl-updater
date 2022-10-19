if [[ $EUID -ne 0 ]]; then
  echo "* This script must be executed with root privileges (sudo)." 1>&2
  exit 1
fi


if ! [ -x "$(command -v curl)" ]; then
  echo "* curl is required in order for this script to work."
  echo "* install using apt (Debian and derivatives) or yum/dnf (CentOS)"
  exit 1
fi



get_latest_release() {
  curl --silent "https://api.github.com/repos/pterodactyl/panel/releases/latest" | 
    grep '"tag_name":' |                                            
    sed -E 's/.*"([^"]+)".*/\1/'                                    
}


PTERODACTYL_VERSION="$(get_latest_release "pterodactyl/panel")"

getting_rightversion(){
    if [ $PTERODACTYL_VERSION = $PTERODACTYL_VERSION ]; then
        echo "Pterodactyl is up to date"
        exit 1
    else
        echo "Pterodactyl is not up to date. Update Pterodactyl"
    fi
}



detect_distro() {
  if [ -f /etc/os-release ]; then
    # freedesktop.org and systemd
    . /etc/os-release
    OS=$(echo "$ID" | awk '{print tolower($0)}')
    OS_VER=$VERSION_ID
  elif type lsb_release >/dev/null 2>&1; then
    # linuxbase.org
    OS=$(lsb_release -si | awk '{print tolower($0)}')
    OS_VER=$(lsb_release -sr)
  elif [ -f /etc/lsb-release ]; then
    # For some versions of Debian/Ubuntu without lsb_release command
    . /etc/lsb-release
    OS=$(echo "$DISTRIB_ID" | awk '{print tolower($0)}')
    OS_VER=$DISTRIB_RELEASE
  elif [ -f /etc/debian_version ]; then
    # Older Debian/Ubuntu/etc.
    OS="debian"
    OS_VER=$(cat /etc/debian_version)
  elif [ -f /etc/SuSe-release ]; then
    # Older SuSE/etc.
    OS="SuSE"
    OS_VER="?"
  elif [ -f /etc/redhat-release ]; then
    # Older Red Hat, CentOS, etc.
    OS="Red Hat/CentOS"
    OS_VER="?"
  else
    # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
    OS=$(uname -s)
    OS_VER=$(uname -r)
  fi

  OS=$(echo "$OS" | awk '{print tolower($0)}')
  OS_VER_MAJOR=$(echo "$OS_VER" | cut -d. -f1)
}

detecting_webserver(){
    if [ $OS == "debian "]; then
    echo "You're using $OS"
        echo "Set Permissions for webserver"
        chown -R www-data:www-data /var/www/pterodactyl/*
    elif [ "$OS" == "centos" ]; then
    echo "You're using $OS"
    echo "Detecting nginx or apache2"
        if [ -f /etc/apache2]; then
        echo "using apache2 on $OS" 
        chown -R apache:apache /var/www/pterodactyl/*
        elif  [ -f /etc/nginx]; then
        echo   "using nginx on $OS"
        chown -R nginx:nginx /var/www/pterodactyl/*
        else 
        echo "No webserver detected"
    fi
    fi
}

update_panel(){
    echo "Detecting OS..."
    detect_distro
    if [ $OS == "centos " ]; then
        OS=centos
    elif [ $OS == "debian "]; then
        OS=debian
    elif [ $OS == "ubuntu " ]; then
        OS=ubuntu
    else
        echo "OS not supported"
        exit 1
    fi
    echo "* Updating Pterodactyl Panel"
    echo "Enable Maintanance Mode"
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
    echo "Panel is now updated to the latest version\n Now $PTERODACTYL_VERSION"
}

goodbey(){
    echo "Thanks for using this script"
    echo "Goodbye"
    exit 0
}
getting_rightversion
update_panel
goodbey
done