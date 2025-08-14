#!/bin/bash

################################################################################
# Yuquan: This script is refactored from ./bench.sh
################################################################################

set -x

readonly curdir=`pwd`
if ! test -f ../../build-bench-env.sh; then
  echo "error: you must run this script from the 'out/bench' directory!"
  exit 1
fi

# 检测 redis-server 进程是否存在
# 使用 ps aux 列出所有进程，通过 grep 过滤包含 redis-server 的行
# wc -l 统计匹配到的行数（若大于 0 则表示进程存在）
redis_process_count=$(ps aux | grep "redis-server" | wc -l)

# 判断进程数量
if [ $redis_process_count -gt 0 ]; then
    echo "Another redis-server process is running. Turn it off first."
    exit
fi

pushd "../../extern" > /dev/null # up from `mimalloc-bench/out/bench`
readonly localdevdir=`pwd`
popd > /dev/null

readonly version_redis=6.2.7

readonly redis_dir="$localdevdir/redis-$version_redis/src"

test_name="redis"
allocator="mi"
alloc_lib="$localdevdir/mi/out/release/libmimalloc.so"
environment="LD_PRELOAD=$alloc_lib"
if [ "$allocator" = "sys" ]; then
  environment="SYSMALLOC=1"
fi
if [ "$allocator" = "mi-dbg" ]; then
  environment="$environment MIMALLOC_VERBOSE=1 MIMALLOC_STATS=1"
fi
command="$redis_dir/redis-benchmark"
command="$command -r 1000000"
command="$command -n 100000"
command="$command -q"
command="$command -P 16"
command="$command lpush a 1 2 3 4 5"
command="$command lrange a 1 5"
  # https://redis.io/docs/reference/optimization/benchmarks/

# Yuquan: These are just some whitespaces used for prettier output.
readonly allocfill="     "
readonly benchfill="           "

format_string="%E %M %U %S %F %R"
  # E - elapsed real (wall clock) time
  # M - maximum RSS in kilobytes
  # U - total number of CPU-seconds (in user mode)
  # S - total number of CPU-seconds (in kernel mode)
  # F - number of major page faults
  # R - number of minor page faults
  # For more info, see time(1).
format_string="$allocator${allocfill:${#allocator}} $format_string"
format_string="$test_name${benchfill:${#test_name}} $format_string"

timecmd="$(type -P time)"  # the shell builtin doesn't have all the options we need

outfile="$test_name-$allocator-out.txt"

readonly benchres="$curdir/benchres.csv"

# clear temporary output
if [ -f "$benchres.line" ]; then
  rm "$benchres.line"
fi

echo "start server"
$timecmd -a -o "$benchres.line" -f "$format_string" \
  /usr/bin/env $environment $redis_dir/redis-server \
  > "$outfile.server.txt" &
sleep 1s
$redis_dir/redis-cli flushall
sleep 1s
$command >> "$outfile"
sleep 1s
$redis_dir/redis-cli flushall
sleep 1s
$redis_dir/redis-cli shutdown
sleep 1s

cat "$benchres.line"

# Yuquan: I have not understood the following code block yet.
# redis_tail="1"
# ops=`tail -$redis_tail "$outfile" | sed -n 's/.*: \([0-9\.]*\) requests per second.*/\1/p'`
# rtime=`echo "scale=3; (2000000 / $ops)" | bc`
# echo "$1 $2: ops/sec: $ops, relative time: ${rtime}s"
# sed -E -i.bak "s/($1  *$2  *)[^ ]*/\10:$rtime/" "$benchres.line"

# test -f "$benchres.line" && cat "$benchres.line" | tee -a $benchres

set +x
