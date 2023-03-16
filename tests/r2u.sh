#! /bin/bash

set -e
echo "options(bspm.version.check=FALSE)" >> /etc/R/Rprofile.site
eval $(cat /etc/os-release)
RVER=$(Rscript -e 'cat(R.version$major, R.version$minor, sep=".")')

echo "TEST: install GitHub package"
installGithub.r MangoTheCat/visualTest

echo "TEST: install Bioc package"
install.r BiocParallel

echo "TEST: install binary deps + binary from r-universe"
REPO_URL="https://eddelbuettel.r-universe.dev/bin/linux/$VERSION_CODENAME/${RVER%.*}"
install2.r -r $REPO_URL RcppKalman
