#!/bin/bash

show_help() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -h, --help      Display this help message"
    echo "  -i, --install   Install scripts"
    echo "  -r, --remove    Remove current scripts"
    echo "  -c, --clean     Remove current scripts and bck files"
}

Install() {
    if [ ! -e /etc/libvirt/hooks ]; then
        mkdir -p /etc/libvirt/hooks;
    fi
    if [ -e /etc/libvirt/hooks/qemu ]; then
        mv /etc/libvirt/hooks/qemu /etc/libvirt/hooks/qemu.bck;
    fi
    if [ -e /usr/bin/vfio.sh ]; then
        mv /usr/bin/vfio.sh /usr/bin/vfio.sh.bck;
    fi
     
    cp -v ./qemu /etc/libvirt/hooks/qemu
    cp -v ./vfio.sh /usr/bin/vfio.sh
     
    chmod +x /usr/bin/vfio.sh
    chmod +x /etc/libvirt/hooks/qemu
}

Remove() {
    rm /etc/libvirt/hooks/qemu
    rm /usr/bin/vfio.sh
}

Clean() {
    Remove
    rm /etc/libvirt/hooks/qemu.bck
    rm /usr/bin/vfio.sh.bck
}

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -i|--install)
            Install
            exit 0
            ;;
        -r|--remove)
            Remove
            exit 0
            ;;
        -c|--clean)
            Clean
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
    shift
done
systemctl restart libvirtd.service
