# debian-preseed

The Debian installer can be automated with a preconfiguration file. The
installer has many options so the `preseed.cfg` file can get pretty long. The
configuration file must be available at install time.

This project inserts a `preseed.cfg` file into an ISO image.

The Debian installer can change on release boundaries, so this project is split
up into release folders.

## buster

Debian stable release 10 is code named [buster](buster/) that has an [example-preseed.txt](buster/example-preseed.txt) to start with.

# di-netboot-assistant

The Debian Installer Netboot Assistant (di-netboot-assistant) software makes
it easy to host Debian install images on a system and other systems can use the
Pre eXecution Environment (PXE) to boot the Debian installers.


## References

* [Debian Installer Preseed](https://wiki.debian.org/DebianInstaller/Preseed) wiki
* [Automating the installation](https://www.debian.org/releases/stable/amd64/apb.en.html)
* [Contents of the preconfiguration file](https://www.debian.org/releases/buster/amd64/apbs04.en.html)
* [Inserting the preseed into an ISO](https://wiki.debian.org/DebianInstaller/Preseed/EditIso)
* [RepackBootableISO](https://wiki.debian.org/RepackBootableISO)

* [DebianInstaller Netboot Assistant](https://wiki.debian.org/DebianInstaller/NetbootAssistant)
* [di-netboot-assistant manual page](https://manpages.debian.org/unstable/di-netboot-assistant/di-netboot-assistant.1.en.html)
---
