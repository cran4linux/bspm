if (!at_home() || !bspm:::root())
  exit_file("not in a CI environment")

sudo.avail <- unname(nchar(Sys.which("sudo")) > 0)
in.toolbox <- file.exists("/run/.toolboxenv")
if (sudo.avail || in.toolbox) {
  expect_true(bspm:::sudo_available())
} else {
  expect_false(bspm:::sudo_available())
  file.create("/run/.toolboxenv")
  expect_true(bspm:::sudo_available())
}

if (requireNamespace("Rcpp", quietly=TRUE))
  exit_file("not in a clean environment")

bspm.pref <- system.file("service/bspm.pref", package="bspm")
bspm.excl <- system.file("service/bspm.excl", package="bspm")
expect_true(all(c(bspm.pref, bspm.excl) == ""))

discover()
bspm.pref <- system.file("service/bspm.pref", package="bspm")
bspm.excl <- system.file("service/bspm.excl", package="bspm")
expect_true(all(c(bspm.pref, bspm.excl) != ""))

pkgs <- available_sys()
expect_inherits(pkgs, "matrix")
expect_equal(colnames(pkgs), c("Package", "Version", "Repository"))
expect_true(length(grep("Rcpp", rownames(pkgs), ignore.case=TRUE)) > 0)

pkgs <- install_sys(c("Rcpp", "NOTAPACKAGE"))
expect_true(requireNamespace("Rcpp", quietly=TRUE))
expect_equal(pkgs, "NOTAPACKAGE")

unloadNamespace("Rcpp")
pkgs <- remove_sys(c("Rcpp", "NOTAPACKAGE"))
expect_false(requireNamespace("Rcpp", quietly=TRUE))
expect_equal(pkgs, "NOTAPACKAGE")
