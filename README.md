# bspm: Bridge to System Package Manager

<!-- badges: start -->
[![Build Status](https://github.com/Enchufa2/bspm/workflows/build/badge.svg)](https://github.com/Enchufa2/bspm/actions)
[![CRAN\_Status\_Badge](https://www.r-pkg.org/badges/version/bspm)](https://cran.r-project.org/package=bspm)
<!-- badges: end -->

Enables binary package installations on Linux distributions.
Provides functions to manage packages via the distribution's package
manager. Also provides transparent integration with R's install.packages()
and a fallback mechanism. When installed as a system package, interacts
with the system's package manager without requiring administrative
privileges via an integrated D-Bus service; otherwise, uses sudo.
Currently, the following backends are supported: DNF, APT.

## Installation

Installation from system repositories is preferred, mainly to avoid issues on
SELinux-enabled systems (see [#19](https://github.com/Enchufa2/bspm/issues/19)).

- For Fedora, see `R-CoprManager` for the
  [cran2copr](https://copr.fedorainfracloud.org/coprs/iucar/cran/) project.
- For Ubuntu/Debian, it is available as `r-cran-bspm` via APT.

Installation from source requires the following dependencies (apart from R):

- python3-dnf (Fedora-like), python3-apt (Debian-like)

If you plan to run it as a regular user (non-root), these are required too:

- systemd
- python3-dbus
- python3-gobject (Fedora-like), python3-gi (Debian-like)

Then, you should install it as a system package to be able to use it as a
regular user (note `sudo`):

```bash
sudo R CMD INSTALL bspm_[version].tar.gz
```

Further configuration options:

- If you plan to run it only as root (e.g., in a docker container), then you
  don't need the D-Bus service, so you can disable its installation by adding
  `--configure-args="--without-dbus-service"`.
- If you are installing the package in a build root, instead of its final
  destination, specify `--configure-vars="BUILD_ROOT=[path_to_build_root]"` too.
- By default, package prefixes and exclusions are automatically discovered from
  system repositories, and this discovery mechanism is exposed so that the user
  can install other packages if e.g. new repositories with other prefixes are
  added. If you want to fix prefixes and exclusions and prevent exposing the
  discovery mechanism, set `--configure-vars="PKG_PREF='prefix1- prefix2- ...'"`
  and `--configure-vars="PKG_EXCL='exclusion1 exclusion2 ...'"`.

To enable it by default, put the following into the `Rprofile.site`:

```r
suppressMessages(bspm::enable())
```

Then, run `install.packages` as usual, and available system packages will be
automatically installed.

## Developing new backends

New backends for other package managers can be added to `inst/service/backend`.
Each backend must implement the following functions:

- `def discover() -> dict({ "prefixes" : list, "exclusions" : list })`
- `def install(prefixes : list, pkgs : list, exclusions : list) -> list`
- `def remove(prefixes : list, pkgs : list, exclusions : list) -> list`

The last two functions receive a list of prefixes, a list of R package names and
a list of exclusions, and must return a list with those package names that could
not be processed (i.e., packages not found in the system repos). Any progress
should be reported to stdout.
