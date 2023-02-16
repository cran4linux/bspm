#' Call Internal Scripts
#'
#' Internal scripts can be called via \code{Rscript} (see examples).
#'
#' @examples
#' \dontrun{
#' # get a list of available scripts with descriptions
#' Rscript -e bspm:::scripts
#'
#' # see a script's help
#' Rscript -e bspm:::scripts <script_name> -h
#'
#' # run a script
#' Rscript -e bspm:::scripts <script_name> [args]
#' }
#'
#' @name scripts
NULL

scripts <- function(x, ...) {
  exit <- function(status, msg) {
    if (!missing(msg)) message("Error: ", msg)
    quit(status=status)
  }

  argv <- commandArgs(TRUE)
  scrp <- list.files(system.file("scripts", package="bspm"), full.names=TRUE)
  names(scrp) <- tools::file_path_sans_ext(basename(scrp))

  if (interactive() || !length(argv)) {
    for (i in names(scrp))
      cat(paste(i, readLines(scrp[i])[2]), fill=TRUE)
    return(invisible())
  }

  if (!argv[1] %in% names(scrp))
    exit(-1, paste0("script '", argv[1], "' not found"))
  else exit(system2(scrp[argv[1]], argv[-1]))
}

class(scripts) <- "bspm cli"

.onLoad <- function(libname, pkgname) {
  registerS3method("print", "bspm cli", scripts, asNamespace(pkgname))
}