# CLAUDE.md — model-selection session

## `presentation.html` build notes

Reveal.js deck, same no-build-step CDN pattern as `20260805-skills-demo/`, but
its own visual identity — deliberately **not** matching that deck's cream/
near-black Claude palette. Jordan likes the current look; when adding slides,
carry these choices forward rather than reverting to the older style:

- **Light, glowy aesthetic** (flipped from an earlier dark version — Jordan
  asked for light background / darker text): radial gradient background
  (`--bg-top` `#fbf8ff` → `--bg-bottom` `#ffffff`), plus two blurred `.glow`
  orbs (coral `--accent` `#e2632c`, teal `--accent-2` `#1f9c82`, both
  deepened from their original dark-theme values for contrast on white) at
  low opacity fixed behind the slides. Reuse the `.glow` pattern for new
  slides rather than inventing a different decoration. There are fourteen
  of them scattered off-grid, and **they drift on every slide change**
  (`driftBlooms()` in the script block, deterministic per slide index, via
  a `transform` transition on `.glow`). Don't animate `top`/`left` or add
  continuous keyframes — slide-driven was a deliberate choice over ambient
  motion (calmer behind projected text, cheaper to render).
- **Type**: Space Grotesk for headings/byline, Inter for body text (both
  Google Fonts, loaded via the `<link>` in `<head>`).
- **Brand-name color coding**: when a model name appears as a callout word
  (like "Fable" on the title slide), color it with that model's own brand
  color rather than the deck's accent colors — e.g. Fable's app-icon blue
  `#6E93F0`. Look up the right hex per model rather than reusing one color for
  all of them.
- **Slide headings (`<h2>`, including the held-title overlay) match body
  text** — plain `--ink`, no accent color. The title slide's date still uses
  `--claude-purple` (`#7c6bc4`, Claude's brand "heather purple" darkened for
  contrast on a light background, same rationale `20260805-skills-demo`
  uses). Don't recolor headings — that was tried and reverted; purple is
  reserved for the date only.
- **No Reveal theme CSS is loaded** — only `reveal.css` (the structural
  stylesheet), not `theme/*.css`. That's intentional (lets the custom palette
  above apply cleanly), but it means `.reveal` gets no base `font-size` from
  anywhere else. It's set explicitly in this file's `<style>` block
  (currently `34px`, tuned by direct projector feedback — 52px ran too big,
  the unset default ran too small) — **don't delete that rule**. If slides
  start feeling cramped or oversized as content is added, adjust that one
  base value rather than resizing every element individually.
- This is being presented on a projector — err toward larger text and higher
  contrast over density. When adding body content (not just title slides),
  sanity-check it wouldn't look small in the back of a room before finishing.
