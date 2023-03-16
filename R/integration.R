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
  trace(utils::install.packages, print=FALSE, tracer=body(shim))
  invisible()
}

#' @name integration
#' @export
disable <- function() {
  options(pkgType="source")
  untrace(utils::install.packages)
  invisible()
}

shim <- function() {
  if (missing(pkgs)) stop("no packages were specified")

  if (type == "both" && !getOption("bspm.version.check", TRUE))
    type <- "binary-source"

  if (is.null(repos)) {
    type <- "source"
  } else if (type == "both") { # regular install, with version check
    pkgs <- utils::getFromNamespace("install_both", asNamespace("bspm"))(
      pkgs, contriburl, method, dependencies, ...)
    type <- "source"
  } else if (type == "binary") { # install binaries and fail otherwise
    if (!length(pkgs <- bspm::install_sys(pkgs)))
      type <- "source"
  } else if (type == "binary-source") { # fast path, no version check
    type <- "both" # restore
    pkgs <- utils::getFromNamespace("install_fast", asNamespace("bspm"))(
      pkgs, contriburl, method, ...)
    type <- "source"
  }
}

formals(shim) <- formals(utils::install.packages)
utils::globalVariables("contrib.url") # argument

# install binaries with checks for newer versions from source
install_both <- function(pkgs, contriburl, method, dependencies, ...) {
  db <- utils::available.packages(contriburl=contriburl, method=method, ...)
  pkgs <- pkg_deps(pkgs, dependencies, db, ..., all=TRUE)
  pkgs <- check_versions(pkgs, db)
  later <- ask_user(pkgs$later, pkgs$bins, pkgs$binvers, pkgs$srcvers)
  pkgs <- c(install_sys(pkgs$bins[!later]), pkgs$bins[later], pkgs$srcs)
  pkgs
}

# install as many binaries as possible and fallback to source
install_fast <- function(pkgs, contriburl, method, ...) {
  if (length(pkgs <- install_sys(pkgs))) {
    db <- utils::available.packages(contriburl=contriburl, method=method, ...)
    install_sys(pkg_deps(pkgs, NA, db=db, ..., all=FALSE))
  }
  pkgs
}
