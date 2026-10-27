#!/usr/bin/env bash
# Wait until a job reaches a terminal state, then print the outcome once.
# Run in the background (one notification when it exits):
#   templates/watch_job.sh <jobid> logs/<id>/status.txt
# Terminal states covered: DONE / FAILED lines in the status file AND the job
# leaving the queue without either (crash, OOM kill, timeout).
set -u
job=$1
status=$2
# only the lines of the latest attempt (status files are append-only)
latest() { awk '/ start /{buf=""} {buf=buf $0 "\n"} END{printf "%s", buf}' "$status" 2>/dev/null; }
while true; do
  if latest | grep -qE "DONE|FAILED"; then break; fi
  if ! squeue -j "$job" -h 2>/dev/null | grep -q .; then
    echo "job $job left the queue without DONE/FAILED:"
    sacct -j "$job" --format=JobID,State,ExitCode,Elapsed,MaxRSS -P | tail -3
    break
  fi
  sleep 30
done
latest | tail -5
