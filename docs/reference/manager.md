# Manage Packages from System Repositories

Talk to the system package manager to install/remove... packages from
system repositories (see details for further options).

## Usage

``` r
install_sys(pkgs)

remove_sys(pkgs)

moveto_sys(lib, newer = FALSE)

available_sys()

discover()
```

## Arguments

- pkgs:

  character vector of names of packages.

- lib:

  a character vector giving the library directories to remove the
  packages from. If missing, defaults to the first element in
  `R_LIBS_USER`.

- newer:

  whether to move newer packages from the user library. The special
  value `"ask"` is also supported.

## Value

Functions `install_sys`, `remove_sys`, and `moveto_sys` return,
invisibly, a character vector of the names of packages not available in
the system.

Function `available_sys` returns a matrix with one row per package. Row
names are the package names, and column names include `"Package"`,
`"Version"`, `"Repository"`.

## Details

If R runs with root privileges (e.g., in a docker container), these
functions talk directly to the system package manager. Regular users are
also able to install/remove packages without any administrative
permission via the accompanying D-Bus service if bspm is installed as a
system package. If not, these methods fall back on using `sudo` to
elevate permissions (or `pkexec` in GUIs such as RStudio) in interactive
sessions. Note that, if you want to fall back to `sudo` in a
non-interactive session, you need to set `options(bspm.sudo=TRUE)`.

If `options(bspm.sudo.autodetect=TRUE)`, bspm tries to detect whether it
is running in an environment where password-less `sudo` can be used
(e.g., in a containerized environment such as a Fedora Toolbox) for
every call, and then uses `sudo` accordingly.

The `moveto_sys` method moves existing user packages to the system
library to avoid *package shadowing* (i.e., installs the available
system packages and removes copies from the user library; see
[`shadowed_packages`](shadowed_packages.md)). This provides a mechanism
to easily deploy bspm on an existing R installation with a populated
user library.

The `discover` method is only needed when e.g. a new repository is added
that contains packages with different prefixes (for example, your system
repositories may provide packages called `r-cran-*` and `r-bioc-*` and
then you add a new repository that provides packages called
`r-github-*`). Otherwise, it will not have any effect besides
regenerating the internal configuration files.

## See also

[`integration`](integration.md), [`bspm-scripts`](bspm-scripts.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# install 'units' and all its dependencies from the system repos
bspm::install_sys("units")

# now remove it
bspm::remove_sys("units")

# get available packages
bspm::available_sys()
} # }
```
