# Enable/Disable Bridge to System Package Manager

Functions to enable or disable the integration of
[`install_sys`](manager.md) into
[`install.packages`](https://rdrr.io/r/utils/install.packages.html).
When enabled, packages are installed transparently from system
repositories if available, including dependencies, and from the
configured R repositories if not.

## Usage

``` r
enable()

disable()
```

## Details

To enable bspm system-wide by default, include the following:

`suppressMessages(bspm::enable())`

into the `Rprofile.site` file. To enable it just for a particular user,
move that line to the user's `~/.Rprofile` instead.

By default, enabling bspm triggers a check of the backend, and a warning
is raised if the system service is required but not available. To avoid
this check, `options(bspm.backend.check=FALSE)` can be set.

Enabling bspm sets default installation `type` to `"both"`, which means
'use binary if available and current, otherwise try source'. The action
if there are source packages which are preferred is controlled by
`getOption("install.packages.compile.from.source")`. Set this option to
`"never"` to always prefer binaries over source packages, with an
informative message about newer versions available from source.

If binaries are always preferred and no message is required, a special
*fast* mode can be enabled via `options(bspm.version.check=FALSE)`,
(true by default) which completely skips version checking.

## See also

[`manager`](manager.md), [`bspm-options`](bspm-options.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# install 'units' and all its dependencies from the system repos
bspm::enable()
install.packages("units")

# install packages again from CRAN
bspm::disable()
install.packages("errors")
} # }
```
