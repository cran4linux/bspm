# R Package Manager for Linux

Enables binary package installations on Linux distributions.
Provides a installation function that talks to a D-Bus service that manages
package installations via the distribution's package manager.

Currently, the following backends are supported: DNF.

## Installation

E.g., if your distro's R packages are called "r-cran-<pkgname>", then

```bash
sudo R CMD INSTALL PackageManager \
  --configure-vars="SYSCONF_DIR=/etc" \
  --configure-vars="DATA_DIR=/usr/share" \
  --configure-vars="PKG_PREFIX=r-cran-"
```

To enable it by default, put the following into the `Rprofile.site`:

```r
suppressMessages(PackageManager::enable())
```
