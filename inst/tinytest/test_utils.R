source("setup.R")

# shadowed_packages ----

df <- shadowed_packages()
expect_inherits(df, "data.frame")
expect_equal(colnames(df), c("Package", "LibPath", "Version",
                             "Shadow.LibPath", "Shadow.Version", "Shadow.Newer"))
expect_equal(df$Version < df$Shadow.Version, df$Shadow.Newer)

# pkg_deps ----

mock("installed.packages", pkg="utils", function(...)
  matrix(1:2, dimnames=list(c("codetools", "rticles"), NULL)))

pkgs <- c("simmer", "simmer")
db <- readRDS("db.rds")

deps <- c("Rcpp", "magrittr", "utils", "methods", "BH")
expect_equal(sort(bspm:::pkg_deps(pkgs, NA, db, all=FALSE)), sort(deps))
deps <- c(deps[-length(deps)], "simmer")
expect_equal(sort(bspm:::pkg_deps(pkgs, NA, db, all=TRUE)), sort(deps))
deps <- c(deps, "simmer.plot", "parallel", "testthat", "knitr", "rmarkdown")
expect_equal(sort(bspm:::pkg_deps(pkgs, TRUE, db, all=TRUE)), sort(deps))
expect_equal(sort(bspm:::pkg_deps(pkgs, "Suggests", db, all=TRUE)), sort(deps))

unmock_all()

# check_versions ----

mock("available_sys", pkg="bspm", function() {
  matrix(c("1.81.0.0", "1.0.10", "1"),
         dimnames=list(c("bh", "Rcpp", "another"), "Version"))
})

pkgs <- c("another", "Rcpp", "BH", "simmer")
db <- readRDS("db.rds")

out <- bspm:::check_versions(pkgs, db)
expect_equal(out$bins, c("another", "Rcpp", "BH"))
expect_equal(out$srcs, "simmer")
expect_equal(out$binvers, c(another="1", rcpp="1.0.10", bh="1.81.0.0"))
expect_equal(out$srcvers, c(another="0", Rcpp="1.0.10", BH="1.81.0-1"))
# expect_equal(out$later, c(another=FALSE, rcpp=FALSE, bh=TRUE))
# R >= 4.3 seems to drop names in this case, bug?
expect_equal(unname(out$later), c(FALSE, FALSE, TRUE))

unmock_all()

# remotes_as_newer ----

mock("packageDescription", pkg="utils", function(bin, lib, field) {
  if (field != "RemoteSha") stop("wrong field")
  switch(bin, sha="sha", NA)
})

pkgs <- list(
  binvers = c(1, 1, 1),
  srcvers = c(2, 1, 1),
  bins = c("a", "a", "sha"),
  later = c(FALSE, FALSE, FALSE)
)
expect_equal(bspm:::remotes_as_newer(pkgs)$later, c(FALSE, FALSE, TRUE))

unmock_all()

# ask_user ----

## prefer later sources (default)
options(install.packages.compile.from.source="bypass interactive")

x <- c(FALSE, FALSE)
expect_silent(later <- bspm:::ask_user(x, c("a", "b"), c(1, 1), c(1, 1)))
expect_equal(later, x)

x <- c(TRUE, FALSE)
expect_stdout(later <- bspm:::ask_user(x, c("a", "b"), c(1, 1), c(2, 1)),
               "available but the source")
expect_equal(later, x)

x <- c(TRUE, TRUE)
expect_stdout(later <- bspm:::ask_user(x, c("a", "b"), c(1, 1), c(2, 2)),
               "available but the source")
expect_equal(later, x)

## prefer binaries
options(install.packages.compile.from.source="never")

x <- c(FALSE, FALSE)
expect_silent(later <- bspm:::ask_user(x, c("a", "b"), c(1, 1), c(1, 1)))
expect_equal(later, x)

x <- c(TRUE, FALSE)
expect_stdout(later <- bspm:::ask_user(x, c("a", "b"), c(1, 1), c(2, 1)),
              "Binaries will be preferred")
expect_equal(later, FALSE)

x <- c(TRUE, TRUE)
expect_stdout(later <- bspm:::ask_user(x, c("a", "b"), c(1, 1), c(2, 2)),
              "Binaries will be preferred")
expect_equal(later, FALSE)

source("teardown.R")
