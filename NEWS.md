# bspm 0.3.2

- Implement functions to discover new prefixes dynamically (#3).

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
