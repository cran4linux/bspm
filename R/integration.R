#' Enable/Disable Bridge to System Package Manager
#'
#' Functions to enable or disable the integration of \code{\link{install_sys}}
#' into \code{\link{install.packages}}. When enabled, packages are installed
#' transparently from system repositories if available, and from CRAN if not.
#'
#' @export
enable <- function() {
  expr <- quote(if (!is.null(repos)) pkgs <- bspm::install_sys(pkgs))
  trace(utils::install.packages, expr, print=FALSE)
  invisible()
}

#' @name enable
#' @export
disable <- function() {
  untrace(utils::install.packages)
  invisible()
}
