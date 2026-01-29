# Package Options

List of [`options()`](https://rdrr.io/r/base/options.html) supported to
configure bspm's behavior. In general, these should be set *before*
calling any package function.

## Options specific to bspm

- `bspm.backend.check`::

  logical, default `TRUE`. If false, the initial check on
  [`enable()`](integration.md) is not performed.

- `bspm.version.check`::

  logical, default `TRUE`. If false, as many binaries are installed as
  possible without any version check, and then installation from source
  is used as a fallback.

- `bspm.sudo.autodetect`::

  logical, default `FALSE`. If true, enables autodetection and selection
  of password-less `sudo`.

- `bspm.sudo`::

  logical, default `FALSE`. If true, forces `sudo` unconditionally as
  the preferred mechanism.

## Options from base R

These are used in the same way as in base R. See
[`options`](https://rdrr.io/r/base/options.html) for a detailed
description.

- `askYesNo`

- `install.packages.compile.from.source`
