# Changelog

## bspm 0.5.8

CRAN release: 2026-01-29

- Fix “invalid escape sequence” SyntaxWarning
  ([@pekkarr](https://github.com/pekkarr) in
  [\#84](https://github.com/cran4linux/bspm/issues/84)).
- Catch and show early errors (e.g. no backend found) in root mode.
- Workaround for duplicated `row.names` in `shadowed_packages`.

## bspm 0.5.7

CRAN release: 2024-04-10

- Restrict D-Bus service configuration to installations in Linux
  machines with admininistrative privileges.

## bspm 0.5.6

CRAN release: 2024-04-09

- Move to cran4linux org on GitHub, update URLs.
- Try binary installation of build-only dependencies for source packages
  ([\#82](https://github.com/cran4linux/bspm/issues/82) addressing
  [\#81](https://github.com/cran4linux/bspm/issues/81)).

## bspm 0.5.5

CRAN release: 2023-08-22

- Fix test to feed character input to `numeric_version`.

## bspm 0.5.4

CRAN release: 2023-08-10

- Fix DNF backend to ensure that the system configuration is used
  (228407a).
- Minor documentation improvements.

## bspm 0.5.3

CRAN release: 2023-07-15

- Add workaround for underscores in Arch package versions
  ([\#71](https://github.com/cran4linux/bspm/issues/71)).
- Fix BioArchLinux instructions in README.
- Fix discovery of installed system packages in Arch
  ([\#73](https://github.com/cran4linux/bspm/issues/73)).

## bspm 0.5.2

CRAN release: 2023-05-20

- Fix package deduplication in dependency getter
  ([\#68](https://github.com/cran4linux/bspm/issues/68) addressing
  [\#67](https://github.com/cran4linux/bspm/issues/67)).
- Rename scripts manual page to `bspm-scripts`.

## bspm 0.5.1

CRAN release: 2023-03-16

- Add support for littler in scripts
  ([@eddelbuettel](https://github.com/eddelbuettel) in
  [\#64](https://github.com/cran4linux/bspm/issues/64)).
- Refactor + fixes + improve testing
  ([\#66](https://github.com/cran4linux/bspm/issues/66) addressing
  [\#63](https://github.com/cran4linux/bspm/issues/63)).

## bspm 0.5.0

CRAN release: 2023-02-19

- New function [`moveto_sys()`](../reference/manager.md) moves existing
  user packages to the system library to avoid *package shadowing*; the
  associated script `mass_move` enables mass-calling this function for
  several users and/or libraries to facilitate `bspm` deployment in
  multitenant servers
  ([\#60](https://github.com/cran4linux/bspm/issues/60) addressing
  [\#59](https://github.com/cran4linux/bspm/issues/59)).
- New function
  [`shadowed_packages()`](../reference/shadowed_packages.md) analyzes
  the library tree and reports which packages, one per row, are shadowed
  by others ([\#62](https://github.com/cran4linux/bspm/issues/62)
  addressing [\#58](https://github.com/cran4linux/bspm/issues/58)).
- Add new `options(bspm.version.check=FALSE)` (true by default) to
  globally enable `binary-source` installation type
  ([\#61](https://github.com/cran4linux/bspm/issues/61)).
- Add a specific manual page `bspm-options` documenting all supported
  options.
- Add support for the installation of binary Suggests and Enhances if
  they are supplied to the `dependencies` argument of
  `install.packages`. `LinkingTo` now is omitted for binary packages as
  documented ([\#32](https://github.com/cran4linux/bspm/issues/32)).

## bspm 0.4.2

CRAN release: 2023-02-09

- Fix error forwarding in root mode
  ([\#54](https://github.com/cran4linux/bspm/issues/54)).
- Fix installation error when `type="binary-source"` is set and a
  package without binary version available is requested
  ([\#56](https://github.com/cran4linux/bspm/issues/56)).
- Fix installation error in `options(pkgType="both")` mode (default)
  when an available binary is not available as source
  ([\#57](https://github.com/cran4linux/bspm/issues/57)).

## bspm 0.4.1

CRAN release: 2023-01-09

- New `type="binary-source"` option (or *fast mode*) tries to install as
  many binaries as possible (requested packages and dependencies), and
  then falls back to source installation (per
  [@eddelbuettel](https://github.com/eddelbuettel)’s wish).
- Fix the call to
  [`available.packages()`](https://rdrr.io/r/utils/available.packages.html)
  when the `repos` argument is specified
  ([\#52](https://github.com/cran4linux/bspm/issues/52) addressing
  [\#51](https://github.com/cran4linux/bspm/issues/51)).

## bspm 0.4.0

CRAN release: 2022-11-24

- New function [`available_sys()`](../reference/manager.md) returns a
  matrix of available packages with `"Package"`, `"Version"`, and
  `"Repository"` ([\#47](https://github.com/cran4linux/bspm/issues/47)
  addressing [\#41](https://github.com/cran4linux/bspm/issues/41)).
- Honor `type` option, set by default to `"both"`, which means ‘use
  binary if available and current, otherwise try source’
  ([\#48](https://github.com/cran4linux/bspm/issues/48) addressing
  [\#46](https://github.com/cran4linux/bspm/issues/46)). As a
  consequence, the option `bspm.always.install.deps` has been removed.

## bspm 0.3.10

CRAN release: 2022-08-05

- Check backend availability on
  [`enable()`](../reference/integration.md), and trigger a warning if
  the service is required but not found. This check can be disabled by
  setting `options(bspm.backend.check=FALSE)`
  ([\#40](https://github.com/cran4linux/bspm/issues/40)).

## bspm 0.3.9

CRAN release: 2022-01-04

- Force `sudo` unconditionally also with autodetection
  ([\#27](https://github.com/cran4linux/bspm/issues/27),
  [\#28](https://github.com/cran4linux/bspm/issues/28)).
- Call `update_cache` in DNF install transactions
  ([\#29](https://github.com/cran4linux/bspm/issues/29)).
- Add ALPM backend ([\#35](https://github.com/cran4linux/bspm/issues/35)
  addressing [\#34](https://github.com/cran4linux/bspm/issues/34)).
- Fix repeated installation issue in APT backend
  ([\#36](https://github.com/cran4linux/bspm/issues/36)).

## bspm 0.3.8

CRAN release: 2021-06-25

- Fix spurious error with `options(bspm.always.install.deps=TRUE)`
  ([\#25](https://github.com/cran4linux/bspm/issues/25)).
- Ensure that `options(bspm.sudo=TRUE)` forces `sudo` unconditionally
  ([\#28](https://github.com/cran4linux/bspm/issues/28)).
- Add new `options(bspm.sudo.autodetect=TRUE)` (not set by default) to
  enable passwordless `sudo` autodetection on every call
  ([\#27](https://github.com/cran4linux/bspm/issues/27)).

## bspm 0.3.7

CRAN release: 2020-10-15

- Fix spurious error with `options(bspm.always.install.deps=TRUE)`
  ([\#24](https://github.com/cran4linux/bspm/issues/24)).

## bspm 0.3.6

CRAN release: 2020-10-13

- Make APT call fail if there are unmet dependencies
  ([\#20](https://github.com/cran4linux/bspm/issues/20)).
- Add new `options(bspm.always.install.deps=TRUE)` (not set by default)
  to always try to install recursive hard dependencies of packages from
  system repositories even if the requested package is not available
  ([\#14](https://github.com/cran4linux/bspm/issues/14),
  [\#23](https://github.com/cran4linux/bspm/issues/23)).
- Add a note about SELinux
  ([\#19](https://github.com/cran4linux/bspm/issues/19)).

## bspm 0.3.5

CRAN release: 2020-08-24

- Fix noise when `busctl` is installed but there’s no system bus
  (docker) ([\#12](https://github.com/cran4linux/bspm/issues/12)).
- Workaround issue with file permissions under `/tmp`
  ([\#13](https://github.com/cran4linux/bspm/issues/13)).
- Fix compatibility with Python 3.6
  ([\#16](https://github.com/cran4linux/bspm/issues/16) addressing
  [\#15](https://github.com/cran4linux/bspm/issues/15)).
- Workaround PATH for old versions of APT/dpkg
  ([\#17](https://github.com/cran4linux/bspm/issues/17) addressing
  [\#15](https://github.com/cran4linux/bspm/issues/15)).
- Prioritize `options(bspm.sudo=TRUE)` over DBus calls (as part of
  [\#16](https://github.com/cran4linux/bspm/issues/16)), so that any
  DBus error or incompatibility can be at least bypassed with `sudo`.

## bspm 0.3.4

CRAN release: 2020-08-03

- Fix installation issue reported by CRAN on Solaris.

## bspm 0.3.3

CRAN release: 2020-08-01

- Cosmetic changes suggested by CRAN.
- Small configure fix.

## bspm 0.3.2

- Implement functions to discover new prefixes dynamically
  ([\#3](https://github.com/cran4linux/bspm/issues/3)).
- Fall back to `sudo` if no root permissions nor D-Bus service are
  available.
- More documentation, some examples, and testing.

## bspm 0.3.1

- Simplified installation, because D-Bus files are always in the same
  place.
- Support for multiple prefixes and exclusions
  ([\#1](https://github.com/cran4linux/bspm/issues/1)).
- Improve APT cache management
  ([\#4](https://github.com/cran4linux/bspm/issues/4)).
- Fix newlines in APT output
  ([\#5](https://github.com/cran4linux/bspm/issues/5)).
- Load D-Bus variables locally instead of in the global environment
  ([\#6](https://github.com/cran4linux/bspm/issues/6)).

## bspm 0.3.0

- New package name, as suggested by
  [@eddelbuettel](https://github.com/eddelbuettel); improved title &
  description.
- Allow root user to talk directly to the system package manager,
  without D-Bus.
