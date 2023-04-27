# bspm devel

- Fix package deduplication in dependency getter (#68 addressing #67).
- Rename scripts manual page to `bspm-scripts`.

# bspm 0.5.1

- Add support for littler in scripts (@eddelbuettel in #64).
- Refactor + fixes + improve testing (#66 addressing #63).

# bspm 0.5.0

- New function `moveto_sys()` moves existing user packages to the system
  library to avoid _package shadowing_; the associated script `mass_move`
  enables mass-calling this function for several users and/or libraries to
  facilitate `bspm` deployment in multitenant servers (#60 addressing #59).
- New function `shadowed_packages()` analyzes the library tree and reports
  which packages, one per row, are shadowed by others (#62 addressing #58).
- Add new `options(bspm.version.check=FALSE)` (true by default) to globally
  enable `binary-source` installation type (#61).
- Add a specific manual page `bspm-options` documenting all supported options.
- Add support for the installation of binary Suggests and Enhances if they are
  supplied to the `dependencies` argument of `install.packages`.
  `LinkingTo` now is omitted for binary packages as documented (#32).

# bspm 0.4.2

- Fix error forwarding in root mode (#54).
- Fix installation error when `type="binary-source"` is set and
  a package without binary version available is requested (#56).
- Fix installation error in `options(pkgType="both")` mode (default) when an
  available binary is not available as source (#57).

# bspm 0.4.1

- New `type="binary-source"` option (or _fast mode_) tries to install as many
  binaries as possible (requested packages and dependencies), and then falls
  back to source installation (per @eddelbuettel's wish).
- Fix the call to `available.packages()` when the `repos` argument is specified
  (#52 addressing #51).

# bspm 0.4.0

- New function `available_sys()` returns a matrix of available packages with
  `"Package"`, `"Version"`, and `"Repository"` (#47 addressing #41).
- Honor `type` option, set by default to `"both"`, which means 'use binary
  if available and current, otherwise try source' (#48 addressing #46).
  As a consequence, the option `bspm.always.install.deps` has been removed.

# bspm 0.3.10

- Check backend availability on `enable()`, and trigger a warning if the
  service is required but not found. This check can be disabled by setting
  `options(bspm.backend.check=FALSE)` (#40).

# bspm 0.3.9

- Force `sudo` unconditionally also with autodetection (#27, #28).
- Call `update_cache` in DNF install transactions (#29).
- Add ALPM backend (#35 addressing #34).
- Fix repeated installation issue in APT backend (#36).

# bspm 0.3.8

- Fix spurious error with `options(bspm.always.install.deps=TRUE)` (#25).
- Ensure that `options(bspm.sudo=TRUE)` forces `sudo` unconditionally (#28).
- Add new `options(bspm.sudo.autodetect=TRUE)` (not set by default) to enable
  passwordless `sudo` autodetection on every call (#27).

# bspm 0.3.7

- Fix spurious error with `options(bspm.always.install.deps=TRUE)` (#24).

# bspm 0.3.6

- Make APT call fail if there are unmet dependencies (#20).
- Add new `options(bspm.always.install.deps=TRUE)` (not set by default) to
  always try to install recursive hard dependencies of packages from system
  repositories even if the requested package is not available (#14, #23).
- Add a note about SELinux (#19).

# bspm 0.3.5

- Fix noise when `busctl` is installed but there's no system bus (docker) (#12).
- Workaround issue with file permissions under `/tmp` (#13).
- Fix compatibility with Python 3.6 (#16 addressing #15).
- Workaround PATH for old versions of APT/dpkg (#17 addressing #15).
- Prioritize `options(bspm.sudo=TRUE)` over DBus calls (as part of #16), so that
  any DBus error or incompatibility can be at least bypassed with `sudo`.

# bspm 0.3.4

- Fix installation issue reported by CRAN on Solaris.

# bspm 0.3.3

- Cosmetic changes suggested by CRAN.
- Small configure fix.

# bspm 0.3.2

- Implement functions to discover new prefixes dynamically (#3).
- Fall back to `sudo` if no root permissions nor D-Bus service are available.
- More documentation, some examples, and testing.

# bspm 0.3.1

- Simplified installation, because D-Bus files are always in the same place.
- Support for multiple prefixes and exclusions (#1).
- Improve APT cache management (#4).
- Fix newlines in APT output (#5).
- Load D-Bus variables locally instead of in the global environment (#6).

# bspm 0.3.0

- New package name, as suggested by @eddelbuettel; improved title & description.
- Allow root user to talk directly to the system package manager, without D-Bus.

# PackageManager 0.2.1

- Add APT backend.

# PackageManager 0.2.0

- Initial fork from cran2copr project, reworked to make it extensible.
- Currently, only DNF backend supported.
