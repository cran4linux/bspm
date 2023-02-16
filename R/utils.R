pkg_deps <- function(pkgs, db, ..., all=TRUE) {
  inst <- row.names(utils::installed.packages(.Library.site, ...))
  pkgs <- tools::package_dependencies(pkgs, db, recursive=TRUE)
  pkgs <- lapply(pkgs, function(x) setdiff(x, inst))
  pkgs <- unique(c(if (all) names(pkgs), unlist(pkgs, use.names=FALSE)))
  pkgs
}

# adapted from install.packages
check_versions <- function(pkgs, db) {
  dbb <- available_sys()
  row.names(dbb) <- tolower(row.names(dbb))

  bins <- pkgs[tolower(pkgs) %in% row.names(dbb)]
  srcs <- pkgs[! pkgs %in% bins]

  binvers <- dbb[tolower(bins), "Version"]
  srcvers <- sapply(bins, function(bin) # may not be in db
    if (bin %in% row.names(db)) db[bin, "Version"] else "0")

  later <- as.numeric_version(binvers) < srcvers

  list(bins=bins, srcs=srcs, binvers=binvers, srcvers=srcvers, later=later)
}

# consider as "later" packages with the same version installed from remotes
remotes_as_newer <- function(pkgs, lib) {
  for (i in which(as.numeric_version(pkgs$binvers) == pkgs$srcvers))
    if (!is.na(utils::packageDescription(pkgs$bins[i], lib, "RemoteSha")))
      pkgs$later[i] <- TRUE
  pkgs
}

# adapted from install.packages
ask_user <- function(later, bins, binvers, srcvers) {
  if (!any(later)) return(later)

  msg <- ngettext(
    sum(later),
    "There is a binary version available but the source version is later",
    "There are binary versions available but the source versions are later")
  cat("\n", paste(strwrap(msg, indent = 2, exdent = 2), collapse = "\n"),
      ":\n", sep = "")
  print(data.frame(`binary` = binvers, `source` = srcvers,
                   row.names = bins, check.names = FALSE)[later, ])
  cat("\n")
  action <- getOption("install.packages.compile.from.source", "interactive")
  if (action == "interactive" && interactive()) {
    msg <- gettext("Do you prefer later versions from sources?")
    res <- utils::askYesNo(msg)
    if (is.na(res)) stop("Cancelled by user")
    if (!isTRUE(res)) later <- FALSE
  } else if (action == "never") {
    cat("  Binaries will be installed\n")
    later <- FALSE
  }

  later
}
