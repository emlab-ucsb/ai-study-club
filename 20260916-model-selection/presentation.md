<!--
This file is the source of truth for the slide content of a Reveal.js deck
(built as a standalone `.html` file in this folder, CDN-loaded, no build
step — following the pattern in `20260805-skills-demo/`). Claude's job is to
apply what's written here to the HTML; the HTML is the build artifact, so
slide content should be authored here, not directly in the deck, unless
asked otherwise.

Ground rules, adapted from `20260805-skills-demo/CLAUDE.md`:

- Each `## Heading` below is one slide. '___' on its own line means the
  following text should 'appear' as a fragment (click-to-reveal) on the same
  slide, rather than starting a new slide.
- The deck is strictly left/right: every slide is a top-level `<section>`.
  Don't nest `<section>`s to create vertical (up/down) stacks — flatten any
  sub-structure into consecutive horizontal slides instead.
- Bracketed notes like `[insert some_asset.png]` describe an asset or
  formatting instruction to apply, not literal slide text.
- If an instruction here is ambiguous or references content that hasn't been
  supplied yet, apply everything else and flag the gap rather than inventing
  content.
-->

## Title slide

*How to create fabulous work without using Fable*

Jordan Wingenroth

Claude Study Club

September 16, 2026

## Outline
___
- Two months in
___
- Usage limits
___
- Model tiers
___
- Efficiency tricks
___
- Choosing the appropriate model

## Two months in

Since our team account opened in mid-July, emLab has engaged in

**1,372 Code sessions**

and 

**1,255 Chat and Cowork conversations**

...and counting^[asterisk with footnote:*The contents of which are private. The admin panel just shows summary stats.*]



[Format it with the figures in text boxes, upper left and lower right. Make it look stylish. Set the privacy line as a small footnote under the tallies, bottom left.]

## Two months in

We have done much of that within our individual usage limits, but we have also taken advantage of

**$2,500 in extra usage credits**

provided by Anthropic as a welcome bonus.

[Match formatting to prior slide, put box center and use Fable blue for value, no italics for text at bottom of text box, match beginning including splitting into at least two lines.]

## Usage limits

Now that we have used up the extra credits, those usage warnings carry a bit more weight. 
___

Claude uses a system of 

**5-hour session limits** and **7-day weekly limits.** [all one line, underline bolded text, make sure it is centered, no paragraph break before it.]
___

How to view them depends on which platform you are using. 

## Usage limits

On Claude Code, you can type `/usage`.

[`assets/usage_menu.png`, 1em instead of 2em before the image]

## Usage limits

In the Chat and Cowork apps, it is a page in the settings menu accessed by clicking your name in the lower left.

[`assets/app_usage_menu.png`, 1em instead of 2em before the image]

## Usage limits

Every individual user has their own limit. Unlike the shared extra usage credits, now your usage doesn't affect availability for others at all.
___

Usage of Chat, Code, and Cowork all deduct from the same limit, although they may have different per-token rates. 

## Usage limits

Across the platforms, the higher-tier models burn usage faster, but the relative rates aren't know.

Ultimately, there is no published explanation of how Anthropic gets to the percent value you see in the menu.

[add a shrug emoji or something?]

## Model tiers

There are four levels of Claude. 

Current versions are:

**Fable 5.1** — newest and most capable

**Opus 5** — heavy lifting and deep reasoning

**Sonnet 5** — the balanced default

**Haiku 4.5** — fastest and lightest

[Four boxes in a 2x2 grid, each filled with that model's icon color from the Claude website.]
___

There is also a restricted model called Mythos, which Fable is built on.

