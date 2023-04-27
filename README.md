```
         ██████╗ ███████╗███╗   ███╗██╗   ██╗████████╗ █████╗ ████████╗██╗ ██████╗ ███╗   ██╗
        ██╔═══██╗██╔════╝████╗ ████║██║   ██║╚══██╔══╝██╔══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║
        ██║   ██║███████╗██╔████╔██║██║   ██║   ██║   ███████║   ██║   ██║██║   ██║██╔██╗ ██║
        ██║   ██║╚════██║██║╚██╔╝██║██║   ██║   ██║   ██╔══██║   ██║   ██║██║   ██║██║╚██╗██║
        ╚██████╔╝███████║██║ ╚═╝ ██║╚██████╔╝   ██║   ██║  ██║   ██║   ██║╚██████╔╝██║ ╚████║
         ╚═════╝ ╚══════╝╚═╝     ╚═╝ ╚═════╝    ╚═╝   ╚═╝  ╚═╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝
```

# OsMutation
Convert Any OpenVZ/LXC VPS to Debian/CentOS/Alpine

## Feature
- Support both Openvz 7 and Lxc
- Support multiple operation systems

## Usage
```
wget -qO OsMutation.sh https://raw.githubusercontent.com/LloydAsp/OsMutation/main/OsMutation.sh && chmod u+x OsMutation.sh && ./OsMutation.sh
```
or
```
curl -so OsMutation.sh https://raw.githubusercontent.com/LloydAsp/OsMutation/main/OsMutation.sh && chmod u+x OsMutation.sh && ./OsMutation.sh
```

## Notice
- A fresh system will be installed and all old data will be wiped! Backup your important data first.
- Openvz 7 and above is support, not openvz 6.
- Virtual Machine is not supported, such as kvm, xen and vmware

## How Does This works
Openvz and Lxc are typical container virtualization technologys. The host OS kernel is shared with both the host and other containers, and all the applications and runtime libraries required by os are packed together in container itself.

So if you want to replace the operation system, you can just replace the files in the container. That's it, simple and straightforward. Just pay attention to the order of action since there are some dependences of files.

## Template Source
Lxc templates are directly downloaded from http://images.linuxcontainers.org, openvz 7 templates are extracted from openvz 7 official iso.

## To Do
- Support non-interactive mode by accepting arguments
- Support customed template source