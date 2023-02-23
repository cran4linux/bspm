suppressMessages(untrace(utils::install.packages))
expect_false(inherits(utils::install.packages, "functionWithTrace"))

suppressWarnings(expect_message(enable()))
expect_true(inherits(utils::install.packages, "functionWithTrace"))

tracer <- paste(body(utils::install.packages), collapse="")
expected <- "pkgs <- bspm::install_sys(pkgs)"
expect_true(grepl(expected, tracer, fixed=TRUE))

expect_message(disable())
expect_false(inherits(utils::install.packages, "functionWithTrace"))
