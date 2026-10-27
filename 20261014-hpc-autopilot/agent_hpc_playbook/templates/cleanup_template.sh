#!/usr/bin/env bash
# Deletion with a dry run by default, a protected list and a log.
#   bash cleanup_template.sh            # dry run: lists what would go, with sizes
#   bash cleanup_template.sh --delete   # deletes; keep the output as the log
# Never list the results folder; protected items make the script refuse.
set -u
ROOT=/shared/project/data
DELETE="v1.1 v1.2 v2.0"                 # items to remove
PROTECT="v1.0 v3.0 final"               # never removed (repo references, recommended runs)
mode=${1:-}
total=0
for v in $DELETE; do
  for k in $PROTECT; do [[ $v == "$k" ]] && { echo "refusing: $v is protected"; exit 1; }; done
  for p in "$ROOT/inputs/$v" "$ROOT/outputs/$v"; do      # never "$ROOT/results/..."
    [[ -d $p ]] || continue
    kb=$(du -sk "$p" | cut -f1); total=$((total + kb))
    if [[ $mode == --delete ]]; then rm -r -- "$p" && echo "deleted $p ($((kb / 1024)) MB)"
    else echo "would delete $p ($((kb / 1024)) MB)"; fi
  done
done
echo "total: $((total / 1024 / 1024)) GB"
