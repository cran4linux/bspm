if (!at_home() || !bspm:::root())
  exit_file("not in a CI environment")

sudo.avail <- unname(nchar(Sys.which("sudo")) > 0)
in.toolbox <- file.exists("/run/.toolboxenv")
expect_false(getOption("bspm.sudo", FALSE))
bspm:::sudo_autodetect()
if (sudo.avail || in.toolbox) {
  expect_true(getOption("bspm.sudo", FALSE))
} else {
  expect_false(getOption("bspm.sudo", FALSE))
  file.create("/run/.toolboxenv")
  bspm:::sudo_autodetect()
  expect_true(getOption("bspm.sudo", FALSE))
}
options(bspm.sudo = NULL)

if (requireNamespace("Rcpp", quietly=TRUE))
  exit_file("not in a clean environment")

bspm.pref <- system.file("service/bspm.pref", package="bspm")
bspm.excl <- system.file("service/bspm.excl", package="bspm")
expect_true(all(c(bspm.pref, bspm.excl) == ""))

discover()
bspm.pref <- system.file("service/bspm.pref", package="bspm")
bspm.excl <- system.file("service/bspm.excl", package="bspm")
expect_true(all(c(bspm.pref, bspm.excl) != ""))

pkgs <- install_sys(c("Rcpp", "NOTAPACKAGE"))
expect_true(requireNamespace("Rcpp", quietly=TRUE))
expect_equal(pkgs, "NOTAPACKAGE")

unloadNamespace("Rcpp")
pkgs <- remove_sys(c("Rcpp", "NOTAPACKAGE"))
expect_false(requireNamespace("Rcpp", quietly=TRUE))
expect_equal(pkgs, "NOTAPACKAGE")
