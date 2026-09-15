# Environment notes

This session runs inside a macOS `sandbox-exec` profile. The restrictions below
are deliberate and are not faults to diagnose or work around.

- Your working directory is the only location you can write to. Writes anywhere
  else fail with `Operation not permitted`.
- Git is unavailable. Git commands report `not a git repository`; that is the
  sandbox, not a broken checkout. Do not try to locate, restore, or reconstruct
  repository state.
- Sibling directories one level up are visible by name but cannot be read or
  listed. Leave them alone.
- Read access elsewhere on the filesystem is normal, as is network access.

Work within your own directory and do not spend turns investigating the
environment itself.
