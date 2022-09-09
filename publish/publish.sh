#!/bin/bash
set -o errexit -o nounset -o pipefail
command -v shellcheck >/dev/null && shellcheck "$0"

function print_usage() {
  echo "Usage: $0 [-h|--help]"
  echo "Publishes crates to crates.io."
}

if [ $# = 1 ] && { [ "$1" = "-h" ] || [ "$1" = "--help" ] ; }
then
    print_usage
    exit 1
fi

# these are imported by other packages
BASE_PACKAGES="abstract-os"
UTILS_PACKAGES="abstract-sdk"
ALL_PACKAGES="abstract-api abstract-add-on"

SLEEP_TIME=30

for pack in $BASE_PACKAGES; do
  (
    cd "packages/$pack"
    echo "Publishing $pack"
    cargo publish
  )
done

# wait for these to be processed on crates.io
echo "Waiting for publishing base packages"
sleep $SLEEP_TIME

for pack in $UTILS_PACKAGES; do
  (
    cd "packages/$pack"
    echo "Publishing $pack"
    cargo publish
  )
done

# wait for these to be processed on crates.io
echo "Waiting for publishing utils packages"
sleep $SLEEP_TIME

for pack in $ALL_PACKAGES; do
  (
    cd "packages/$pack"
    echo "Publishing $pack"
    cargo publish
  )
done


# wait for these to be processed on crates.io
echo "Waiting for publishing all packages"
sleep $SLEEP_TIME

for cont in $CW20_BASE; do
  (
    cd "contracts/$cont"
    echo "Publishing $cont"
    cargo publish
  )
done

# wait for these to be processed on crates.io
echo "Waiting for publishing cw20 base"
sleep $SLEEP_TIME

# for cont in $BASE_CONTRACTS; do
#   (
#     cd "contracts/$cont"
#     echo "Publishing $cont"
#     cargo publish
#   )
# done

# # wait for these to be processed on crates.io
# echo "Waiting for publishing base contracts"
# sleep $SLEEP_TIME

# for cont in $ALL_CONTRACTS; do
#   (
#     cd "contracts/$cont"
#     echo "Publishing $cont"
#     cargo publish
#   )
# done

echo "Everything is published!"