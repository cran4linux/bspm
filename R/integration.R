#' Enable/Disable Bridge to System Package Manager
#'
#' Functions to enable or disable the integration of \code{\link{install_sys}}
#' into \code{\link{install.packages}}. When enabled, packages are installed
#' transparently from system repositories if available, including dependencies,
#' and from the configured \R repositories if not.
#'
#' @details To enable \pkg{bspm} system-wide by default, include the following:
#'
#' \code{suppressMessages(bspm::enable())}
#'
#' into the \code{Rprofile.site} file. To enable it just for a particular user,
#' move that line to the user's \code{~/.Rprofile} instead.
#'
#' By default, enabling \pkg{bspm} triggers a check of the backend, and a
#' warning is raised if the system service is required but not available. To
#' avoid this check, \code{options(bspm.backend.check=FALSE)} can be set.
#'
#' Enabling \pkg{bspm} sets default installation \code{type} to \code{"both"},
#' which means 'use binary if available and current, otherwise try source'.
#' The action if there are source packages which are preferred is controlled by
#' \code{getOption("install.packages.compile.from.source")}. Set this option to
#' \code{"never"} to always prefer binaries over source packages.
#'
#' @seealso \code{\link{manager}}
#'
#' @examples
#' \dontrun{
#' # install 'units' and all its dependencies from the system repos
#' bspm::enable()
#' install.packages("units")
#'
#' # install packages again from CRAN
#' bspm::disable()
#' install.packages("errors")
#' }
#'
#' @name integration
#' @export
enable <- function() {
  if (getOption("bspm.backend.check", TRUE))
    backend_check()

  options(pkgType="both")

  trace(utils::install.packages, print=FALSE, tracer=quote({
    if (missing(pkgs)) stop("no packages were specified")

    if (is.null(repos)) {
      type <- "source"
    } else if (grepl("[.]tar[.](gz|bz2|xz)$", pkgs)) {
      repos <- NULL
      type <- "source"
      message("inferring 'repos = NULL' from 'pkgs'")
    } else if (type == "both") {
      if (is.null(repos))
        stop("type == \"both\" cannot be used with 'repos = NULL'")

      # get pkgs with non-installed dependencies
      dbs <- available.packages(type="source")
      inst <- row.names(installed.packages(.Library.site))
      pkgs <- tools::package_dependencies(pkgs, dbs, recursive=TRUE)
      pkgs <- lapply(pkgs, function(x) setdiff(x, inst))
      pkgs <- unique(c(names(pkgs), unlist(pkgs, use.names=FALSE)))

      # get available binaries and pkgs with later versions available
      dbb <- bspm::available_sys()
      row.names(dbb) <- tolower(row.names(dbb))
      bins <- pkgs[tolower(pkgs) %in% row.names(dbb)]
      srcs <- pkgs[! pkgs %in% bins]
      binvers <- dbb[tolower(bins), "Version"]
      srcvers <- dbs[bins, "Version"]
      later <- as.numeric_version(binvers) < srcvers

      # determine whether later versions should be installed
      if (any(later)) {
        msg <- ngettext(
          sum(later),
          "There is a binary version available but the source version is later",
          "There are binary versions available but the source versions are later")
        cat("\n", paste(strwrap(msg, indent = 2, exdent = 2), collapse = "\n"),
            ":\n", sep = "")
        print(data.frame(`binary` = binvers, `source` = srcvers,
                         row.names = bins, check.names = FALSE)[later, ])
        cat("\n")
        action <- getOption("install.packages.compile.from.source", "interactive")
        if (action == "interactive" && interactive()) {
          msg <- gettext("Do you want to install later versions from sources?")
          res <- utils::askYesNo(msg)
          if (is.na(res)) stop("Cancelled by user")
          if (!isTRUE(res)) later <- FALSE
        } else if (action == "never") {
          cat("  Binaries will be installed\n")
          later <- FALSE
        }
      }

      # install binaries and forward the rest
      pkgs <- c(bspm::install_sys(bins[!later]), bins[later], srcs)
      type <- "source"
    } else if (type == "binary") {
      # try just binaries and fail otherwise
      if (!length(pkgs <- bspm::install_sys(pkgs)))
        type <- "source"
    }
  }))

  invisible()
}

#' @name integration
#' @export
disable <- function() {
  options(pkgType="source")
  untrace(utils::install.packages)
  invisible()
}
