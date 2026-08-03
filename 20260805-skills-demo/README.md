# Skills demo

Session for 2026-08-05.

`index.html` is a [Reveal.js](https://revealjs.com/) slide deck (loaded from
CDN, no build step).

**[View the slides](https://emlab-ucsb.github.io/ai-study-club/20260805-skills-demo/)**
— published via GitHub Pages from `main`.

Or open it locally with:

```bash
open 20260805-skills-demo/index.html
```

The five videos are served from the `media.githubusercontent.com` LFS endpoint
rather than by relative path, because GitHub Pages doesn't serve LFS content.
That only works while the repo is public and the `.mp4` files are on `main`,
so the deck's videos stay blank on a feature branch until it's merged.
`preload="none"` keeps the metered LFS bandwidth to actual plays.

Each video also has a `poster` — a first-frame JPEG in `assets/`, extracted
with AVFoundation. Without one, `preload="none"` leaves a blank gray box until
the viewer hits play. The posters aren't LFS-tracked, so they serve from Pages
by relative path.

# Slide descriptions (CLAUDE.md refers Claude here to build the .html)

NOTE: '___' means have the text below 'appear' rather than switching to a new '##' slide

## Adapting Claude to your workflow with Skills (title slide)

**Adapting Claude to your workflow with Skills** 

Jordan Wingenroth [somewhat smaller font]

08/05/2026 [smaller font]

## What is a skill?

What is a skill? [normal color]
___

It's something you are good at.

[Insert William Defoe "I'm something of a scientist myself" meme (put in `assets/`)]

# What is a Skill?

What is a Skill? [Skill in orange color]
___

It's when Claude loads a special folder of tools and info that are geared towards a specific task or subject, within a chat or Cowork session.

[Insert kung fu JPG I put in `assets/`]

## Picking up where we left off with CLAUDE.md

Claude Skills are sort of like a CLAUDE.md file, but designed for use outside of codebases.

Add a table comparing CLAUDE.md (left) and Skills. Use formatting described in this folder's CLAUDE.md. Can you have the rows of the table appear one by one on click?

| CLAUDE.md | Skills |
| --- | --- |
| Added to Claude Code context automatically on load | Skill title and summary always available to Claude Chat and Cowork |
| Lives in the repo, scoped to that codebase | Lives in your account, not accessed by Claude Code |
| A single markdown file that references other files in the repo | A folder: `SKILL.md` plus any scripts or reference files |
| Can be shared between teammates on a GitHub repo | Can be shared with individuals or the whole emLab team on the Claude app |

## First steps

Skills are located under the Customize menu. Claude comes with a library out of the box, but they are pretty generic. 

[assets/skills_setup.mp4] (match formatting currently in the HTML for connectors)

## First steps

There are many ways to create a skill but let's start simple. I googled "astronomy stars database" and the first result was SIMBAD, so...

[random_star.mp4]

## Improving

Not bad! But it took over 30 seconds. Some of that time was spent troubleshooting, which is good information to add to the skill using `skill-creator`.

[skill_creator.mp4]

## Run it back

Let's see how it runs now. I am also going to switch to a less powerful model, Sonnet, which failed to retrieve the data using the original version of the skill.

[improved_random_star.mp4]
___

And then have the text "Much better." replace the video using the fade technique we used for "First steps".

## Branching out: Connectors

Skills are only as powerful as the tools they have to work with. 

___

Connectors (sometimes called MCPs^[footnote: Model Context Protocol]) are a straightforward way to put Claude in touch with your other software^[footnote: For content creation, Claude is set up best for using Microsoft Word, Excel, and PowerPoint. However, its Google Drive extension is great for searching and reading files, and it's usually not too hard to convert output from one filetype to another]. (Footnotes appear along with the sentence that carries the markers.)

### Connectors video slide

First, navigate to the Connectors menu:

[insert connectors_setup.mp4, balance size with avoiding crowded text]

___

If you haven't set up your connectors yet, clicking "Connect" should take you to the login screen for your account.

## Next slide [no title]

Once a Connector is set up, Claude sees it in the chat and should load it for use it when it finds it applicable. For example: 

[insert connectors_use_example.png, fade whole image width to background/white beginning at "Announcements"]
___

Connectors often come equipped with tools adequate for most routine tasks. But if you come up with an outside-the-box idea, creating a Skill can feel like giving Claude superpowers. [smallish text]

##

Add a slide with the emlab-drive-recent.jpg asset up top and a scrollable box with the corresponding SKILL.md filling the main area.