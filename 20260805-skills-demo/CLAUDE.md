# CLAUDE.md — skills-demo session

## Workflow: README drives the slides

`README.md` in this folder is the source of truth for slide content. The user
writes/edits slide descriptions there under `## Slide N` headings; Claude's job
is to apply those changes to the Reveal.js deck in `index.html`. The HTML is
the build artifact — don't author slide content directly in it unless asked.

When asked to "make the updates" or similar:

1. Read `README.md`, compare each `## Slide N` entry against the deck.
2. Apply the differences to `index.html`.
3. If an entry is ambiguous or incomplete (e.g. text that was promised but not
   pasted in), apply everything else and flag the gap — don't invent content.

## Deck specifics

- Reveal.js 5 from the jsDelivr CDN — no build step, but slides need internet.
- **The deck is strictly left/right.** Every slide is a top-level `<section>`;
  never nest `<section>`s to make Reveal's vertical (up/down) stacks. If a
  README entry has sub-headings under a slide, flatten them into consecutive
  horizontal slides. Fragments (appear-on-click) are fine — they advance with
  the right arrow.
- Slides live in a 960x700 coordinate system that Reveal scales to the screen.
- The connectors video is sized with explicit pixel dimensions, NOT `r-stretch`:
  r-stretch computes the box from video metadata, which never loads under
  `preload="none"`, collapsing the element to a blank slide.
- The video is stored in Git LFS and served from `media.githubusercontent.com`
  (GitHub Pages doesn't serve LFS content). Keep `preload="none"` and the
  poster — LFS bandwidth is metered against the org quota, and this only works
  while the repo is public.
- Always boldface "Skills" and "Connectors", and color the text (no background
  highlights): Skills in the Claude logo coral `#D97757`, Connectors in mint
  `#3B9C7F`. Use the `.term-skills` / `.term-connectors` spans.