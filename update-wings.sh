if [[ $EUID -ne 0 ]]; then
  echo "* This script must be executed with root privileges (sudo)." 1>&2
  exit 1
fi


if ! [ -x "$(command -v curl)" ]; then
  echo "* curl is required in order for this script to work."
  echo "* install using apt (Debian and derivatives) or yum/dnf (CentOS)"
  exit 1
fi

if ! [ -f /etc/wings ]; then
  echo "* Wings is not installed on this server."
  echo "*Please install wings first or run this script on a different server."
  exit 1
fi

get_latest_release() {
  curl --silent "https://api.github.com/repos/pterodactyl/wings/releases/latest" | 
    grep '"tag_name":' |                                            
    sed -E 's/.*"([^"]+)".*/\1/'                                    
}


WINGS_VERSION="$(get_latest_release "pterodactyl/wings")"

getting_rightversion(){
    if [ $WINGS_VERSION !== $WINGS_VERSION ]; then
        echo "Wings is up to date"
        exit 0
    else
        echo "Wings is not up to date"
        echo "Updating Pterodactyl"
        update_wings
    fi
}


update_wings(){
    echo "Detecting OS..."
     if [ $OS == 'centos ']; then
        OS=centos
    elif [ $OS == "debian " ]; then
        OS=debian
    elif [ $OS == 'ubuntu ' ]; then
        OS=ubuntu
    else
        echo "OS not supported\nOnly supported OS are: Debian, Ubuntu and CentOS"
        exit 1
    fi
    echo "$OS detected"
    echo "* Updating Wings"
    echo "Stop wings"
    systemctl stop wings
    echo "Donwloading latest wings update ..."
    curl -L -o /usr/local/bin/wings "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_$([[ "$(uname -m)" == "x86_64" ]] && echo "amd64" || echo "arm64")"
    echo "Set wings to executable"
    chmod u+x /usr/local/bin/wings
    echo "Start wings"
    systemctl start wings
   
}

goodbey(){
    echo "Wings is now updated to the latest version"
    echo "Thanks for using this script"
    echo "Goodbye"
    exit 0
}

update_wings
goodbey
done