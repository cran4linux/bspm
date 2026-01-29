# bspm: Bridge to System Package Manager

Enables binary package installations on Linux distributions. Provides
functions to manage packages via the distribution's package manager.
Also provides transparent integration with R's `install.packages` and a
fallback mechanism. When installed as a system package, interacts with
the system's package manager without requiring administrative privileges
via an integrated D-Bus service; otherwise, uses sudo. Currently, the
following backends are supported: DNF, APT, ALPM.

## References

<https://cran4linux.github.io/bspm/>

## See also

[`manager`](manager.md), [`integration`](integration.md),
[`bspm-scripts`](bspm-scripts.md), [`bspm-options`](bspm-options.md)

## Author

Iñaki Ucar
