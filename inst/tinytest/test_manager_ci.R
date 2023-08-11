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

test_methods <- function() {
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

  unlink(c(bspm.pref, bspm.excl))
}

test_methods()

if (!nchar(Sys.which("dbus-daemon")) || !nchar(Sys.which("busctl")))
  exit_file("dbus tools not available")

dir.create("/run/dbus")
dbus <- system2("dbus-daemon", c("--system", "--print-pid"), stdout=TRUE)
trace(bspm:::backend_call, print=FALSE, tracer=quote(root <- function() FALSE))

test_methods()

untrace(bspm:::backend_call)
tools::pskill(dbus)
unlink("/run/dbus", recursive=TRUE)
