.onLoad <- function(libname, pkgname) {
  if (getOption("bspm.sudo.autodetect", FALSE))
    sudo_autodetect()
}

sudo_autodetect <- function() {
  nopass <- !system2nowarn("sudo", c("-n", "true"), stdout=FALSE, stderr=FALSE)
  toolbox <- file.exists("/run/.toolboxenv") # see #27

  if (nopass || toolbox) {
    packageStartupMessage("bspm: passwordless sudo detected and enabled")
    options(bspm.sudo=TRUE)
  }
}
