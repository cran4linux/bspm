suppressMessages(untrace(utils::install.packages))
expect_false(inherits(utils::install.packages, "functionWithTrace"))

suppressWarnings(expect_message(enable()))
expect_true(inherits(utils::install.packages, "functionWithTrace"))

tracer <- paste(body(utils::install.packages), collapse="")
expect_true(sum(grepl("bspm", tracer, fixed=TRUE)) > 0)

expect_message(disable())
expect_false(inherits(utils::install.packages, "functionWithTrace"))
