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
    cttype=$(virt-what | sed -n 1p)
    if [[ $cttype == "lxc" || $cttype == "openvz" ]]; then
        [[ $cttype == "lxc" ]] && echo -e '\e[1;33mYour container type: lxc\e[m' || echo -e '\e[1;33mYour container type: openvz\e[m'
    else
        while [ "$cttype" != 'lxc' -a "$cttype" != 'openvz' ] ; do
            echo -ne "\e[1;33mplease input container type (lxc/openvz):\e[m"
            read cttype
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
    last_lxc_version=$(curl -Ls "https://api.github.com/repos/LloydAsp/OsMutation/releases/latest" | grep "LXC" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    if [[ -n $last_lxc_version ]]; then
        image_list=$(curl -Ls "https://api.github.com/repos/LloydAsp/OsMutation/releases/latest" | grep "LXC" | grep '"browser_download_url":' | sed -E 's/.*"([^"]+)".*/\1/')

        os_list=$(curl -Ls "https://api.github.com/repos/LloydAsp/OsMutation/releases/latest" | grep "LXC" | grep '"browser_download_url":' | sed -E 's/.*"([^"]+)".*/\1/' | sed "s/https\:\/\/github.com\/LloydAsp\/OsMutation\/releases\/download\/${last_lxc_version}\///g" | sed "s/\.tar\.gz//g")
        echo "$os_list" | nl

        while [ -z "${os_index##*[!0-9]*}" ]; do
            echo -ne "\e[1;33mplease select os (input number):\e[m"
            read os_index
        done

        download_link=$(echo "$image_list" | head -n $os_index | tail -n 1)
    else
        server=http://images.linuxcontainers.org
        path=$(wget -qO- ${server}/meta/1.0/index-system | \
            grep -v edge | grep default | \
            awk '-F;' '(( $1=="debian" || $1=="centos" || $1=="alpine") && ( $3=="amd64" || $3=="i386")) {print $NF}')

        os_list=$( echo "$path" | sed -E 's%/images/(.*)/default/.*/%\1%g' | sed 's%/%-%g' )
        echo "$os_list" | nl

        while [ -z "${os_index##*[!0-9]*}" ]; do
            echo -ne "\e[1;33mplease select os (input number):\e[m"
            read os_index 
        done

        path=$( echo "$path" | head -n $os_index | tail -n 1)
        os_selected=$(echo "$os_list" | head -n $os_index | tail -n 1 )
        download_link=${server}/${path}/rootfs.tar.xz
    fi
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
        read os_index
    done

    os_selected=$( echo "$os_list" | head -n $os_index | tail -n 1)
    download_link="https://github.com/LloydAsp/OsMutation/releases/download/${releasetag}/${os_selected}.tar.gz"
}

function download_rootfs(){
    cd /oldroot;
    rm -rf $(ls /oldroot | grep -vE "(^dev|^proc|^sys|^run|^x)") ;

    if [ "$cttype" == 'lxc' ] ; then
        #rootfs.tar.xz
        wget -qO- $download_link | tar -C /oldroot -xJv --delay-directory-restore --exclude="dev" --exclude="proc" --exclude="run" --exclude="sys"
    else
        wget -qO- $download_link | tar -C /oldroot -xzv --delay-directory-restore --exclude="dev" --exclude="proc" --exclude="run" --exclude="sys"
    fi
}


function migrate_configuration(){
    dest_os_dir="$1"
    # save root password and ssh directory
    sed -i '/^root:/d' "/$dest_os_dir/etc/shadow"
    grep '^root:' /etc/shadow >> "/$dest_os_dir/etc/shadow"
    [ -d /root/.ssh ] && cp -a "/root/.ssh /$dest_os_dir/root/"

    # save network configuration
    dev=$(ip route get 8.8.8.8 | sed -n 's/.*dev \([^\ ]*\).*/\1/p' | head -n 1)
    [ -d "/$dest_os_dir/etc/network/" ] || mkdir -p "/$dest_os_dir/etc/network/"
    ipaddr_with_mask=$(ip addr show dev $dev | sed -nE '/global/s/.*inet (.+) brd.*$/\1/p' | head -n 1)
    hostname=$(hostname)
    route_part="$(ip route show default 0.0.0.0/0 | sed -E 's/^(.*dev [^ ]+).*$/\1/')"
    gateway_line="up ip route add $route_part"

    # manual save network
    if [ -f /etc/network/interfaces ] && grep static /etc/network/interfaces > /dev/null ; then
        cp -rf /etc/network/interfaces "/$dest_os_dir/etc/network/interfaces"
    else
        cat > "/$dest_os_dir/etc/network/interfaces" <<- EOF
			auto lo
			iface lo inet loopback

			auto $dev
			iface $dev inet static
			address $ipaddr_with_mask
			$gateway_line

			hostname $hostname
		EOF
    fi

    rm "/$dest_os_dir/etc/resolv.conf"
	cat > "/$dest_os_dir/etc/resolv.conf" <<- EOF
		nameserver 8.8.8.8
		nameserver 2001:4860:4860::8888
	EOF
}

function chroot_run(){
    if grep -qi alpine /x/etc/issue; then
        chroot "/x/" sh -c "[ -f /bin/bash ] || apk add bash"
    fi
    chroot "/x/" /bin/bash -c "$*"
}

function post_install(){
    export PATH="/usr/sbin:/usr/bin:/sbin:/bin"
    if grep -qi alpine /etc/issue; then
        install openssh bash
        rc-update add sshd default
        rc-update add mdev sysinit
        rc-update add devfs sysinit
        if grep -qa container=lxc /proc/1/environ ; then
            apk add ifupdown-ng
            rc-update add networking default
            sed -i 's/--auto/-a/' /etc/init.d/networking # fix bug in networking script of lxc
        fi
    elif grep -qi debian /etc/issue; then
        install ssh
        if grep -qa container=lxc /proc/1/environ ; then
            install ifupdown
            systemctl disable systemd-networkd.service
        fi
    elif grep -qi centos /etc/issue; then
        install openssh
        if grep -qa container=lxc /proc/1/environ ; then
            install ifupdown
            systemctl disable systemd-networkd.service
            # To-Do: Network service of CentOS need modify
        fi
    fi
    echo PermitRootLogin yes >> /etc/ssh/sshd_config
    rm -rf /x
    sync
    while [ "$reboot_ans" != 'yes' -a "$reboot_ans" != 'no' ] ; do
        echo -ne "\e[1;33mreboot now? (yes/no):\e[m"
        read reboot_ans  < /dev/tty
    done

    if [ "$reboot_ans" == 'yes' ] ; then
        reboot -f
    fi
}

function install_requirement(){
    # prevent no access on ipv6 only vps
    ping -c 3 api.github.com || echo "nameserver 2a00:1098:2c::1"  >  /etc/resolv.conf 
    
    if [ -n "$(command -v apk)" ] ; then
        install curl sed gawk wget gzip xz tar virt-what
    else
        install curl sed gawk wget gzip xz-utils virt-what
    fi
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
    migrate_configuration oldroot
}

function make_temp_os(){
    temp_os_url="https://github.com/LloydAsp/OsMutation/releases/download/utils/alpine-3.18-chroot.tar.gz"
    mkdir /x
    if [ -n "$(command -v wget)" ] ; then
        wget -qO- $temp_os_url | tar -C /x -xz
    elif [ -n "$(command -v curl)" ] ; then
        curl -sL $temp_os_url | tar -C /x -xz
    else
        install wget
        wget -qO- $temp_os_url | tar -C /x -xz
    fi

    # backup configuration
    migrate_configuration x

    cp OsMutation.sh /x/
    mkdir /x/oldroot
    mount --bind / /x/oldroot
    chroot_run env main=1 ./OsMutation.sh
    umount /x/oldroot

    echo -e '\e[1;32mpost processing...\e[m'
    post_install
}


if [ -z "$main" ]; then
    make_temp_os 2>&1 | tee reinstall.log
    exit 0
fi

main
