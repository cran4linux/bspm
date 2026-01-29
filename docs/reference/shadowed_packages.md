# Find Shadowed Packages

Find packages that are *shadowed* by others in library locations with a
higher priority.

## Usage

``` r
shadowed_packages(lib.loc = NULL)
```

## Arguments

- lib.loc:

  character vector describing the location of the R library trees to
  search through, or `NULL` for all known trees (see
  [`.libPaths`](https://rdrr.io/r/base/libPaths.html)).

## Value

A `data.frame` with one row per package, row names the package names and
column names (currently) "Package", "LibPath", "Version",
"Shadow.LibPath", "Shadow.Version", "Shadow.Newer".

## Details

R supports setting several locations for library trees. This is a
powerful feature, but many times packages end up installed in multiple
locations, and in such cases R silently uses the one in the path with
the highest priority (appearing first in
[`.libPaths`](https://rdrr.io/r/base/libPaths.html)), thus *shadowing*
packages in locations with a lower priority.

For bspm installations, this means that outdated user packages may break
system libraries. This utility reports packages that are shadowed (one
per row) with information on which location ("Shadow.LibPath") and
version ("Shadow.Version") has priority over it. The
[`moveto_sys`](manager.md) method is a great complement to move such
outdated versions to the system libraries.

## See also

[`moveto_sys`](manager.md)
