utils::globalVariables(c("BUS_NAME", "OPATH", "IFACE"))

dbus_call <- function(cmd, pkgs) {
  source(system.file("service/dbus-paths", package="bspm"))

  args <- c("list", "--no-pager")
  out <- suppressWarnings(system2("busctl", args, stdout=TRUE, stderr=TRUE))
  if (!any(grepl(BUS_NAME, out)))
    stop("bspm service not found")

  args <- c("call", "--timeout=1h", BUS_NAME, OPATH, IFACE,
            cmd, "ias", Sys.getpid(), length(pkgs), pkgs)
  out <- suppressWarnings(system2("busctl", args, stdout=TRUE, stderr=TRUE))

  if (!length(out))
    return(out)
  status <- attr(out, "status")
  if (!is.null(status) && status != 0)
    stop(out)
  cat("\n")

  out <- gsub('"', "", out)
  out <- strsplit(out, " ")[[1]][-(1:2)]
  invisible(out)
}

backend_call <- function(cmd, pkgs) {
  if (Sys.info()["effective_user"] != "root")
    return(dbus_call(cmd, pkgs))

  tmp <- tempfile()
  on.exit(unlink(tmp))

  mgr <- system.file("service/bspm.py", package="bspm")
  args <- c(if (cmd == "remove") "-r", "-o", tmp, "-u", pkgs)
  system2(mgr, args, stderr=FALSE)

  invisible(readLines(tmp))
}

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
