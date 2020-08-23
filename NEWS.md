# bspm 0.3.4.2

- Fix noise when `busctl` is installed but there's no system bus (docker) (#12).
- Workaround issue with file permissions under `/tmp` (#13).
- Fix compatibility with Python 3.6 (#15).

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
