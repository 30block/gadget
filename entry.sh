#!/bin/sh

set -e

load_modules() {
	modprobe -a dwc2 g_ether
}

GADGET_ADDRESS=${GADGET_ADDRESS:-"10.55.0.1"}
addr_prefix=${GADGET_ADDRESS%.*}

setup_usb() {
	gadget=/sys/kernel/config/usb_gadget/rpi
	if [ ! -f "${gadget}/UDC" ] || [ ! -s "${gadget}/UDC" ]; then
		mkdir -p "${gadget}"
		cd "${gadget}"

		# Ignore erorrs in this chunk of code
		set +e

		# Setup gadget
		# see https://docs.kernel.org/usb/gadget_configfs.html for detaisl
		echo "0x0200" >bcdUSB # USB 2.0
		echo "0xEF" >bDeviceClass
		echo "0x02" >bDeviceSubClass
		echo "0x1d6b" >idVendor  # Linux Foundation
		echo "0x0104" >idProduct # Multifunction composite gadget
		echo "0x0100" >bcdDevice # v1.0.0
		echo "0x01" >bDeviceProtocol

		# Gadget manufacturer details in english (0x409)
		mkdir -p strings/0x409
		echo "Me" >strings/0x409/manufacturer
		echo "Raspberry-Pi USB Gadget" >strings/0x409/product
		echo "fedcba9876543211" >strings/0x409/serialnumber

		# Gadget configuration
		mkdir -p configs/c.1
		echo "0x80" >configs/c.1/bmAttributes # Bus powered
		echo "250" >configs/c.1/MaxPower
		mkdir -p configs/c.1/strings/0x409
		echo "RNDIS" >configs/c.1/strings/0x409/configuration # Configuration name

		# Gadget identification
		mkdir -p os_desc
		echo "1" >os_desc/use
		echo "0xcd" >os_desc/b_vendor_code # Microsoft
		echo "MSFT100" >os_desc/qw_sign    # also Microsoft

		# Gadget functions
		mkdir -p functions/rndis.usb0
		mac="01:23:45:67:89:ab"
		dev_mac="02$(echo ${mac} | cut -b 3-)"
		host_mac="12$(echo ${mac} | cut -b 3-)"
		echo "${dev_mac}" >functions/rndis.usb0/dev_addr
		echo "${host_mac}" >functions/rndis.usb0/host_addr
		echo "RNDIS" >functions/rndis.usb0/os_desc/interface.rndis/compatible_id       # matches Windows RNDIS Drivers
		echo "5162001" >functions/rndis.usb0/os_desc/interface.rndis/sub_compatible_id # matches Windows RNDIS 6.0 Driver

		# Assing the gadget configuration and functions
		ln -s ${gadget}/configs/c.1 ${gadget}/os_desc
		ln -s ${gadget}/functions/rndis.usb0 ${gadget}/configs/c.1

		# Go back to checking errors
		set -e

		# Enable the gadget
		ls /sys/class/udc >${gadget}/UDC

		# Wait for devices to be created
		udevadm settle -t 5 || :
	fi

	# Setup the interface
	if [ -f "${gadget}/UDC" ] && [ -s "${gadget}/UDC" ]; then
		ip link set dev usb0 up
		ip addr add "${GADGET_ADDRESS}/24" dev usb0 || true
	else
		echo 'Could not setup usb gadget. Ensure that the device has been configured with dtoverlay="dwc2"'
		exit 0
	fi
}

load_modules
setup_usb

# serve dhcp on usb interface
dnsmasq --interface=usb0 \
	--port=0 \
	--dhcp-range="${addr_prefix}.1,${addr_prefix}.6",255.255.255.248,1h \
	--dhcp-option=3 \
	--leasefile-ro \
	--listen-address=127.0.1.1 \
	--no-daemon
