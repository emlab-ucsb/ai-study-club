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
- Use cases
___
- Live demo??

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

How to view their status depends on which platform you are using. 

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
___

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

## Model tiers

Consider starting with:

**Fable 5.1** — Deep research and math questions, autonomous improvement of large model codebases

[on the click advance after Fable appears, gray it out, including the card background color, and have text appear below it saying "No longer available on our plan 😭". Then have the annotation disappear when Opus shows up, but keep the gray Fable card and use case info text.]

**Opus 5** — Complex agentic coding, data exploration, statistical modeling, tasks with creative or visual elements

**Sonnet 5** — Sufficient for most text creation and editing, administrative tasks, and code development

**Haiku 4.5** — Focused on cost-effectiveness and instant responses, but sometimes prone to hallucination

[Condensed from the use-case table in Anthropic's docs. Table-style rows, each name in a chip filled with its color from the slide before, rows appearing one at a time.]

## Working efficiently

First, some definitions:
___

**Token:** Large language models (LLMs) are trained on and work with text in units of a few characters each—about 4 on average per token including spaces and punctuation. [left justify]
___

**Context window:** When you write the first prompt of a conversation, the LLM reads a bunch of other text and files alongside it. For subsequent prompts, it remembers the whole conversation, including file reads and writes.*[footnote: *until it runs out of space, but frontier models have room for 1,000,000+ tokens in their context window, the equivalent of around 2,000 pages]. [left justify]

## Working efficiently

**Keep conversations short.**
___

Every prompt re-reads the whole conversation above it, so the twentieth message costs far more than the first.
___

When the topic changes, start over: `/clear` in Claude Code, or a new chat in the app.

[bold line as a lead-in above the body text, the rest appearing one at a time]

## Working efficiently

**Give it less to read.**
___

- **Name the file or folder you mean.** A vague prompt sends Claude hunting around your whole project first.
___
- **Attach the table, not the 200-page report** it came in.
___
- **If efficiency is key, disable connectors you don't use.** Every one that is switched on is described in the context window every turn.
___
- **Batch tasks.** If you have a few clear and related goals, putting them all in one prompt may help Claude economize. 
___

In Claude Code, `/context` shows you what is actually taking up space.

[bullets with the same accent dots as the outline slide]

## Working efficiently

**Match the effort to the task.**
___

`/effort` sets how hard the model thinks before it answers: `low`, `medium`, `high`, `xhigh`, `max`.* Effort can be customized for all models except Haiku.
___

`high` is the default but often not necessary. Save `xhigh` and `max` for huge, challenging projects.
___

Effort is displayed next to the model name in the Chat and Cowork apps.

[footnote appears simultaneously with asterisk above: *For early LLMs, just writing "think hard", or "ultrathink" into their prompt led them to produce better results—the inspiration for the "effort" setting. `/ultrathink` still works too.]

## Working efficiently

**Write the standing context down once.**
___

**CLAUDE.md** in Claude Code, **Projects** in the app: the facts about your work that Claude would otherwise burn usage rediscovering in each new session.
___

Keep it short — it is re-read on every turn, so a bloated CLAUDE.md is a tax you pay continuously.

## Working efficiently

**⚠️ Cowork is a usage hog.**
___

It is at its most expensive when it drives your computer or your Chrome browser: for many actions, it takes a screenshot and looks at it, and an image costs many times what the same information in plain text would.

It is also working unattended, so nobody is watching the meter.

[warning card — coral border and tint.]

## Actual tasks

[On this slide, start with showing the `id.md` prompt, then have the responses from the `results_x` subfolders appear one by one, in ascending order by tier]

## Kelvin

[On this slide, add a table with the runtime stats (cost, number of tokens, wall clock runtime) and a link to the resulting HTML for the kelvin.md task.]

