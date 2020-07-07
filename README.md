# R Bridge to System Package Manager

Enables binary package installations on Linux distributions
without administrative privileges. Provides functions to manage packages
via the distribution's package manager. Also provides transparent
integration with R's 'install.packages' and a fallback mechanism.

Currently, the following backends are supported: DNF, APT.

## Installation

The following dependencies are required (apart from R):

- python3-dnf (Fedora-like), python3-apt (Debian-like)

If you plan to run it as a regular user (non-root), these are required too:

- systemd
- python3-dbus
- python3-gobject (Fedora-like), python3-gi (Debian-like)

Then, if e.g. your distro's R packages are called "r-cran-[pkgname]",

```bash
sudo R CMD INSTALL PackageManager \
  --configure-vars="SYSCONF_DIR=/etc" \
  --configure-vars="DATA_DIR=/usr/share" \
  --configure-vars="PKG_PREFIX=r-cran-"
```

If you plan to run it only as root (e.g., in a docker container), then you
don't need the D-Bus service, so only `PKG_PREFIX` is required above.

To enable it by default, put the following into the `Rprofile.site`:

```r
suppressMessages(PackageManager::enable())
```

Then, run `install.packages` as usual, and available system packages will be
automatically installed.

## Developing new backends

New backends for other package managers can be added to `inst/service/backend`.
Each backend must implement the following functions:

- `def install(prefix : str, pkgs : list) -> list`
- `def remove(prefix : str, pkgs : list) -> list`

Both functions receive a prefix and a list of R package names, and must return
a list with those package names that could not be processed (i.e., packages not
found in the system repos). Any progress should be reported to stdout.
