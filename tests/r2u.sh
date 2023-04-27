#! /bin/bash

set -e
eval $(cat /etc/os-release)
RVER=$(Rscript -e 'cat(as.character(getRversion()))')

# Tests for fast path
echo "options(bspm.version.check=FALSE)" >> /etc/R/Rprofile.site

echo "TEST: install GitHub package"
installGithub.r MangoTheCat/visualTest

echo "TEST: install Bioc package"
install.r BiocParallel

echo "TEST: install binary deps + binary from r-universe"
REPO_URL="https://eddelbuettel.r-universe.dev/bin/linux/$VERSION_CODENAME/${RVER%.*}"
install2.r -r $REPO_URL RcppKalman

# Tests for default path
echo "options(bspm.version.check=TRUE)" >> /etc/R/Rprofile.site
echo "options(install.packages.compile.from.source='never')" >> /etc/R/Rprofile.site

echo "TEST: install suggested packages overlapping the requested ones"
install2.r -d TRUE units dplyr
