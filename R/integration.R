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
#' \code{"never"} to always prefer binaries over source packages, with an
#' informative message about newer versions available from source.
#'
#' If binaries are always preferred and no message is required, a special
#' \emph{fast} mode can be enabled via \code{options(bspm.version.check=FALSE)},
#' (true by default) which completely skips version checking.
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

    if (type == "both" && !getOption("bspm.version.check", TRUE))
      type <- "binary-source"

    if (is.null(repos)) {
      type <- "source"
    } else if (type == "both") {
      # get pkgs with non-installed dependencies
      db <- available.packages(contriburl=contriburl, method=method,
                               type="source", ...)
      pkg_deps <- getFromNamespace("pkg_deps", asNamespace("bspm"))
      pkgs <- pkg_deps(pkgs, dependencies, db, ..., all=TRUE)

      # get available binaries and pkgs with later versions available
      check_versions <- getFromNamespace("check_versions", asNamespace("bspm"))
      pkgs <- check_versions(pkgs, db)

      # determine whether later versions should be installed
      ask_user <- getFromNamespace("ask_user", asNamespace("bspm"))
      later <- ask_user(pkgs$later, pkgs$bins, pkgs$binvers, pkgs$srcvers)

      # install binaries and forward the rest
      pkgs <- c(bspm::install_sys(pkgs$bins[!later]), pkgs$bins[later], pkgs$srcs)
      type <- "source"
    } else if (type == "binary") {
      # try just binaries and fail otherwise
      if (!length(pkgs <- bspm::install_sys(pkgs)))
        type <- "source"
    } else if (type == "binary-source") {
      # install as many binaries as possible and fallback to source
      if (length(pkgs <- bspm::install_sys(pkgs))) {
        db <- available.packages(contriburl=contriburl, method=method,
                                 type="source", ...)
        pkg_deps <- getFromNamespace("pkg_deps", asNamespace("bspm"))
        pkgs <- pkg_deps(pkgs, NA, db, ..., all=FALSE)
        if (length(pkgs)) bspm::install_sys(pkgs)
      }
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
