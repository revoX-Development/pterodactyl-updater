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
        
    else
        echo "Pterodactyl is not up to date. Update Pterodactyl"
    fi
}



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
        if [ "$dist_version" != "11" || $dist_version == '10']; then
            output "Unsupported Debian version. Only Debian 10 is supported."
            exit 2
        fi
    elif [ "$lsb_dist" = "centos" ]; then
        if [ "$dist_version" != "8" ]; then
            output "Unsupported CentOS version. Only CentOS Stream 8 is supported."
            exit 2
        fi
    elif [ "$lsb_dist" != "ubuntu" ] && [ "$lsb_dist" != "debian" ] && [ "$lsb_dist" != "fedora" ] && [ "$lsb_dist" != "centos" ] && [ "$lsb_dist" != "rhel" ] && [ "$lsb_dist" != "rocky" ] && [ "$lsb_dist" != "almalinux" ]; then
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
    elif [ $OS == "debian" ]; then
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