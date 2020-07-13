#' Install Binary Packages from System Repositories
#'
#' Talk to the system package manager to download and install or remove
#' packages from system repositories.
#'
#' @param pkgs character vector of names of packages.
#' @return Invisibly, a character vector of the names of packages not available.
#'
#' @details The root user talks directly to the system package manager.
#' Non-root users talk to the accompanying D-Bus service, which performs the
#' required actions and returns packages that could not be processed.
#'
#' @export
install_sys <- function(pkgs) backend_call("install", pkgs)

#' @name install_sys
#' @export
remove_sys <- function(pkgs) backend_call("remove", pkgs)

#' Discover Packages from System Repositories
#'
#' Talk to the system package manager to discover new packages. Needed only
#' when e.g. a new repository is added that contains packages with different
#' prefixes (for example, your system repositories may provide packages called
#' \code{r-cran-*} and \code{r-bioc-*} and then you add a new repository that
#' provides packages called \code{r-github-*}).
#'
#' @export
discover <- function() backend_call("discover")
