if (!at_home() || !bspm:::root())
  exit_file("not in a CI environment")

if (requireNamespace("Rcpp", quietly=TRUE))
  exit_file("not in a clean environment")

bspm.pref <- system.file("service/bspm.pref", package="bspm")
bspm.excl <- system.file("service/bspm.excl", package="bspm")
expect_true(all(c(bspm.pref, bspm.excl) == ""))

discover()
bspm.pref <- system.file("service/bspm.pref", package="bspm")
bspm.excl <- system.file("service/bspm.excl", package="bspm")
expect_true(all(c(bspm.pref, bspm.excl) != ""))

.libPaths("/usr/lib/R/site-library") # for Debian
pkgs <- install_sys(c("Rcpp", "NOTAPACKAGE"))
expect_true(requireNamespace("Rcpp", quietly=TRUE))
expect_equal(pkgs, "NOTAPACKAGE")

unloadNamespace("Rcpp")
pkgs <- remove_sys(c("Rcpp", "NOTAPACKAGE"))
expect_false(requireNamespace("Rcpp", quietly=TRUE))
expect_equal(pkgs, "NOTAPACKAGE")
