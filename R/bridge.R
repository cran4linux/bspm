#' \pkg{bspm}: Bridge to System Package Manager
#'
#' Enables binary package installations on Linux distributions.
#' Provides functions to manage packages via the distribution's package
#' manager. Also provides transparent integration with R's \code{install.packages}
#' and a fallback mechanism. When installed as a system package, interacts
#' with the system's package manager without requiring administrative
#' privileges via an integrated D-Bus service; otherwise, uses sudo.
#' Currently, the following backends are supported: DNF, APT.
#'
#' @author Iñaki Ucar
#'
#' @references \url{https://github.com/Enchufa2/bspm}
#'
#' @docType package
#' @name bspm-package
#'
#' @seealso \code{\link{manager}}, \code{\link{integration}}
NULL

utils::globalVariables(c("BUS_NAME", "OPATH", "IFACE"))

system2nowarn <- function(...) suppressWarnings(system2(...))

backend_call <- function(method, pkgs=NULL) {
  if (root())
    return(invisible(root_call(method, pkgs)))

  if (getOption("bspm.sudo", FALSE))
    return(invisible(sudo_call(method, pkgs)))

  if (dbus_service_alive())
    return(invisible(dbus_call(method, pkgs)))

  if (interactive())
    return(invisible(sudo_call(method, pkgs)))

  stop("cannot connect to the system package manager", call.=FALSE)
}

root <- function() {
  Sys.info()["effective_user"] == "root"
}

root_call <- function(method, pkgs=NULL, sudo=NULL) {
  tmp <- tmp2 <- tempfile()
  # workaround, see #13
  if (length(strsplit(tmp2, "/")[[1]]) == 3) {
    dir.create(tmp)
    tmp <- paste0(tmp, tempfile(tmpdir=""))
  }
  file.create(tmp)
  on.exit(unlink(tmp2, recursive=TRUE, force=TRUE))

  cmd <- system.file("service/bspm.py", package="bspm")
  args <- method
  if (!is.null(pkgs))
    args <- c(args, "-o", tmp, pkgs)
  if (!is.null(sudo)) {
    args <- c(cmd, args)
    cmd <- sudo
  }
  out <- system2nowarn(cmd, args, stderr=FALSE)

  if (out != 0)
    stop("cannot connect to the system package manager", call.=FALSE)
  readLines(tmp)
}

dbus_service_alive <- function() {
  source(system.file("service/dbus-paths", package="bspm"), local=TRUE)

  cmd <- Sys.which("busctl")
  args <- c("list", "--no-pager")
  out <- try(system2nowarn(cmd, args, stdout=TRUE, stderr=TRUE), silent=TRUE)

  if (inherits(out, "try-error") || !any(grepl(BUS_NAME, out)))
    return(FALSE)
  return(TRUE)
}

dbus_call <- function(method, pkgs=NULL) {
  source(system.file("service/dbus-paths", package="bspm"), local=TRUE)

  cmd <- Sys.which("busctl")
  args <- c("call", "--timeout=1h", BUS_NAME, OPATH, IFACE, method)
  if (!is.null(pkgs))
    args <- c(args, "ias", Sys.getpid(), length(pkgs), pkgs)
  out <- system2nowarn(cmd, args, stdout=TRUE, stderr=TRUE)

  if (!length(out))
    return(out)
  status <- attr(out, "status")
  if (!is.null(status) && status != 0)
    stop("dbus: ", out, call.=FALSE)
  cat("\n")

  out <- gsub('"', "", out)
  out <- strsplit(out, " ")[[1]][-(1:2)]
  out
}

sudo_call <- function(method, pkgs=NULL) {
  if (!isatty(stdin()))
    cmd <- "pkexec"
  else cmd <- "sudo"

  sudo <- Sys.which(cmd)
  if (!nchar(sudo))
    stop(cmd, " command not found", call.=FALSE)

  root_call(method, pkgs, sudo=sudo)
}
