# OVMF-VFIO Scripts

## Hardware
- **CPU**: AMD Ryzen 5 1600 AF
- **Motherboard**: Asrock B450M PRO4-F
- **GPU**: Asrock Radeon RX570 4GB
- **RAM**: Geil Orion 2x8GB DDR4 3200MHz

## Software
- **Host Kernel**: Linux 6.5.5-arch1-1
- **Host OS**: Arch Linux
- **Guest OS**: Windows 10 Pro

## Installation
```bash
cd vfio/
sudo ./script.sh -i
```

## TODO
- [ ] Try to configure to work with win11
- [ ] Check if it's necesary to kill all the user proceses
- [ ] SSD/HDD passtrough for faster loading

## Credits
- [Heavily inspired in the scripts made by @akshaycodes](https://gitlab.com/akshaycodes/vfio-script)
- [Guided by this wiki](https://gitlab.com/risingprismtv/single-gpu-passthrough/-/wikis/home)
