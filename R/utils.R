#' Find Shadowed Packages
#'
#' Find packages that are \emph{shadowed} by others in library locations
#' with a higher priority.
#'
#' @param lib.loc character vector describing the location of the \R library
#' trees to search through, or \code{NULL} for all known trees
#' (see \code{\link{.libPaths}}).
#' @return A \code{data.frame} with one row per package, row names the package
#' names and column names (currently) "Package", "LibPath", "Version",
#' "Shadow.LibPath", "Shadow.Version", "Shadow.Newer".
#'
#' @details \R supports setting several locations for library trees. This is a
#' powerful feature, but many times packages end up installed in multiple
#' locations, and in such cases \R silently uses the one in the path with the
#' highest priority (appearing first in \code{\link{.libPaths}}), thus
#' \emph{shadowing} packages in locations with a lower priority.
#'
#' For \pkg{bspm} installations, this means that outdated user packages may
#' break system libraries. This utility reports packages that are shadowed
#' (one per row) with information on which location ("Shadow.LibPath")
#' and version ("Shadow.Version") has priority over it.
#' The \code{\link{moveto_sys}} method is a great complement to move such
#' outdated versions to the system libraries.
#'
#' @seealso \code{\link{moveto_sys}}
#' @export
shadowed_packages <- function(lib.loc=NULL) {
  if (is.null(lib.loc)) lib.loc <- .libPaths()

  fields <- c("Package", "LibPath", "Version")
  sfields <- paste("Shadow", fields, sep=".")
  shadow <- data.frame(matrix(nrow=0, ncol=5))
  colnames(shadow) <- c(fields, sfields[-1])

  pkgs <- data.frame(utils::installed.packages(lib.loc)[, fields])
  pkgs <- split(pkgs, factor(pkgs$LibPath, levels=lib.loc))

  idx <- seq_along(pkgs)
  for (i in idx) {
    colnames(pkgs[[i]]) <- sfields
    for (j in idx[-seq_len(i)]) {
      hidden <- merge(pkgs[[j]], pkgs[[i]], by.x=fields[1], by.y=sfields[1])
      shadow <- rbind(shadow, hidden)
    }
  }

  row.names(shadow) <- shadow[, "Package"]
  shadow$Version <- as.package_version(shadow$Version)
  shadow$Shadow.Version <- as.package_version(shadow$Shadow.Version)
  newer <- shadow[, "Version"] < shadow[, "Shadow.Version"]
  shadow <- cbind(shadow, Shadow.Newer = newer)
  shadow
}

installed_packages <- function(...) {
  libs <- unique(c(.Library.site, .Library))
  inst <- row.names(utils::installed.packages(libs, ...))
  inst
}

# get package dependencies
pkg_deps <- function(pkgs, dependencies, db, ..., all=TRUE) {
  pkgs <- unique(pkgs)
  inst <- installed_packages(...)
  deps <- tools::package_dependencies(pkgs, db, c("Depends", "Imports"), recursive=TRUE)
  deps <- unlist(deps, use.names=FALSE)
  if (!all) {
    hard <- tools::package_dependencies(pkgs, db, "LinkingTo", recursive=FALSE)
    deps <- c(deps, unlist(hard, use.names=FALSE))
  }
  if (isTRUE(dependencies) || "Suggests" %in% dependencies) {
    soft <- tools::package_dependencies(pkgs, db, "Suggests", recursive=FALSE)
    deps <- c(deps, unlist(soft, use.names=FALSE))
  }
  if ("Enhances" %in% dependencies) {
    enha <- tools::package_dependencies(pkgs, db, "Enhances", recursive=FALSE)
    deps <- c(deps, unlist(enha, use.names=FALSE))
  }
  deps <- unique(c(setdiff(deps, inst), if (all) pkgs))
  deps
}

# get LinkingTo-only dependencies for src packages
hard_deps <- function(pkgs, db, ..., mask) {
  inst <- installed_packages(...)
  srcs <- c(pkgs$bins[mask], pkgs$srcs)
  deps <- tools::package_dependencies(srcs, db, "LinkingTo", recursive=FALSE)
  deps <- setdiff(unlist(deps, use.names=FALSE), c(inst, pkgs$bins, pkgs$srcs))
  deps
}

# adapted from install.packages
# get available binaries and pkgs with later versions available
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
# determine whether later versions should be preferred
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
    cat("  Binaries will be preferred\n")
    later <- FALSE
  }

  later
}
