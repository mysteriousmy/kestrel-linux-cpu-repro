#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
  echo "Usage: $0 <server-pid> [url]" >&2
  exit 2
fi

server_pid="$1"
target_url="${2:-http://localhost:5000/}"

for required_command in wrk pidstat mpstat; do
  if ! command -v "$required_command" >/dev/null 2>&1; then
    echo "Missing required command: $required_command" >&2
    exit 1
  fi
done

if ! kill -0 "$server_pid" 2>/dev/null; then
  echo "Server PID $server_pid is not running" >&2
  exit 1
fi

hard_nofile_limit="$(ulimit -Hn)"
ulimit -Sn "$hard_nofile_limit"

timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
result_dir="results/current-$timestamp"
mkdir -p "$result_dir"

echo "Warming up $target_url for 20 seconds"
wrk -t24 -c1024 -d20s "$target_url" >"$result_dir/warmup.txt"

echo "Measuring $target_url for 30 seconds"
wrk --latency -t24 -c1024 -d30s "$target_url" >"$result_dir/wrk.txt" &
client_pid="$!"

pidstat -u -p "$server_pid,$client_pid" 1 30 >"$result_dir/pidstat.txt" &
pidstat_pid="$!"
mpstat 1 30 >"$result_dir/mpstat.txt" &
mpstat_pid="$!"

wait "$client_pid"
wait "$pidstat_pid"
wait "$mpstat_pid"

cat "$result_dir/wrk.txt"
awk '/^Average:/ {print}' "$result_dir/pidstat.txt"
awk '/^Average:.* all / {print}' "$result_dir/mpstat.txt"
echo "Raw results: $result_dir"
