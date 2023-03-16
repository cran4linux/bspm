call_scripts <- function(args=NULL) {
  cmd <- paste(R.home("bin/Rscript"), "-e bspm:::scripts", args, "2>&1")
  system(cmd, intern=TRUE)
}

## list scripts
expect_silent(x <- call_scripts())
expect_true(any(grepl("mass_move # Call moveto_sys", x)))

## script not found
expect_warning(x <- call_scripts("asdf"))
expect_true(any(grepl("not found", x)))

## script found, no arguments
expect_warning(x <- call_scripts("mass_move"))
expect_true(any(grepl("Error: no user or library", x)))

## script found, help
expect_silent(x <- call_scripts("mass_move -h"))
expect_true(any(grepl("Usage: mass_move", x)))
