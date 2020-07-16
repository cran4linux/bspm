untrace(utils::install.packages)
expect_false(inherits(utils::install.packages, "functionWithTrace"))

enable()
expect_true(inherits(utils::install.packages, "functionWithTrace"))

tracer <- paste(body(utils::install.packages), collapse="")
expected <- "if (!is.null(repos)) pkgs <- bspm::install_sys(pkgs)"
expect_true(grepl(expected, tracer, fixed=TRUE))

disable()
expect_false(inherits(utils::install.packages, "functionWithTrace"))
