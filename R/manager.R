#' Manage Packages from System Repositories
#'
#' Talk to the system package manager to install/remove... packages from system
#' repositories (see details for further options).
#'
#' @param pkgs character vector of names of packages.
#' @return Functions \code{install_sys} and \code{remove_sys} return, invisibly,
#' a character vector of the names of packages not available in the system.
#'
#' @details If \R runs with root privileges (e.g., in a docker container), these
#' functions talk directly to the system package manager. Regular users are also
#' able to install/remove packages without any administrative permission via the
#' accompanying D-Bus service if \pkg{bspm} is installed as a system package.
#' If not, these methods fall back on using \code{sudo} to elevate permissions
#' (or \code{pkexec} in GUIs such as RStudio) in interactive sessions. Note
#' that, if you want to fall back to \code{sudo} in a non-interactive session,
#' you need to set \code{options(bspm.sudo=TRUE)}.
#'
#' If \code{options(bspm.sudo.autodetect=TRUE)}, \pkg{bspm} tries to detect
#' whether it is running in an environment where password-less \code{sudo} can
#' be used (e.g., in a containerized environment such as a Fedora Toolbox) for
#' every call, and then uses \code{sudo} accordingly.
#'
#' By default, if a package is not available in the system repositories, it is
#' installed from R's configured repositories along with all its dependencies.
#' This behavior can be changed via \code{options(bspm.always.install.deps=TRUE)},
#' which tries to install from system repositories recursive dependencies of
#' those packages that are not available. For example, if \pkg{A} depends on
#' \pkg{B}, and \pkg{B} is available in the system repositories but \pkg{A} is
#' not, then only \pkg{A} will be installed from CRAN with this option enabled,
#' and both will be installed from CRAN with this option disabled (default).
#'
#' @seealso \code{\link{integration}}
#'
#' @examples
#' \dontrun{
#' # install 'units' and all its dependencies from the system repos
#' bspm::install_sys("units")
#'
#' # now remove it
#' bspm::remove_sys("units")
#'
#' # get available packages
#' bspm::available_sys()
#' }
#'
#' @name manager
#' @export
install_sys <- function(pkgs) {
  not.avail <- backend_call("install", pkgs)
  if (length(not.avail) && getOption("bspm.always.install.deps", FALSE)) {
    deps <- tools::package_dependencies(not.avail, recursive=TRUE)
    deps <- unique(unlist(deps, use.names=FALSE))
    if (length(deps)) backend_call("install", deps)
  }
  invisible(not.avail)
}

#' @name manager
#' @export
remove_sys <- function(pkgs) invisible(backend_call("remove", pkgs))

#' @return Function \code{available_sys} returns a matrix with one row per
#' package. Row names are the package names, and column names include
#' \code{"Package"}, \code{"Version"}, \code{"Repository"}.
#'
#' @name manager
#' @export
available_sys <- function() {
  pkgs <- do.call(rbind, strsplit(backend_call("available"), " "))
  colnames(pkgs) <- c("Package", "Version", "Repository")
  rownames(pkgs) <- pkgs[, 1]
  pkgs
}

#' @details The \code{discover} method is only needed when e.g. a new repository
#' is added that contains packages with different prefixes (for example, your
#' system repositories may provide packages called \code{r-cran-*} and
#' \code{r-bioc-*} and then you add a new repository that provides packages
#' called \code{r-github-*}). Otherwise, it will not have any effect besides
#' regenerating the internal configuration files.
#'
#' @name manager
#' @export
discover <- function() invisible(backend_call("discover"))
