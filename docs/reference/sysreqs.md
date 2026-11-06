# Find System Requirements

Compute the system requirements (system libraries; operating system
packages) required by a set of R packages.

## Usage

``` r
sysreqs(pkgs, ..., type = c("build", "run"), distro = NULL,
  collapse = FALSE)
```

## Arguments

- pkgs:

  character vector of R package names.

- ...:

  unused, reserved for future expansion.

- type:

  type of requirements: build- or run-time requirements, or both.

- distro:

  name of the Linux distribution; if nothing is provided, the function
  tries to detect it automatically.

- collapse:

  whether to collapse the requirements into a single line.

## Value

A character vector of system requirements.

## Details

This function relies on https://github.com/cran4linux/sysreqs.
