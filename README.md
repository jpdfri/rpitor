# rpitor

[DFRI](https://www.dfri.se/)'s second project for [Raspberry PI's](https://www.dfri.se/projekt/tor/rpi/), making them an appliance for Tor.

Scripts in this repo are a collection of updated scripts from [dfri-rpi-tor](https://github.com/DFRI/dfri-rpi-tor).
Major changes are as follows:

* Hardware upgraded to Raspberry Pi 2 (support for Raspberry Pi 3 experimental)

* Base OS upgraded to Raspbian Jessie

## This is the devel branch
_Here be dragons..._

* WIPs and TODOs
	> Decide of a license - done

	> systemd unit files for locally compiled packages, copied from a repo package? - unecessary

	> To Perl or not to Perl...

	> Alternative to UPnP

## Getting started with a new relay
* Prepare a folder to work with the scripts and such
	> mkdir scripts && cd scripts

* Create a fresh, minimal Raspbian install with [Raspbian unattended netinstaller](https://github.com/debian-pi/raspbian-ua-netinst)
NOTE: Raspberry Pi 3 requires you use [v1.1.x](https://github.com/debian-pi/raspbian-ua-netinst/tree/v1.1.x)
	> git clone https://github.com/debian-pi/raspbian-ua-netinst.git

	> cd raspbian-ua-netinst

* Download and use the _setup-image.sh_ script from this repo to create customized _installer-config.txt_ and _post-install.txt_ files
	> bash setup-image.sh _Pi-hostname_ _root-password_ _git repo_

If you don't pass any argument, the script will choose some for you. Note that the script will ask you if you want to checkout the "devel" branch and use more recent (albeit in testing) scripts.

* Proceed with building the base image	
	> ./build.sh

	> ./buildroot.sh (as root, e.g. with sudo)

* Copy the resulting _img_ file to your SD card with e.g. _dd_
* Boot up your Raspberry Pi 2, let it go through the initial setup. The RPi will download and install all necessary packages and then reboot itself (this normally takes about 10-15 minutes).
* After the automatic reboot, Tor will be started.
* Remember to setup port forwarding (TCP 9001) on your router/firewall if the RPi is located on a NAT:ed private LAN
