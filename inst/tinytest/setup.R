mock <- function(fun, new, pkg, envir=getOption("mock")) {
  stopifnot(is.function(new))
  ns <- asNamespace(pkg)
  assign(paste(pkg, fun), get(fun, ns), envir)
  unlockBinding(fun, ns)
  assign(fun, new, ns)
  lockBinding(fun, ns)
}

unmock <- function(fun, pkg, envir=getOption("mock")) {
  stopifnot(is.function(old <- get0(paste(pkg, fun), envir)))
  ns <- asNamespace(pkg)
  unlockBinding(fun, ns)
  assign(fun, old, ns)
  lockBinding(fun, ns)
  rm(list=paste(pkg, fun), envir=envir)
}

unmock_all <- function(envir=getOption("mock")) {
  for (name in strsplit(ls(envir), " "))
    unmock(name[2], name[1], envir=envir)
}

options(mock=new.env(parent=emptyenv()))
reg.finalizer(getOption("mock"), unmock_all)
