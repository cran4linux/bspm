#! /bin/bash

set -e
echo "options(bspm.version.check=FALSE)" >> /etc/R/Rprofile.site

echo "TEST: install GitHub package"
installGithub.r MangoTheCat/visualTest

echo "TEST: install Bioc package"
install.r BiocParallel

echo "TEST: install binary deps + binary from r-universe"
install2.r -r "https://eddelbuettel.r-universe.dev/bin/linux/jammy/4.2" tiledbsoma
