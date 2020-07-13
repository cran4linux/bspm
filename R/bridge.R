utils::globalVariables(c("BUS_NAME", "OPATH", "IFACE"))

backend_call <- function(method, pkgs=NULL) {
  if (root())
    return(invisible(root_call(method, pkgs)))

  if (dbus_service_alive())
    return(invisible(dbus_call(method, pkgs)))

  if (interactive() || getOption("bspm.sudo", FALSE))
    return(invisible(sudo_call(method, pkgs)))

  stop("cannot connect to the system package manager", call.=FALSE)
}

root <- function() {
  Sys.info()["effective_user"] == "root"
}

root_call <- function(method, pkgs=NULL, sudo=NULL) {
  tmp <- tempfile()
  file.create(tmp)
  on.exit(unlink(tmp))

  cmd <- system.file("service/bspm.py", package="bspm")
  args <- c("root", method)
  if (!is.null(pkgs))
    args <- c(args, "-o", tmp, pkgs)
  if (!is.null(sudo)) {
    args <- c(cmd, args)
    cmd <- sudo
  }
  out <- suppressWarnings(system2(cmd, args, stderr=FALSE))

  if (out != 0)
    stop("cannot connect to the system package manager", call.=FALSE)
  readLines(tmp)
}

dbus_service_alive <- function() {
  source(system.file("service/dbus-paths", package="bspm"), local=TRUE)

  cmd <- Sys.which("busctl")
  args <- c("list", "--no-pager")
  out <- try(system2(cmd, args, stdout=TRUE, stderr=TRUE), silent=TRUE)

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
  out <- suppressWarnings(system2(cmd, args, stdout=TRUE, stderr=TRUE))

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
