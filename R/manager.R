#' Manage Packages from System Repositories
#'
#' Talk to the system package manager to install/remove... packages from system
#' repositories (see details for further options).
#'
#' @param pkgs character vector of names of packages.
#' @return Functions \code{install_sys}, \code{remove_sys}, and \code{moveto_sys}
#' return, invisibly, a character vector of the names of packages not available
#' in the system.
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
#' @seealso \code{\link{integration}}, \code{\link{bspm-scripts}}
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
install_sys <- function(pkgs) invisible(backend_call("install", pkgs))

#' @name manager
#' @export
remove_sys <- function(pkgs) invisible(backend_call("remove", pkgs))

#' @param lib a character vector giving the library directories to remove the
#' packages from. If missing, defaults to the first element in \code{R_LIBS_USER}.
#' @param newer whether to move newer packages from the user library.
#' The special value \code{"ask"} is also supported.
#'
#' @details The \code{moveto_sys} method moves existing user packages to the
#' system library to avoid \emph{package shadowing} (i.e., installs the
#' available system packages and removes copies from the user library;
#' see \code{\link{shadowed_packages}}).
#' This provides a mechanism to easily deploy \pkg{bspm} on an existing R
#' installation with a populated user library.
#'
#' @name manager
#' @export
moveto_sys <- function(lib, newer=FALSE) {
  stopifnot(is.logical(newer) || newer == "ask")
  if (missing(lib)) lib <- user_lib()
  if (!dir.exists(lib)) return(invisible())

  if (isTRUE(newer)) {
    pkgs <- utils::installed.packages(lib)[, "Package"]
    notavail <- install_sys(pkgs)
    utils::remove.packages(setdiff(pkgs, notavail), lib)
    invisible(notavail)
  } else {
    db <- utils::installed.packages(lib)
    pkgs <- row.names(db)
    pkgs <- remotes_as_newer(check_versions(pkgs, db), lib)
    later <- pkgs$later; if (interactive() && newer == "ask")
      later <- ask_user(pkgs$later, pkgs$bins, pkgs$binvers, pkgs$srcvers)
    install_sys(pkgs$bins[!later])
    utils::remove.packages(pkgs$bins[!later], lib)
    invisible(c(pkgs$bins[later], pkgs$srcs))
  }
}

user_lib <- function()
  unlist(strsplit(Sys.getenv("R_LIBS_USER"), .Platform$path.sep))[1L]

#' @return Function \code{available_sys} returns a matrix with one row per
#' package. Row names are the package names, and column names include
#' \code{"Package"}, \code{"Version"}, \code{"Repository"}.
#'
#' @name manager
#' @export
available_sys <- function() {
  pkgs <- do.call(rbind, strsplit(backend_call("available"), ";"))
  colnames(pkgs) <- c("Package", "Version", "Repository")
  pkgs[, "Version"] <- gsub("_", "-", pkgs[, "Version"], fixed=TRUE) #71 Arch

  vers <- package_version(pkgs[, "Version"])
  pkgs <- pkgs[order(pkgs[, "Package"], vers, decreasing=TRUE), ]
  pkgs <- pkgs[!duplicated(pkgs[, "Package"]), ]
  pkgs <- pkgs[order(pkgs[, "Package"]), ]

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
