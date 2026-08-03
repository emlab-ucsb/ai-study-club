# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Materials for the emLab AI study club. One self-contained folder per session,
named `<YYYYMMDD>-<topic>` so they sort chronologically, each with its own `README.md`. The code inside is
deliberately trivial and disposable — the *tool behaviour* being demonstrated is
the point. Read a session's `README.md` before touching its files; the code is
often written to match a walkthrough step by step.

This file sits at the repo root and so applies to every session folder. If a
session needs rules of its own, add a `CLAUDE.md` inside that folder.

## Sessions

- `20260722-claude-md-demo/` — a small R package (`programimpact`) pulling
  BWBS emissions totals from BigQuery and plotting them. Run with:

  ```r
  bigrquery::bq_auth()
  source("20260722-claude-md-demo/R/program_impact.R")
  save_program_impact()   # queries, plots, writes figs/program_impact.png
  ```

  Requires `bigrquery`, `ggplot2`, `patchwork`. No test suite.

- `20260805-skills-demo/` — a Reveal.js slide deck (`index.html`, CDN-loaded,
  no build step). Open the file in a browser or serve via GitHub Pages.

## Conventions

- R style: `<-` for assignment, package-qualified calls (`ggplot2::aes()`), roxygen
  comments on exported functions.
- Don't reorganize a session directory — the layout matches its README walkthrough.
- Don't add dependencies to a demo project. Small enough to read in one sitting
  is the requirement.
- Screen recordings and other large binaries go through Git LFS (`.gitattributes`
  currently tracks `*.mov` and `*.mp4`). Prefer `.mp4` for anything embedded in
  a web page — Firefox won't play the QuickTime `.mov` container at all.
