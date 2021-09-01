# debian-preseed

The Debian installer can be automated with a preconfiguration file. The
installer has many options so the `preseed.cfg` file can get pretty long. The
configuration file must be available at install time.

This project inserts a `preseed.cfg` file into an ISO image.

The Debian installer can change on release boundaries, so this project is split
up into release folders.

# Check the syntax of preseed files!

To avoid costly delays check the syntax of the preseed file before using it.
This can be done by running the `debconf-set-selections` command:

```
debconf-set-selections -c /path/to/preseed.cfg
```

This will help find line continuation issues and other syntax errors before the
installer does with unhelpful messages. Watch out for spaces AFTER the line
continuation character backslash (\\).

## bullseye

The latest release as of this document is Debian version 11 code named
[bullseye](bullseye/) and the [example-preseed.txt](bullseye/example-preseed.txt)
is the preconfiguration file to start with for this release.

## buster

Debian version 10 code named [buster](buster/) that has an
[example-preseed.txt](buster/example-preseed.txt) to start with for the buster
release.

# di-netboot-assistant

The Debian Installer Netboot Assistant (di-netboot-assistant) software makes
it easy to host Debian install images on a system and other systems can use the
Pre eXecution Environment (PXE) to boot the Debian installers.

# Network booting challenges

The Pre eXecution Environment (PXE) introduces its own challenges to the
automated install. To use PXE, the system needs to have an active network
connection to download the installer binary from the PXE server. Some of the
network values (interface, domain, and hostname) are set by the DHCP server and
the installer will not overwrite these values from the preseed file.

To set these network values, one can provide them as parameters to the installer
from the grub boot instruction.

## Troubleshooting

If running a PXE on a VM remember the host firewall must allow PXE port 69 and
DHCP traffic to the VM TCP&UDP port 53 UDP port 67.

## References

* [Debian Installer Preseed](https://wiki.debian.org/DebianInstaller/Preseed) wiki
* [Automating the installation](https://www.debian.org/releases/stable/amd64/apb.en.html)
* [Contents of the preconfiguration file](https://www.debian.org/releases/buster/amd64/apbs04.en.html)
* [Inserting the preseed into an ISO](https://wiki.debian.org/DebianInstaller/Preseed/EditIso)
* [RepackBootableISO](https://wiki.debian.org/RepackBootableISO)

* [DebianInstaller Netboot Assistant](https://wiki.debian.org/DebianInstaller/NetbootAssistant)
* [di-netboot-assistant manual page](https://manpages.debian.org/unstable/di-netboot-assistant/di-netboot-assistant.1.en.html)
---
