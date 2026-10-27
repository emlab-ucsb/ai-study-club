#!/usr/bin/env bash
# Template SLURM job: one run of <task> for <id>, in resumable steps.
#   sbatch --job-name=<task>_<id> --partition=<partition> --cpus-per-task=<N> \
#     --mem=<X>G --time=<HH:MM:SS> --output=logs/%x_%j.out templates/job.sbatch <id>
# Workers = --cpus-per-task (one core per independent replicate).
#SBATCH --partition=<partition>
set -u
id=$1
workers=${SLURM_CPUS_PER_TASK:-1}
cd "${SLURM_SUBMIT_DIR:-$(pwd)}" || exit 1

# Environment: always set it here, never rely on the login shell
. "$HOME/opt/R/<version>/env.sh"          # user-space toolchain
export DATA_DIR=${DATA_DIR:?set DATA_DIR before sbatch}

logs=logs/$id
mkdir -p "$logs"
status=$logs/status.txt
note() { echo "$(date '+%F %T') $*" | tee -a "$status"; }
step() { # step <name> <command...>: skip if done before, stop on failure
  local name=$1; shift
  if [[ -f $logs/$name.done ]]; then note "$name already done, skipped"; return; fi
  note "$name start"
  "$@" > "$logs/$name.log" 2>&1 || { note "FAILED in $name (see $logs/$name.log)"; exit 1; }
  touch "$logs/$name.done"; note "$name done"
}

note "start $id ($workers workers)"
step build   Rscript scripts/build.R "$id"
step run     Rscript scripts/run_replicates.R "$id" "$workers"   # parallel workers inside
step check   Rscript scripts/check_complete.R "$id"              # from outputs, not exit codes
step report  Rscript scripts/report.R "$id"                      # cache slow inputs inside
note "DONE $id"
