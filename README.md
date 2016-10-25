# rpitor

[DFRI's](https://www.dfri.se/) second project for [Raspberry PI's](https://www.dfri.se/projekt/tor/rpi/), making them an appliance for Tor.

Scripts in this repo are a collection of updated scripts from [dfri-rpi-tor](https://github.com/DFRI/dfri-rpi-tor).
Major changes are as follows:
* Hardware upgraded to Raspberry Pi 2
* Base OS upgraded to Raspbian Jessie

##This is the devel branch
Here be dragons...
* WIPs and TODOs
	> Decide of a license

	> systemd unit files for locally compiled packages, copied from a repo package?

	> To Perl or not to Perl...

##Getting started with a new relay
* Prepare a folder to work with the scripts and such
	> mkdir scripts && cd scripts

* Create a fresh, minimal Raspbian install with [Raspbian unattended netinstaller](https://github.com/debian-pi/raspbian-ua-netinst)
NOTE: kernel 4.4 should now be part of the master branch, otherwise make sure you use [v1.1.x](https://github.com/debian-pi/raspbian-ua-netinst/tree/v1.1.x)
	> git clone https://github.com/debian-pi/raspbian-ua-netinst.git

	> cd raspbian-ua-netinst

* Download and use the _setup-image.sh_ script from this repo to create a customized _installer-config.txt_ file
	> bash setup-image.sh _Pi-hostname_ _root-password_

If you don't pass any argument, the script will choose some for you

* Proceed with building the base image	
	> ./build.sh

	> ./buildroot.sh (as root, e.g. with sudo)

* Copy the resulting _img_ file to your SD card with e.g. _dd_
* Boot up your Raspberry Pi 2, let it go through the initial setup. Once you can SSH into it, clone the rpitor repo to the Raspberry Pi
	> git clone https://github.com/DFRI/rpitor.git

* Run _initial-boot-setup-rpi2-raspbian-jessie.sh_. Pass "source" as an argument to compile from source.
* Now the RPi will download and install updates and then reboot itself (this normally takes about 10-15 minutes).
* After the automatic reboot, Tor will be started.
* Remember to setup port forwarding (TCP 9001) on your router/firewall if the RPi is located on a NAT:ed private LAN
