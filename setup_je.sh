#!/bin/bash

readonly tag="5.3.0"
readonly src="https://github.com/jemalloc/jemalloc"
readonly dst="je"

extdir=extern
pushd $extdir

# clone
if test -d "$dst"; then
  echo "$extdir/$dst already exists; no need to git clone"
else
  git clone $src $dst
fi

# checkout
cd $dst
git config advice.detachedHead false  # turn off advice
git checkout $tag

# configure
if test -f config.status; then
  echo "jemalloc is already configured; no need to reconfigure"
else
  ./autogen.sh --enable-doc=no --enable-static=no --disable-stats
fi

make -j `nproc`

rm -rf ./src/*.o  # jemalloc has like ~100MiB of object files
rm -rf ./lib/*.a  # jemalloc produces 80MiB of static files

popd
