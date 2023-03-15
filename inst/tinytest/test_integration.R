source("setup.R")

# enable / disable ----

suppressMessages(untrace(utils::install.packages))
expect_false(inherits(utils::install.packages, "functionWithTrace"))

suppressWarnings(expect_message(enable()))
expect_true(inherits(utils::install.packages, "functionWithTrace"))
expect_equal(getOption("pkgType"), "both")

tracer <- paste(body(utils::install.packages), collapse="")
expect_true(sum(grepl("bspm", tracer, fixed=TRUE)) > 0)

expect_message(disable())
expect_false(inherits(utils::install.packages, "functionWithTrace"))
expect_equal(getOption("pkgType"), "source")

# shim ----

test_shim <- function(pkgs, repos = "https://cran.r-project.org",
                      contriburl = contrib.url(repos, type), method,
                      dependencies = NA, type = getOption("pkgType"), ...) {
  eval(body(bspm:::shim))
  list(pkgs=pkgs, type=type)
}

expect_error(test_shim(), "no packages")

## no return
mock_install <- function(msg) function(...) { warning(msg); character(0) }
mock("install_both", mock_install("both"), "bspm")
mock("install_sys",  mock_install("sys"),  "bspm")
mock("install_fast", mock_install("fast"), "bspm")

expect_silent(res <- test_shim("pkg", repos=NULL, type="both"))
expect_equal(res, list(pkgs="pkg", type="source"))
expect_silent(res <- test_shim("pkg", type="source"))
expect_equal(res, list(pkgs="pkg", type="source"))

expect_warning(res <- test_shim("pkg", type="both"), "both")
expect_equal(res, list(pkgs=character(0), type="source"))
expect_warning(res <- test_shim("pkg", type="binary"), "sys")
expect_equal(res, list(pkgs=character(0), type="source"))
expect_warning(res <- test_shim("pkg", type="binary-source"), "fast")
expect_equal(res, list(pkgs=character(0), type="source"))

options(bspm.version.check=FALSE)
expect_warning(res <- test_shim("pkg", type="both"), "fast")
expect_equal(res, list(pkgs=character(0), type="source"))
options(bspm.version.check=NULL)

unmock_all()

## return
mock_install <- function(pkgs, contriburl, ...) {
  expect_inherits(contriburl, "character")
  "notavail"
}
mock("install_both", mock_install, "bspm")
mock("install_sys",  function(...) "notavail", "bspm")
mock("install_fast", mock_install, "bspm")

res <- test_shim("pkg", type="both")
expect_equal(res, list(pkgs="notavail", type="source"))
res <- test_shim("pkg", type="binary")
expect_equal(res, list(pkgs="notavail", type="binary"))
res <- test_shim("pkg", type="binary-source")
expect_equal(res, list(pkgs="notavail", type="source"))

unmock_all()

source("teardown.R")
