#!/bin/bash

Vars() {
    NULL="/dev/null"
     
    #Delays
    Delay_1="1"
    Delay_2="2"
    Delay_3="3"
    Delay_4="4"
    Delay_5="5"
     
    #Virsh Commands
    PCI="pci_0000_"
    REMOVE="nodedev-detach"
    ADD="nodedev-reattach"

    #Video and Audio
    VIDEO=$(lspci -nn | grep VGA | head -1 | cut -d " " -f1 | tr ":." "_")
    VIDEO1=$(lspci -nn | grep VGA | head -1 | cut -d " " -f1)
    AUDIO=$(lspci -nn | grep "HDMI Audio" | head -1 | cut -d " " -f1 | tr ":." "_")
    AUDIO1=$(lspci -nn | grep "HDMI Audio" | head -1 | cut -d " " -f1)

    #RTC Wake Timer
    TIME="+8sec"
    
    #CoolDown Delay
    Delay_8="8"
     
    #Loop Variables
    declare -i Loop
    Loop=1
    declare -i TimeOut
    TimeOut=5
     
    # Helpful to read output when debugging
    set -x
}

Kill() {
    #Just to make sure the session is dead.	
	for i in $(ls /home); do 
        echo $i;
        killall -u $i;
        kill -9 $(ps -s -U $i | awk '{print $2}' | grep -Ev "pid");
    done
    sleep $Delay_2
	#Unbinding VT Consoles if currently bound (adapted from https://www.kernel.org/doc/Documentation/fb/fbcon.txt)
	for i in /sys/class/vtconsole/*; do
        echo 0 > $i/bind
	done
    # Unbind EFI-framebuffer
    # echo "efi-framebuffer.0" > /sys/bus/platform/drivers/efi-framebuffer/unbind
}

AMD() {
    if [ "lsmod | grep "amdgpu" &> /dev/null" ]; then
        # List AMD GPU modules into /tmp/amd-modules
        lsmod | grep amdgpu | cut -d " " -f1 > /tmp/amd-modules
        # Syncing Disk and Clearing the Cache (RAM)
        sync; echo 1 > /proc/sys/vm/drop_caches
        # Un-Binding GPU from driver
        sleep $Delay_2
        echo "0000:$VIDEO1" > "/sys/bus/pci/devices/0000:$VIDEO1/driver/unbind"
        echo "0000:$AUDIO1" > "/sys/bus/pci/devices/0000:$AUDIO1/driver/unbind"
        # Waiting for AMD GPU to Finish
        while !(dmesg | grep "amdgpu 0000:$VIDEO1" | tail -5 | grep "amdgpu: finishing device."); do
            echo "Loop-1";
            if [ "$Loop" -le "$TimeOut" ]; then
                echo "Waiting";
                TimeOut+=1;
                echo "Try: $TimeOut";
                sleep 1;
            else
                break;
            fi
        done
        # Removing Video and Audio
        virsh $REMOVE "$PCI$VIDEO"
        sleep 1
        virsh $REMOVE "$PCI$AUDIO"
        modprobe -r amdgpu
        # Resetting the Loop counter
        Loop=1
        # Making sure that AMD GPU is Un-Loaded
        while (lsmod | grep amdgpu); do
            echo "Loop-3";
            if [ "$Loop" -le $TimeOut ]; then
                echo "AMD GPU in use";
                lsmod | grep amdgpu | awk '{print $1}' | while read AMD; do modprobe -r $AMD; done;
                TimeOut+=1;
                echo "AMD GPU Try: $TimeOut";
                sleep 1;
            else
                echo "Fail to remove AMD GPU";
                rmmod amdgpu;
                break;
            fi;
        done
        # Add VFIO modules
        modprobe vfio_pci
        modprobe vfio
        modprobe vfio_iommu_type1
        # Garbage collection
        unset Loop
        unset TimeOut
        # Putting System to a quick sleep cycle to make sure that AMD GPU is properly reset
        rtcwake -m mem --date $TIME
    fi
}

# Main Init
Vars
if [[ "$*" == "prepare" ]]; then
    Kill
    AMD
    echo " Done"
elif [[ "$*" == "release" ]]; then
    # Add VFIO modules
    modprobe -r vfio_pci
    modprobe -r vfio
    modprobe -r vfio_iommu_type1
    # Rebind AMDGPU
    virsh $ADD "$PCI$AUDIO"
    sleep 1
    virsh $ADD "$PCI$VIDEO"
    # Unbind EFI-framebuffer
    # echo "efi-framebuffer.0" > /sys/bus/platform/drivers/efi-framebuffer/bind
    # Load AMDGPU module
    modprobe amdgpu
    rtcwake -m mem --date $TIME
    sleep $Delay_3
    echo "Stop Done"
fi
