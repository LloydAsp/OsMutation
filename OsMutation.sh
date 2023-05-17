#!/bin/bash
# Reinstall Any OpenVZ/LXC VPS to Debian/CentOS/Alpine
# Author: Lloyd@nodeseek.com
# WARNING: A fresh system will be installed and all old data will be wiped.
# License: GPLv3; Partly based on https://gist.github.com/trimsj/c1fefd650b5f49ceb8f3efc1b6a1404d

function print_help(){
    echo -ne "\e[1;32m"
    cat <<- EOF
                                                                                     
		 ██████╗ ███████╗███╗   ███╗██╗   ██╗████████╗ █████╗ ████████╗██╗ ██████╗ ███╗   ██╗
		██╔═══██╗██╔════╝████╗ ████║██║   ██║╚══██╔══╝██╔══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║
		██║   ██║███████╗██╔████╔██║██║   ██║   ██║   ███████║   ██║   ██║██║   ██║██╔██╗ ██║
		██║   ██║╚════██║██║╚██╔╝██║██║   ██║   ██║   ██╔══██║   ██║   ██║██║   ██║██║╚██╗██║
		╚██████╔╝███████║██║ ╚═╝ ██║╚██████╔╝   ██║   ██║  ██║   ██║   ██║╚██████╔╝██║ ╚████║
		 ╚═════╝ ╚══════╝╚═╝     ╚═╝ ╚═════╝    ╚═╝   ╚═╝  ╚═╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝
                                                                                     
		Reinstall Any OpenVZ/LXC VPS to Debian/CentOS/Alpine;
		[warning] A fresh system will be installed and all old data will be wiped!
		Author: Lloyd@nodeseek.com
	EOF
    echo -ne "\e[m"
}

function read_virt_tech(){
    install virt-what
    cttype=$(virt-what)
    if [[ $cttype == "lxc" || $cttype == "openvz" ]]; then
    	echo -e '\e[1;32mYour container type: $cttype \e[m'
    else
    	while [ "$cttype" != 'lxc' -a "$cttype" != 'openvz' ] ; do
            echo -n "please input container type (lxc/openvz):"
            read cttype  < /dev/tty
        done
    fi
}

function install(){
    if [ -n "$(command -v apt)" ] ; then
        cmd1="apt-get"
        cmd2="apt-get install -y"
    elif [ -n "$(command -v yum)" ] ; then
        cmd1="yum"
        cmd2="yum install -y"
    elif [ -n "$(command -v dnf)" ] ; then
        cmd1="dnf"
        cmd2="dnf install -y"
    elif [ -n "$(command -v apk)" ] ; then
        cmd1="apk"
        cmd2="apk add"
    else
        echo "Error: Not Supported Os"
        exit 1
    fi
    $cmd1 update
    $cmd2 "$@"
}

function read_lxc_template(){
    server=http://images.linuxcontainers.org
    path=$(wget -qO- ${server}/meta/1.0/index-system | \
        grep -v edge | grep default | \
        awk '-F;' '(( $1=="debian" || $1=="centos" || $1=="alpine") && ( $3=="amd64" || $3=="i386")) {print $NF}')

    os_list=$( echo "$path" | sed -E 's%/images/(.*)/default/.*/%\1%g' | sed 's%/%-%g' )
    echo "$os_list" | nl

    while [ -z "${os_index##*[!0-9]*}" ]; 
    do
        echo -n "please select os (input number):"
        read os_index < /dev/tty
    done

    path=$( echo "$path" | head -n $os_index | tail -n 1)
    os_selected=$(echo "$os_list" | head -n $os_index | tail -n 1 )
    download_link=${server}/${path}/rootfs.tar.xz
}

function read_openvz_template(){
    releasetag="v0.0.1"
    os_list=$(wget -qO- "https://github.com/LloydAsp/OsMutation/releases/expanded_assets/v0.0.1" | \
        sed -nE '/tar.gz/s/.*>([^<>]+)\.tar\.gz.*/\1/p' | \
        grep -E "(debian)|(centos)|(alpine)" )
    echo "$os_list" | nl

    while [ -z "${os_index##*[!0-9]*}" ]; 
    do
        echo -n "please select os (input number):"
        read os_index < /dev/tty
    done

    os_selected=$( echo "$os_list" | head -n $os_index | tail -n 1)
    download_link="https://github.com/LloydAsp/OsMutation/releases/download/${releasetag}/${os_selected}.tar.gz"
}

function download_rootfs(){
    cd /
    mkdir /x

    if [ "$cttype" == 'lxc' ] ; then
        wget $download_link
        tar -C /x -xvf rootfs.tar.xz
    else
        wget -O rootfs.tar.gz $download_link
        tar -C /x -xzvf rootfs.tar.gz
    fi
}


function migrate_configuration(){
    # save root password and ssh directory
    sed -i '/^root:/d' /x/etc/shadow
    grep '^root:' /etc/shadow >> /x/etc/shadow
    [ -d /root/.ssh ] && cp -a /root/.ssh /x/root/

    # save network configuration
    dev=$(awk '$2 == 00000000 { print $1 }' /proc/net/route)
    [ -d /x/etc/network/ ] || mkdir -p /x/etc/network/
    ipaddr=$(ip addr show dev $dev | grep global | awk '($1=="inet") {print $2}' | cut -d/ -f1 | head -1)
    hostname=$(hostname)

    if [ -f /etc/network/interfaces ] ; then
        cp -rf /etc/network/interfaces /x/etc/network/interfaces
    else
        cat > /x/etc/network/interfaces <<- EOF
		    auto lo
		    iface lo inet loopback

		    auto $dev
		    iface $dev inet static
		    address $ipaddr
		    netmask 255.255.255.255
		    up ip route add default dev $dev

		    hostname $hostname
		EOF
    fi

    rm /x/etc/resolv.conf
	cat > /x/etc/resolv.conf <<- EOF
		nameserver 8.8.8.8
		nameserver 2001:4860:4860::8888
	EOF
}

function install_requirement(){
    if [ -n "$(command -v apk)" ] ; then
        install sed gawk wget gzip rsync xz
    else
        install sed gawk wget gzip rsync xz-utils
    fi
}

function replace_os(){
    rsync -a -v \
        --delete-after \
        --ignore-times \
        --exclude="/dev" \
        --exclude="/proc" \
        --exclude="/sys" \
        --exclude="/x" \
        --exclude="/run" \
        /x/* /  
}

function post_install(){
    export PATH="/usr/sbin:/usr/bin:/sbin:/bin"
    if [[ $os_selected == *"alpine"* ]]; then
        install openssh bash
        rc-update add sshd default
        rc-update add mdev sysinit
        rc-update add devfs sysinit
        if [ "$cttype" == 'lxc' ] ; then
            install ifupdown
            rc-update add networking default
        fi
    elif [[ $os_selected == *"debian"* ]]; then
        install ssh bash
        if [ "$cttype" == 'lxc' ] ; then
            install ifupdown
        fi
    elif [[ $os_selected == *"centos"* ]]; then
        install openssh bash
        if [ "$cttype" == 'lxc' ] ; then
            install ifupdown
        fi
    fi
    echo PermitRootLogin yes >> /etc/ssh/sshd_config
    rm -rf /x /rootfs.tar.xz /rootfs.tar.gz
    sync
    reboot -f
}

function main(){
    print_help
    echo -e '\e[1;32minstall requirement...\e[m'
    install_requirement
    read_virt_tech

    if [ "$cttype" == 'lxc' ] ; then
        read_lxc_template
    else
        read_openvz_template
    fi

    echo -e '\e[1;32mdownloading template...\e[m'
    download_rootfs
    echo -e '\e[1;32mmigrating configuration\e[m'
    migrate_configuration
    echo -e '\e[1;32mreplacing old files\e[m'
    replace_os
    echo -e '\e[1;32mpost processing...\e[m'
    post_install
}

main 2>&1 | tee reinstall.log
