# OsMutation
Reinstall Any OpenVZ/LXC VPS to Debian/CentOS/Alpine

## Features
- Support both OpenVZ 7 and LXC
- Support reinstall to multiple operating systems

## Usage
```
wget -qO OsMutation.sh https://raw.githubusercontent.com/LloydAsp/OsMutation/main/OsMutation.sh && chmod u+x OsMutation.sh && ./OsMutation.sh
```
or
```
curl -so OsMutation.sh https://raw.githubusercontent.com/LloydAsp/OsMutation/main/OsMutation.sh && chmod u+x OsMutation.sh && ./OsMutation.sh
```
for vps whose disk is small (experimental support)
```
wget -qO OsMutation.sh https://raw.githubusercontent.com/LloydAsp/OsMutation/main/OsMutationTight.sh && chmod u+x OsMutation.sh && ./OsMutation.sh
```

[![asciicast](https://asciinema.org/a/582009.svg)](https://asciinema.org/a/582009)

## Notice
- A fresh system will be installed and all old data will be wiped! Backup your important data first.
- OpenVZ 7 and above is support, not OpenVZ 6.
- Virtual Machine is not supported, such as kvm, xen and vmware

## How Does This work
Openvz and Lxc are typical container virtualization technologys. The host OS kernel is shared with both the host and other containers, and all the applications and runtime libraries required by os are packed together in container itself.

So if you want to replace the operating system, you can just replace the files in the container. That's it, simple and straightforward. Just pay attention to the order of action since there are some dependences of files.

## Template Sources
LXC templates are directly downloaded from http://images.linuxcontainers.org, OpenVZ 7 templates are extracted from OpenVZ 7 official iso.

## Thanks To
- Inspired by https://gist.github.com/trimsj/c1fefd650b5f49ceb8f3efc1b6a1404d

## To Do
- Support non-interactive mode by accepting arguments
- Support customed template source
- Support more operating system 
- Fix networking bug of CentOS under LXC
- Auto configure ipv6 network