#! /bin/bash
# Call moveto_sys for a list of users and/or libraries (requires sudo access)

set -e

usage() {
  printf "Usage: $(basename ${0%.*}) [options] user|library ...\n"
  printf "\n"
  printf "Options:\n"
  printf " -r|--run\tMake changes, instead of a dry run\n"
  printf " -y|--yes\tAnswer yes for all questions\n"
  printf " -h|--help\tPrint this help\n"
  exit 0
}

proceed() {
  read -rp "Proceed? [y/n/c] "
  [[ ${REPLY,,} =~ ^(c|cancel)$ ]] && exit 1
  [[ ${REPLY,,} =~ ^(y|yes)$ ]]
  return
}

while [ ! -z "$1" ]; do
  case "$1" in
    --run|-r) RUN=true ;;
    --yes|-y) YES=true ;;
    --help|-h) usage ;;
    -*) echo "Error: wrong option '$1'" && exit 1 ;;
    *) [ -d "$1" ] && LIBS+=("$1") || USERS+=("$1") ;;
  esac
  shift
done

if [ ${#USERS[@]} -eq 0 ] && [ ${#LIBS[@]} -eq 0 ]; then
  echo "Error: no user or library provided, use -h for help"
  exit 1
fi

if [ "$RUN" != true ] ; then
  echo "NOTE: no changes will be made unless '--run' is specified"
fi

echo "Gaining sudo access..."
sudo true

for user in "${USERS[@]}"; do
  # check user exists
  id $user > /dev/null 2>&1 || continue
  # retrieve user library and append if exists
  lib=$(sudo -u $user Rscript -e "cat(bspm:::user_lib(), fill=TRUE)")
  [ -d "$lib" ] && LIBS+=("$lib")
done

for lib in "${LIBS[@]}"; do
  # get library owner and report
  user=$(ls -ld "$lib" | cut -d" " -f3)
  n_before=$(ls "$lib" | wc -l)
  echo "Found $n_before packages in $user's $lib"
  # proceed only if run flag was specified
  if [ "$RUN" = true ] ; then
    # ask user by default
    [ "$YES" != true ] && { proceed || continue; }
    # move, and count again
    sudo -u $user Rscript -e "bspm::moveto_sys('$lib')" > /dev/null
    n_after=$(ls "$lib" | wc -l)
    # report results
    echo "Moved $(($n_before-$n_after)) ($n_after left) from $user's $lib"
  fi
done
