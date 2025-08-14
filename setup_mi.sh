#!/bin/bash

################################################################################
# Yuquan: This script is mostly pasted from ./build-bench-env.sh
# with added proxy support.
################################################################################

set -x

# NOTE: Change this as needed.
proxy="http://172.19.208.1:10811"

readonly version_mi=v1.8.2

curdir=`pwd`
mkdir -p extern
readonly devdir="$curdir/extern"

function write_version {  # name, git-tag, repo
  commit=$(git log -n1 --format=format:"%h")
  echo "$1: $2, $commit, $3" > "$devdir/version_$1.txt"
}

function checkout {  # name, git-tag, git repo, options
  pushd $devdir

  if test "$rebuild" = "1"; then
    rm -rf "$1"
  fi

  if test -d "$1"; then
    echo "$devdir/$1 already exists; no need to git clone"
  else
    # Yuquan: Add proxy.
    /usr/bin/env HTTPS_PROXY=$proxy git clone $4 $3 $1
  fi

  cd "$1"
  git checkout $2
  write_version $1 $2 $3
}

checkout mi $version_mi https://github.com/microsoft/mimalloc

echo ""
echo "- build mimalloc release"

cmake -B out/release
cmake --build out/release --parallel $procs

echo ""
echo "- build mimalloc debug with full checking"

cmake -B out/debug -DMI_CHECK_FULL=ON
cmake --build out/debug --parallel $procs

echo ""
echo "- build mimalloc secure"

cmake -B out/secure -DMI_SECURE=ON
cmake --build out/secure --parallel $procs

popd

set +x