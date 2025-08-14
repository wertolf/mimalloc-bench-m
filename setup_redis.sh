#!/bin/bash

################################################################################
# Yuquan: This script is mostly pasted from ./build-bench-env.sh
# with added proxy support.
################################################################################

set -x

readonly proxy="http://172.19.208.1:10811"

curdir=`pwd`

mkdir -p extern
readonly devdir="$curdir/extern"

readonly version_redis=6.2.7

pushd "$devdir"

if test -d "redis-$version_redis"; then
  echo "$devdir/redis-$version_redis already exists; no need to download it"
else
  # Yuquan: Use curl(1) instead of wget(1).
  curl -LO -x $proxy "https://download.redis.io/releases/redis-$version_redis.tar.gz"
  tar xzf "redis-$version_redis.tar.gz"
  rm "./redis-$version_redis.tar.gz"
fi

cd "redis-$version_redis/src"
USE_JEMALLOC=no MALLOC=libc BUILD_TLS=no make -j $procs

popd

set +x
