#' Manage Packages from System Repositories
#'
#' Talk to the system package manager to install/remove... packages from system
#' repositories.
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
#' @seealso \code{\link{integration}}
#'
#' @examples
#' \dontrun{
#' # install 'units' and all its dependencies from the system repos
#' bspm::install_sys("units")
#'
#' # now remove it
#' bspm::remove_sys("units")
#' }
#'
#' @name manager
#' @export
install_sys <- function(pkgs) backend_call("install", pkgs)

#' @name manager
#' @export
remove_sys <- function(pkgs) backend_call("remove", pkgs)

#' @details The \code{discover} method is only needed when e.g. a new repository
#' is added that contains packages with different prefixes (for example, your
#' system repositories may provide packages called \code{r-cran-*} and
#' \code{r-bioc-*} and then you add a new repository that provides packages
#' called \code{r-github-*}). Otherwise, it will not have any effect besides
#' regenerating the internal configuration files.
#'
#' @name manager
#' @export
discover <- function() backend_call("discover")
