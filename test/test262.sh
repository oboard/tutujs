#!/bin/bash
# 提取最后一行的前两个数字
dir=$(cd "$(dirname "$0")" && pwd)
project_root=$(cd "$dir/.." && pwd)
tmpdir=$(mktemp -d 2>/dev/null || mktemp -d -t test262)
timeout="${TEST_TIMEOUT:-5}"
max_jobs=${MAX_JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)}
# 确保 max_jobs 是合法的正整数，避免空值或垃圾值导致判断失败
if ! [[ "$max_jobs" =~ ^[0-9]+$ ]]; then
  max_jobs=4
fi
if [ "$max_jobs" -lt 1 ]; then
  max_jobs=1
fi

run_single_test() {
  local base="$1"
  local log="$2"
  (
    cd "$project_root" || exit 1
    moon test --package oboard/tutujs/test --target js -f "$base"
  ) >"$log" 2>&1 &
  local test_pid=$!
  (
    sleep "$timeout"
    if kill -0 "$test_pid" 2>/dev/null; then
      echo "Timeout after ${timeout}s, killing test $base" >>"$log"
      kill -TERM "$test_pid" 2>/dev/null
    fi
  ) &
  local killer_pid=$!
  wait "$test_pid"
  local status=$?
  kill -TERM "$killer_pid" 2>/dev/null || true
  wait "$killer_pid" 2>/dev/null || true
  line=$(grep 'Total tests:' "$log" | tail -n 1 || true)
  if [ -n "$line" ]; then
    echo "[$base] $line"
  else
    if [ "$status" -eq 0 ]; then
      echo "[$base] finished (no Total tests line)"
    else
      echo "[$base] failed with status $status"
    fi
  fi
  return "$status"
}

files=()
for f in "$dir"/test262_*.mbt; do
  if [ -f "$f" ]; then
    files+=("$f")
  fi
done

if [ "${#files[@]}" -eq 0 ]; then
  echo "No test262_*.mbt files found in $dir"
  exit 1
fi

for ((w = 0; w < max_jobs; w++)); do
  (
    idx=$w
    while [ "$idx" -lt "${#files[@]}" ]; do
      base=$(basename "${files[$idx]}")
      log="$tmpdir/$base.log"
      run_single_test "$base" "$log"
      idx=$((idx + max_jobs))
    done
  ) &
done

wait

total=0
passed=0
failed=0

for log in "$tmpdir"/*.log; do
  if [ ! -f "$log" ]; then
    continue
  fi
  line=$(grep 'Total tests:' "$log" | tail -n 1 || true)
  if [ -z "$line" ]; then
    continue
  fi
  nums=($(echo "$line" | grep -o -E '[0-9]+'))
  if [ "${#nums[@]}" -ge 3 ]; then
    total=$((total + nums[0]))
    passed=$((passed + nums[1]))
    failed=$((failed + nums[2]))
  fi
done

echo "$total $passed $failed"
python "$dir/generate_progress_svg.py" "$total" "$passed" "$dir/test262_progress.svg"
