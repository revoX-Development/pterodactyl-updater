if [[ $EUID -ne 0 ]]; then
  echo "* This script must be executed with root privileges (sudo)." 1>&2
  exit 1
fi


if ! [ -x "$(command -v curl)" ]; then
  echo "* curl is required in order for this script to work."
  echo "* install using apt (Debian and derivatives) or yum/dnf (CentOS)"
  exit 1
fi

if ! [ -f /etc/pterodactyl]; then
  echo "* Pterodactyl is not installed on this server."
  echo "* Please install Pterodactyl first or run this script on a different server."
  exit 1
fi

get_latest_release() {
  curl --silent "https://api.github.com/repos/pterodactyl/panel/releases/latest" | 
    grep '"tag_name":' |                                            
    sed -E 's/.*"([^"]+)".*/\1/'                                    
}


PTERODACTYL_VERSION="$(get_latest_release "pterodactyl/panel")"

getting_rightversion(){
    if [ $PTERODACTYL_VERSION !== $PTERODACTYL_VERSION ]; then
        echo "Pterodactyl is up to date"
        exit 0
    else
        echo "Pterodactyl is not up to date"
        echo "Updating Pterodactyl"
        update_panel
    fi
}

detecting_webserver(){
    if [ "$OS" == "debian" ]; then
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

update_panel
goodbey
done