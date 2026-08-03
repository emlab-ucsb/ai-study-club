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

It's when Claude loads a set of specialized tools within a chat or Cowork session

[Insert kung fu JPG I put in `assets/`]

## Picking up where we left off with CLAUDE.md

Claude Skills are sort of like a CLAUDE.md file, but designed for use outside of codebases.

Add a table comparing CLAUDE.md (left) and Skills. Use formatting described in this folder's CLAUDE.md. Can you have the rows of the table appear one by one on click?

| CLAUDE.md | Skills |
| --- | --- |
| Added to Claude Code context automatically on load | Skill title and summary always available to Claude Chat and Cowork |
| Lives in the repo, scoped to that codebase | Lives with your account or Projects |
| A single markdown file | A folder: `SKILL.md` plus any scripts or reference files |
| Can be shared between teammates on a GitHub repo | Can be shared with individuals or the whole emLab team on the Claude app |

## First steps

Skills are located under the Customize menu. Claude comes with a library of Skills out of the box, but they are pretty generic. 

[assets/skills_setup.mov] (match formatting currently in the HTML for connectors)

## No title

[Center text] Creating Skills that are tailored to a specific user or organization is the .

## Upskilling: Connectors

Skills are only as powerful as the tools you put in their hands. 

Connectors (sometimes called MCPs^[footnote: Model Context Protocol]) are a straightforward way to put Claude in touch with your other software^[add a footnote about how there is a connector for Google Drive but not yet for Google Docs, Sheets, Slides]. 

### Connectors video slide

First, navigate to the Connectors menu:

[insert connectors_setup.mov, balance size with avoiding crowded text]

___

If you haven't set up your connectors yet, clicking "Connect" should take you to the login screen for your account.

## Next slide [no title]

Once a Connector is set up, Claude sees it in the chat and should load it for use it when it finds it applicable. For example: 

[insert connectors_use_example.png, fade whole image width to background/white beginning at "Announcements"]

