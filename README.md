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
Currently, the following backends are supported: DNF, APT, ALPM.

See our contributed talk at _useR! 2021_:
[[video](https://youtu.be/GMMGBlyl_ok?t=1170),
[slides](https://enchufa2.github.io/bspm/slides/20210709-useR2021_talk.html)].

## Installation

Installation from system repositories is preferred, mainly to avoid issues on
SELinux-enabled systems (see [#19](https://github.com/Enchufa2/bspm/issues/19)).

- Follow these links if the target system is a desktop/server installation of
  one of the supported distributions:
  [Fedora](#fedora), [Ubuntu](#ubuntu), [openSUSE](#opensuse), [Arch](#arch).
- If the target system is a containerized application (e.g., a Docker image),
  refer to the [`rocker/r-bspm` images](https://github.com/rocker-org/rocker/tree/master/r-bspm).
- If you are trying `bspm` in another distro, or you are packaging it as a
  system package, please follow the general procedure below.

### General procedure

Installation from source requires (apart from R) the folllowing Python bindings:

|               | Package manager | DBus (\*)              | GObject (\*)      |
|---------------|-----------------|------------------------|-------------------|
| Fedora/RedHat | `python3-dnf`   | `python3-dbus`         | `python3-gobject` |
| Ubuntu/Debian | `python3-apt`   | `python3-dbus`         | `python3-gi`      |
|      openSUSE | `python3-dnf`   | `python38-dbus-python` | `python3-gobject` |
|          Arch | `pyalpm`        | `python-dbus`          | `python-gobject`  |

(*) Optional, only required if you plan to run `bspm` as a regular user
(non-root) in a (systemd-based) desktop/server setting.

Then, you should install `bspm` as a system package to be able to use it as a
regular user. Download the latest version from CRAN or GitHub and proceed with
the installation (note `sudo`):

```bash
$ sudo R CMD INSTALL bspm_[version].tar.gz
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
> bspm::enable() # wrap it in suppressMessages() to avoid the initial message
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

### Ubuntu

There are thousands of binary packages available via the
[c2d4u.team/c2d4u4.0+](https://launchpad.net/~c2d4u.team/+archive/ubuntu/c2d4u4.0+)
PPA repo:

```bash
$ sudo add-apt-repository ppa:marutter/rrutter4.0   # R v4.0 and higher
$ sudo add-apt-repository ppa:c2d4u.team/c2d4u4.0+  # R packages
$ sudo apt-get update && sudo apt-get install python3-{dbus,gi,apt}
```

Then, install `bspm` as a system package from CRAN:

```bash
$ sudo Rscript -e 'install.packages("bspm", repos="https://cran.r-project.org")'
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

### Arch

There are a number of binary CRAN packages available via the
[ArchRPkgs](https://github.com/dvdesolve/ArchRPkgs) repo
as well as Bioconductor packages via the
[BioArchLinux](https://github.com/BioArchLinux/Packages) repo:

```bash
$ echo -e "\n[desolve]\nServer = https://desolve.ru/archrepo/\$arch" \
  "\n[BioArchLinux]\nServer = https://repo.bioarchlinux.org/\$arch" \
  | sudo tee -a /etc/pacman.conf
$ sudo pacman -Sy && sudo pacman -S r pyalpm python-{dbus,gobject}
```

Then, install `bspm` as a system package from CRAN:

```bash
$ sudo Rscript -e 'install.packages("bspm", repos="https://cran.r-project.org")'
```

Then, to enable it system-wide (alternatively, use your `.Rprofile`):

```bash
$ echo "bspm::enable()" | sudo tee -a /usr/lib64/R/etc/Rprofile.site
```

## Moving the user library

After installing and enabling `bspm` in a system with a populated user library,
_package shadowing_ will prevent system packages from loading, because the user
library takes precedence in `.libPaths()`. To solve this, it is necessary to
install packages available in the system repos and remove them from the user
library, leaving there only GitHub packages, development versions, and so on.
This is achieved simply by calling `bspm::moveto_sys()`.

Additionally, `bspm` provides a script for mass-calling `bspm::moveto_sys()`
for several users and/or libraries, which allows sysadmins to easily deploy
`bspm` in a multi-user server. The script, which requires `sudo` privileges,
is called as follows:

```bash
$ Rscript -e bspm:::scripts mass_move user1 [user2 ...] [lib1 [lib2 ...]]
```

By default, it does a dry run, meaning that it won't touch anything and will
just report the user libraries found. To actually run the script, the `--run`
flag must be provided:

```bash
$ Rscript -e bspm:::scripts mass_move --run user1 [user2 ...] [lib1 [lib2 ...]]
```

## Developing new backends

New backends for other package managers can be added to `inst/service/backend`.
Each backend must implement the following functions:

- `def discover() -> dict({ "prefixes" : list, "exclusions" : list })`
- `def available(prefixes : list, exclusions : list) -> list`
- `def install(prefixes : list, pkgs : list, exclusions : list) -> list`
- `def remove(prefixes : list, pkgs : list, exclusions : list) -> list`

The last two functions receive a list of prefixes, a list of R package names and
a list of exclusions, and must return a list with those package names that could
not be processed (i.e., packages not found in the system repos). Any progress
should be reported to stdout.

## Support and troubleshooting

If you are experiencing an issue that is not listed here, or the solution
did not work for you, please do not hesitate to open a ticket at our
[GitHub issue tracker](https://github.com/Enchufa2/bspm/issues).

### Cannot connect to the system package manager

Symptom: you tried to install a package and you got this message.

```r
> install.packages(<some_package>)
Error in install.packages : cannot connect to the system package manager
```

This usually happens when `bspm` was installed in the user library or, as a
system package, it is not properly configured for some reason. The solution is:

1. First and foremost, **uninstall** any copy of `bspm` in your user library.
2. Reinstall with admin privileges, e.g.:

```bash
$ sudo Rscript --vanilla -e 'install.packages("bspm", repos="https://cran.r-project.org")'
```
