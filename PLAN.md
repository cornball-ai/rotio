# Plan: nle.api as the R OTIO wrapper

**Status: PROPOSED** — to be implemented on troy-ai.

## Context

`nle.api` v0.0.x is structurally ~80% OTIO already (rational time,
clip-on-track model, JSON serialization, driver registry pattern).
Realizing this, the decision is to pivot: drop the `cornball.sequence.v1`
identity, adopt OTIO directly, and become the R-language wrapper around
`libopentimelineio`.

Our unique contribution narrows from "a sequence schema" to:

1. **The R verb surface** (`clip_add`, `clip_move`, `clip_trim`,
   `clip_split`, `clip_speed`, `clip_transform`, `clip_crop`,
   `clip_set`, `clip_delete`, `track_add`, `shift_after`).
2. **The Markdown carrier** (`sequence.md` — prose + delimited state
   block holding raw OTIO JSON).
3. **The driver registry pattern** (`nle_register_driver`,
   `dump_sequence`, `apply_sequence`, `driver_capabilities`).

The schema underneath is plain OTIO. We get OTIO's mature
JSON read/write, edge cases, schema versioning, and (eventually,
through `otioconvert` shell-out) FCP XML / AAF / EDL / Premiere /
Resolve interop for free.

## Architecture after the pivot

```
                 Pure-R (Rcpp shim)
                       |
   nle.api  ----  libopentimelineio (C++)
   |    |    \
   |    |     \-- libopentime (C++)
   |    |
   |    \--- Markdown carrier (sequence.md)
   |    \--- R verb surface
   |    \--- driver registry
   |
drivers: blendR (Blender VSE), future ffmpeg / OTIO native /
         FCP XML / AAF / EDL
```

`nle_sequence` (R S3) wraps an `Rcpp::XPtr<otio::Timeline>`. Verbs
mutate via copy-and-return. `seq$clips` becomes a fresh data.frame
view materialised from the C++ Timeline on read. Edits go through
verbs only.

## Why C++ wrap, not pure R or reticulate

| | Choice | Outcome |
|---|---|---|
| Pure R (status quo + rename) | Reimplement OTIO's JSON shape in R | Doable, but we keep finding the edge cases OTIO already fixed (gaps, transitions, negative durations, schema versioning); two parallel implementations to maintain |
| `reticulate` over Python OTIO | Easiest interop, gets all adapter plugins for free | **Rejected.** Adds a Python runtime dep; against the tinyverse / minimal-deps direction |
| **C++ wrap via Rcpp** | **Chosen.** Native R, no Python, delegates all serialization + schema work to libopentimelineio | One C++ dep (`libopentimelineio-dev`), an Rcpp shim, and the R verb surface. Tracks OTIO releases via the system library version |

## Identity / branding changes

| Today | After |
|---|---|
| `schema = "cornball.sequence.v1"` (top-level string) | Per-object `OTIO_SCHEMA = "Timeline.1"` / `"Track.1"` / `"Clip.1"` etc., set by OTIO itself during serialization |
| `<!-- sequence:state json cornball.sequence.v1 -->` | `<!-- sequence:state otio -->` (encoding is implicit JSON since OTIO speaks JSON natively) |
| `extensions.blender_vse.*` | `metadata.blender_vse.*` (OTIO's standard extension namespace) |
| `tl_in`, `tl_out`, `source_in`, `source_out` field names | OTIO's `source_range = TimeRange{start_time, duration}` |
| `transform.pos_x` / `pos_y` / `scale_x` / `scale_y` / `rotation_deg` | An OTIO `EffectReference` carrying the transform |
| `crop.left/right/top/bottom` (normalized) | An OTIO `EffectReference` for crop |
| `coord = "topleft" / "cartesian" / "center"` opt-in | **Drop.** OTIO doesn't standardize coord origin; effects can carry whatever convention they want in `metadata`. Default top-left. |
| `rational_time(num, den)` constructor (R list) | `RationalTime` XPtr wrapping `otio::RationalTime` |

The **R-facing verb names stay the same** so existing scripts keep
working. Only what's inside `nle_sequence` and on the wire changes.

## Dependencies (DESCRIPTION)

```
Imports: Rcpp
LinkingTo: Rcpp
SystemRequirements: libopentimelineio-dev (>= 0.17), pkg-config
```

Install on Debian/Ubuntu:

```bash
sudo apt install libopentimelineio-dev
```

On troy-ai (the build target), confirm the headers + .so are present
before scaffolding `src/`.

## Migration in PR-sized commits

### PR 1 — Build chain + RationalTime wrap

- `DESCRIPTION`: add `Imports: Rcpp`, `LinkingTo: Rcpp`,
  `SystemRequirements`.
- `src/Makevars` or `src/Makevars.in`: link
  `-lopentimelineio -lopentime`. Use `pkg-config` if OTIO provides a
  `.pc` (verified at install time); otherwise hard-code `-I/usr/include`
  + `-L/usr/lib`.
- `src/init.cpp` + `src/rational_time.cpp` — wrap `otio::RationalTime`
  (`new`, `to_seconds`, `to_frames(rate)`, `rate`, `value`).
- `R/zzz.R` — `useDynLib(nle.api, .registration = TRUE)`.
- `R/time.R` — rewrite to return `Rcpp::XPtr<RationalTime>` from the
  `rational_time()` constructor; `to_seconds()` / `to_frames()` /
  `to_rational()` call into C++.
- Tests: round-trip a `RationalTime` through C++.

Goal: verify the build works on troy-ai, the linker finds OTIO,
Rcpp can carry an XPtr through R.

### PR 2 — Timeline / Stack / Track / Clip / ExternalReference

- `src/sequence.cpp` — wrap the Timeline + Stack + Track + Clip +
  ExternalReference classes. Constructor + JSON serialization (using
  OTIO's `SerializableObject::to_json_string` /
  `SerializableObject::from_json_string`) + accessors.
- `R/sequence.R` — `new_sequence()` constructs a C++ Timeline,
  returns an `nle_sequence` S3 wrapping the XPtr. `seq$tracks` and
  `seq$clips` accessors materialise data.frames from the C++ side
  on demand.
- `R/verbs.R` — re-implement `clip_add()`, `clip_delete()`,
  `track_add()` as the smallest viable verb set.
- Tests: build a 3-clip sequence in R, serialize to JSON, parse back,
  verify shape.

Goal: a Timeline can be constructed, populated, JSON-dumped, and
JSON-restored entirely through the wrapped C++ — no R-side schema
code in the data path.

### PR 3 — Remaining verbs

- `clip_move` / `clip_trim` / `clip_split` / `clip_speed` /
  `clip_transform` / `clip_crop` / `clip_set` / `shift_after`.
- Per-verb tests, matching the current `inst/tinytest` suite.
- Deprecate (but keep callable for one release) the R-only
  implementations in old `R/verbs.R`; they error and tell you to
  install the C++ build.

Goal: full verb parity with the current pure-R surface.

### PR 4 — Marker-block IO

- `R/io.R` — keep the marker parser (`<!-- sequence:state otio -->` /
  `<!-- /sequence:state -->`). The body becomes raw OTIO JSON; pass
  it to OTIO's deserializer via the C++ shim. `write_sequence()`
  similarly serializes the Timeline through OTIO and surgically
  replaces the state block.
- Update marker text: `cornball.sequence.v1` → `otio`.
- Rewrite `inst/schema/SEQUENCE_SCHEMA.md` to describe the carrier
  (the Markdown convention) and point at OTIO's docs for the inner
  JSON schema.
- Delete `R/json.R`; OTIO owns serialization.
- Delete `R/coords.R`; transforms live in `EffectReference`.

Goal: a `sequence.md` round-trip uses only OTIO's serializer for
the JSON; we just wrap it in our Markdown carrier.

### PR 5 — blendR driver refactor

- `blendR::dump_sequence_blender()` builds an OTIO Timeline using
  nle.api's C++ wrappers (no field-name guessing).
- `blendR::apply_sequence_blender()` reads OTIO objects via nle.api
  and pushes to Blender VSE via existing `bl_exec` machinery.
- The conversion math (top-left ↔ centre, frames ↔ RationalTime)
  doesn't change. Field names do (e.g., `source_in` →
  `clip$source_range$start_time`).
- Re-dump `corteza_demo/sequence.md` and re-apply cuts 1 and 2 to
  validate end-to-end parity with the current v8 state.

Goal: the live `corteza_blendR_v8.blend` reachable through the new
nle.api stack with no behavioural regression.

### Post-migration (out of scope here, but worth flagging)

- **`otioconvert` shell-out** in `nle.api` for FCP XML / AAF / EDL
  / Premiere / Resolve export. Uses the Python OTIO CLI installed
  separately (we don't ship Python; users invoke it from R via
  `system2()`).
- **Direct binding to OTIO's adapter plugin API** if we want native R
  access to adapters. Bigger lift; defer until needed.

## Compatibility / breaking changes

- **R verb surface stays.** Scripts that call `clip_add(seq, ...)`,
  `clip_move(...)`, etc. work as-is.
- **`seq$clips` shape stays a data.frame** (view materialised from C++).
  Callers that read `seq$clips$tl_in` will need to read the OTIO field
  (`seq$clips$source_range$start_time` or a derived `tl_in_frames`
  helper column we add for backward visibility).
- **`sequence.md` files written by 0.0.x do NOT load on 0.1.x.** The
  marker text changed and the JSON schema changed. A one-shot
  conversion script (`migrate_sequence_md.R`) lives in
  `inst/migrations/` and reads old marker blocks + rewrites them as
  OTIO. Run it once per old project.
- **`extensions.blender_vse.*` becomes `metadata.blender_vse.*`.**
  Same data, different namespace. Conversion script handles it.

## What this kills in the current codebase

```
R/sequence.R         REWRITE   (XPtr-backed, OTIO-shaped)
R/verbs.R            REWRITE   (delegates to C++)
R/json.R             DELETE    (OTIO owns serialization)
R/coords.R           DELETE    (effects carry coordinate convention)
R/io.R               KEEP      (Markdown marker IO; our contribution)
R/driver.R           KEEP      (driver registry pattern; ours)
R/time.R             SHRINK    (thin R wrapper over otio::RationalTime XPtr)
R/ripple.R           KEEP      (shift_after delegates to C++)
inst/schema/         REWRITE   (carrier doc + OTIO pointer)
inst/tinytest/       UPDATE    (new field names + XPtr handling)
AGENTS.md            UPDATE    (drop cornball.sequence.v1 references)
```

## Test plan

After PR 5:

- [ ] `tinytest::test_package("nle.api")` — full suite green.
- [ ] A round-trip of the current `corteza_demo/sequence.md` (after
  conversion via `migrate_sequence_md.R`) produces a byte-identical
  output on re-serialization (modulo whitespace).
- [ ] `nle.api::dump_sequence("blender")` on the live v8 session
  returns an `nle_sequence` whose `seq$clips` view matches the
  pre-pivot dump.
- [ ] `nle.api::apply_sequence("blender", seq)` rebuilds v8 with the
  IMAGE strips, SPEED effects, and channel assignments intact.
- [ ] An exported OTIO JSON file passes
  `python -c "import opentimelineio as otio; otio.adapters.read_from_file('sequence.json')"`
  validation.

## Open questions for implementer

1. **`SerializableObject::Retainer<T>` and Rcpp.** OTIO's smart-pointer
   pattern is a wrapper around its serialization framework. We
   probably want the shim to take/return raw `T*` and let OTIO manage
   the retainer internally, exposing only `Rcpp::XPtr<T>` to R.
2. **Memory model on copy-mutate verbs.** Each verb returns a *new*
   `nle_sequence` — do we deep-clone the C++ Timeline on every verb
   call, or expose mutation explicitly? Pure-function R semantics
   argue for deep clone; performance argues for a builder pattern.
   For our scale (50–200 clips per sequence) deep-clone is fine.
3. **Effect representation for `clip_transform()`.** OTIO has
   `LinearTimeWarp` (for speed) and a generic `Effect` class. We
   either add a `metadata.cornyverse.transform`-flavoured effect or
   contribute a proper `TransformEffect` upstream. Start with the
   metadata approach; upstream later if useful.
