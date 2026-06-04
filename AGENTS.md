# nle.api — agent guidance

Guidance for LLM agents (Claude, Codex, etc.) and humans editing timelines
through nle.api. These rules apply whenever an agent is *constructing visual
content* that will appear in a timeline — text overlays, data slides, "console
snapshot" frames, fake terminal frames, transcribed cards, etc.

The schema and verbs are documented at `inst/schema/TIMELINE_SCHEMA.md`. This
file is about the *creative defaults* drivers and editing agents should
respect.

## Visual content fidelity

### Preserve verbatim source spacing

When recreating any visible artifact that the project owns a source for —
chat transcripts, console output, agent reply blocks, code, README, blog
post copy — **preserve the original spacing, line breaks, bullet glyphs,
and indentation exactly.** Do not "clean up" or "normalize" the formatting.

A reader recognises what they wrote when the whitespace matches. The
moment you collapse blank lines, swap `•` for `*`, re-indent, or rewrap
paragraphs, the artifact stops feeling authentic.

If the original includes a header like:

```
Air Temperature
• Range: 51.4F to 97.3F
• Median: 71.2F, 80th percentile: 75.0F
```

…ship that exact text. Don't shorten "80th percentile" to "p80". Don't
turn the bullet into a checkmark. Don't add a colon after the header.

If the source itself has typos or odd capitalisation, leave them. The
authenticity is the point.

### Match the user's tooling visuals

When the slide is meant to *feel like* it came from the user's actual
working environment (RStudio console, terminal, VSCode panel, etc.):

- **Font:** match the typeface the user actually has configured. If you
  don't know, ask. Default monospace fallbacks (`mono`, DejaVu Sans Mono)
  read as generic; users notice when a "console screenshot" doesn't match
  the font they see every day.
- **Theme:** background colour, foreground colour, prompt colour, comment
  colour, value/output colour — match the user's editor theme. RStudio
  has named themes (Modern, Tomorrow Night, Solarized Dark, Monokai,
  Cobalt, etc.); ask which one before rendering.
- **Window chrome:** keep the slide content-only; don't fake titlebars,
  toolbars, scrollbars unless the user specifically asked for them. The
  source surrounding the slide already establishes the editor context.

If you don't know the user's specific font/theme, render a draft with a
sensible default, *put it in the timeline*, and let the user eyeball it
against their other clips. Iterate from real visual feedback, not from
a Sync/ preview that lacks surrounding context.

### Show real artifacts, not stylized summaries

When the choice is "render a static info graphic with rephrased data"
vs. "render the actual console output that produced that data", prefer
the second. The audience is people who recognise R/Python/shell output;
showing real artifacts reads as honest, while rephrased summaries read
as marketing.

This applies even when the real output is long — better to truncate the
real thing than to write a fake summary. A `...` ellipsis with real
context above and below it lands as authentic. A bulleted slide written
in your own voice lands as a sales pitch.

### Where to source the verbatim text

For corteza demos / agent sessions, the source-of-truth is the saved
chat transcript or terminal log. Read it, copy the relevant block,
preserve it character-for-character. Do not paraphrase from memory or
from a project summary.

For data outputs that aren't in a saved log, ask the user to capture
fresh output (or capture it yourself if you can run the relevant code),
then preserve it verbatim.

## Driver-author guidance

Drivers (blendR for Blender, future drivers for ffmpeg / OTIO / FCP XML)
should document their fidelity statement in their own README or in
`inst/schema/TIMELINE_SCHEMA.md` under a `## <driver> driver fidelity`
section. The blendR driver's statement lives there already; future
drivers should follow the same shape.

Driver authors should not silently coerce values to match their native
units (frames vs. seconds, pixels vs. normalized, centre vs. top-left
coords). Conversion happens at the boundary, lossy approximations are
recorded in `extensions.<driver>`, and the fidelity statement says
which fields round-trip cleanly.
