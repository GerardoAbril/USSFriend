# Portable Network Monitoring (U.S.S. Friend)
Our system allows for network monitoring by:

* Reading packets into a database and display it into a viewer-friendly website.
* Displaying default information to client
* Displaing the cross-listed database with second database of blocklisted IP addresses
* Flagging specific IP addresses on the network that may be hostile
* Providing remote database management
* Querying results

## Getting Started

### Hardware

Suggested platform: Rock64.
Suggested network tap: Great Scott Gadgets LAN Tap.

Additional: 
1 USB3.0 to Ethernet adapter with promiscuous abilities.
1 USB2.0 to Ethernet adapter.

To setup, plug the network tap in line with your connection.  

Connect both adapters to the Rock64.

Connect the LAN Tap's output to the 3.0 ethernet adapter and the Rock64's primary adapter. 

Connect the 2.0 ethernet adapter to the internet to be able to remotely access the Rock64's webpage.

### Prerequisites

Install Xenial on the Rock64.
Recommend using Etcher (https://etcher.io)
*Direct download for Xenial Mate Build Image (http://wiki.pine64.org/index.php/ROCK64_Software_Release#Xenial_Mate)*


### Software
 
Download all files.

Move the web package to its proper location in the root file (/var/www/html) for localhost.

Find active ethernet ports with ifconfig command, setting IP Addresses to each unassigned port that will be used for sniffing.

Run Perl file from terminal.  These commands require the -Tw command, and must be run on all sniffing ports by using the tag -i \[port\].

## Built With

* [ATOM](https://github.com/atom) - Text editor

## Contributing

Please read [CONTRIBUTING.md] in the root folder for details on our code of conduct, and the process for submitting pull requests to us.

## Authors

* **Ruzgar Zere** - *Frontend* - (https://github.com/rzere)
* **Cyrus Bonyadi** - *Backend* - (https://github.com/cbonyadi)
* **Hannah Holman** - *Hardware* - (https://github.com/Hannah1902)
* **Jerry Abril** - *Backend-Frontend Integration* - (https://github.com/LilJearBear)

## Acknowledgments

* Thanks Dr. Summet!
          -U.S.S. Friend Team
