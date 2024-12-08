#!/bin/bash

# phase "patch shbench" skipped

# phase "get large PDF document" skipped

# phase "get lua" skipped

cmake -B out/bench -S bench
cmake --build out/bench --parallel `nproc`
