# Leaving Claude on the cluster

Session for 2026-10-14.

A short Reveal.js deck ([presentation.html](presentation.html), CDN-loaded, no
build step) on running long analyses with an unattended Claude Code session on
the GRIT cluster. It draws on the DISPLACE calibration run of October 2026.

The deck covers:

1. **SLURM**: what the scheduler does, general good practice, and the limits
   the agent was given (job caps, a 32 → 64 → 96 GB memory ladder, deadline).
2. **Restartability**: what each stage saves to disk, so a failure restarts
   from the last good point instead of from scratch.
3. **Supervision**: step by step, running Claude in `tmux` on the server with
   `/loop` so it keeps going after the laptop is closed; what it does at each
   wake-up; what happens at a usage limit.
4. **Guardrails**: the layers with examples, the real DISPLACE permission
   rules for reading, writing and running commands, and testing the hook.
5. **Data on Nextcloud**: on the server the Nextcloud folders are the storage,
   so reads and writes are direct, with no syncing.
6. **Takeaways**: advantages, safety concerns and how they were handled, and
   what Claude managed on its own versus what still needed a person.
7. **Next**: whether to turn all of this into a Claude skill.

The source material, with templates (`job.sbatch`, `watch_job.sh`,
`branch-guard.sh`, `settings.local.json`, ...), is
[agent_hpc_playbook/](agent_hpc_playbook/) in this folder (moved from the
`calib_autopilot` branch of DISPLACE-westcoast-analysis on 2026-10-27).
