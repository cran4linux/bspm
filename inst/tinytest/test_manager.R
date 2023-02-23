source("setup.R")

mock_available <- function(...) readRDS("db.rds")

mock_call <- function(method, pkgs=NULL) {
  available <- c("Rcpp", "magrittr")
  installed <<- c(installed, intersect(pkgs, available))
  setdiff(pkgs, available)
}

# mock functions
mock("available.packages", mock_available, "utils")
mock("backend_call", mock_call, "bspm")

installed <- NULL
pkgs <- install_sys(c("Rcpp", "simmer"))
expect_equal(pkgs, "simmer")
expect_equal(installed, "Rcpp")

source("teardown.R")
