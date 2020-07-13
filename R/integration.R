#' Enable/Disable Bridge to System Package Manager
#'
#' Functions to enable or disable the integration of \code{\link{install_sys}}
#' into \code{\link{install.packages}}. When enabled, packages are installed
#' transparently from system repositories if available, and from the configured
#' \R repositories if not.
#'
#' @details To enable \pkg{bspm} system-wide by default, include the following:
#'
#' \code{suppressMessages(bspm::enable())}
#'
#' into the \code{Rprofile.site} file. To enable it just for a particular user,
#' move that line to the user's \code{~/.Rprofile} instead.
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
  expr <- quote(if (!is.null(repos)) pkgs <- bspm::install_sys(pkgs))
  trace(utils::install.packages, expr, print=FALSE)
  invisible()
}

#' @name integration
#' @export
disable <- function() {
  untrace(utils::install.packages)
  invisible()
}
