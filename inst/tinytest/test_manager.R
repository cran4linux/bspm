mock_available <- function(...) readRDS("db.rds")

mock_call <- function(method, pkgs=NULL) {
  available <- c("Rcpp", "magrittr")
  installed <<- c(installed, intersect(pkgs, available))
  setdiff(pkgs, available)
}

mock <- function(fun, new, pkg) {
  ns <- asNamespace(pkg)
  old <- get(fun, ns)
  unlockBinding(fun, ns)
  assign(fun, new, ns)
  lockBinding(fun, ns)
  old
}

# mock functions
.available.packages <- mock("available.packages", mock_available, "utils")
.backend_call <- mock("backend_call", mock_call, "bspm")

expect_null(getOption("bspm.always.install.deps"))
installed <- NULL
pkgs <- install_sys(c("Rcpp", "simmer"))
expect_equal(pkgs, "simmer")
expect_equal(installed, "Rcpp")

options(bspm.always.install.deps=TRUE)
installed <- NULL
pkgs <- install_sys(c("Rcpp", "simmer"))
expect_equal(pkgs, "simmer")
expect_equal(installed, c("Rcpp", "Rcpp", "magrittr"))

# restore mocked functions and options
options(bspm.always.install.deps=NULL)
mock("available.packages", .available.packages, "utils")
mock("backend_call", .backend_call, "bspm")
