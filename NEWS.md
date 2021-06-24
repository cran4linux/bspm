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
