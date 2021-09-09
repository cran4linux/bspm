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

See our contributed talk at _useR! 2021_:
[[video](https://youtu.be/GMMGBlyl_ok?t=1170),
[slides](https://enchufa2.github.io/bspm/slides/20210709-useR2021_talk.html)].

## Installation

Installation from system repositories is preferred, mainly to avoid issues on
SELinux-enabled systems (see [#19](https://github.com/Enchufa2/bspm/issues/19)).

- Follow these links if the target system is a desktop/server installation of
  one of the supported distributions:
  [Fedora](#fedora), [Ubuntu/Debian](#ubuntudebian), [openSUSE](#opensuse)).
- If the target system is a containerized application (e.g., a Docker image),
  refer to the [`rocker/r-bspm` images](https://github.com/rocker-org/rocker/tree/master/r-bspm).
- If you are trying `bspm` in another distro, or you are packaging it as a
  system package, please follow the general procedure below.

### General procedure

Installation from source requires the following dependency (apart from R):

- `python3-dnf` (Fedora-, openSUSE-like), `python3-apt` (Debian-like)

If you plan to run it as a regular user (non-root) in a desktop/server setting,
these dependencies are required too:

- `systemd` (should be already installed in all distros nowadays).
- `python3-dbus` (Fedora-, Debian-like), `python38-dbus-python` (openSUSE-like)
- `python3-gobject` (Fedora-, openSUSE-like), `python3-gi` (Debian-like)

Then, you should install `bspm` as a system package to be able to use it as a
regular user. Download the latest version from CRAN or GitHub and proceed with
the installation (note `sudo`):

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
bspm::enable() # wrap it in suppressMessages() to avoid the initial message
```

Then, run `install.packages` as usual, and available system packages will be
automatically installed.

### Fedora

There are thousands of binary packages available via the
[iucar/cran](https://copr.fedorainfracloud.org/coprs/iucar/cran/) Copr repo.
The `bspm` package is available as `R-CoprManager`, and enabled by default:

```bash
$ sudo dnf install 'dnf-command(copr)'
$ sudo dnf copr enable iucar/cran
$ sudo dnf install R-CoprManager
```

### Ubuntu/Debian

There are thousands of binary packages available via the
[marutter/c2d4u](https://launchpad.net/~marutter/+archive/ubuntu/c2d4u) PPA repo.
The `bspm` package is available as `r-cran-bspm` via the
[edd/r-4.0](https://launchpad.net/~edd/+archive/ubuntu/r-4.0) PPA repo:

```bash
$ sudo add-apt-repository ppa:marutter/c2d4u # if using Ubuntu 20.04
$ sudo add-apt-repository ppa:edd/r-4.0      # if using Debian testing
$ sudo apt-get update
$ sudo apt-get install r-cran-bspm
```

Then, to enable it system-wide (alternatively, use your `.Rprofile`):

```bash
$ echo "bspm::enable()" | sudo tee -a /etc/R/Rprofile.site
```

### openSUSE

There are thousands of binary packages available via the
[autoCRAN](https://build.opensuse.org/project/show/devel:languages:R:autoCRAN)
OBS repo:

```bash
$ sudo zypper ar -r https://download.opensuse.org/repositories/devel:/languages:/R:/patched/openSUSE_Tumbleweed/devel:languages:R:patched.repo
$ sudo zypper ar -r https://download.opensuse.org/repositories/devel:/languages:/R:/autoCRAN/openSUSE_Tumbleweed/devel:languages:R:autoCRAN.repo
$ sudo zypper install R-patched python3-dnf python38-dbus-python python3-gobject
$ sudo ln -s /etc/zypp/repos.d /etc/yum.repos.d
```

Then, install `bspm` as a system package from CRAN:

```bash
$ sudo Rscript -e 'install.packages("bspm", repos="https://cran.r-project.org")'
```

Then, to enable it system-wide (alternatively, use your `.Rprofile`):

```bash
$ echo "bspm::enable()" | sudo tee -a /usr/lib64/R/etc/Rprofile.site
```

Sometimes, a restart is required so that the new systemd service is recognized.

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
