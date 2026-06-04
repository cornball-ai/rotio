# nle.api timeline carrier

`nle.api`'s timeline model **is** OpenTimelineIO (OTIO). There is no separate
`nle.api` schema: a timeline is an OTIO `Timeline`, and the on-disk JSON is
canonical OTIO (each object carries its own `OTIO_SCHEMA`, e.g. `Timeline.1`,
`Track.1`, `Clip.2`, `Gap.1`, `ExternalReference.1`). nle.api binds the OTIO
C++ library through Rcpp and lets OTIO own serialization, schema versioning,
and file upgrade/downgrade.

This document describes only nle.api's own contribution: the **Markdown
carrier** and the **driver registry**. For the inner JSON schema, see the OTIO
docs: <https://opentimelineio.readthedocs.io>.

## File layout

`timeline.md` is the canonical artifact. Markdown prose with a single delimited
state block carrying raw OTIO JSON:

```
<!-- timeline:state otio -->
{ ...OTIO JSON... }
<!-- /timeline:state -->
```

The opening marker carries the literal `timeline:state` and the encoding token
`otio`. Encoding is implicit JSON (OTIO speaks JSON natively).

`nle.api::read_timeline("timeline.md")` parses the block into an
`nle_timeline` (a handle to a live OTIO `Timeline`) with the surrounding prose
attached. `nle.api::write_timeline()` preserves all prose and surgically
replaces only the state block.

Strict parser rules:

- Exactly one opening marker and exactly one closing marker.
- Error if either marker is missing, duplicated, or malformed.

`timeline.md` replaces the earlier `*.cb.md` convention, which is dead.

## Model

A timeline is an OTIO `Timeline` containing a `Stack` of `Track`s. Each track is
an **ordered, contiguous** list of items: `Clip`s and `Gap`s. A clip has no
absolute timeline position; its position is the sum of the durations before it,
and empty space is an explicit `Gap`.

nle.api's verbs think in absolute timeline frames (`tl_in`/`tl_out`) and
translate to/from the sequential model: when a timeline is rebuilt, Gaps are
inserted to honour each clip's `tl_in` ("gap model A"). Two clips may not
overlap on one track; overlapping placements are an error (use separate
tracks).

`timeline$clips` and `timeline$tracks` are fresh data.frame views materialised from the
OTIO Timeline on read. Edits go through the verbs only.

### Time

Times are `RationalTime` (value, rate) — value is the frame number, rate the
fps. The R verb surface accepts integer/seconds/`rational_time`/`otio_time`
inputs and converts at the boundary. fps, canvas, and sample rate are stored in
the Timeline metadata (`nle_fps_num`, `nle_fps_den`, `nle_canvas_w`,
`nle_canvas_h`, `nle_sample_rate`) so they survive serialization.

### Not yet modelled (returns with OTIO effects)

Speed/time-remap, transform (position/scale/rotation), crop, blend, opacity,
mute, and labels are **not** in this release. They migrate to OTIO `Effect` /
`LinearTimeWarp` / per-clip metadata in a later PR; the corresponding verbs
(`clip_speed`, `clip_transform`, `clip_crop`, `clip_set`) currently error with
a pointer to that work.

## Drivers and capabilities

Backends register with `nle.api::nle_register_driver(name, dump, apply,
capabilities)`. Each driver SHOULD expose a `capabilities()` returning a list:

```r
list(
    formats          = c("blend"),   # file extensions
    coords           = "video",      # native coord system
    time             = "frames",     # native time unit
    fields_preserved = c(...),       # OTIO fields round-tripped
    metadata         = "blender_vse" # metadata namespace this driver uses
)
```

Driver-specific lossless state lives under OTIO object `metadata` in a
driver-named namespace (e.g. `metadata.blender_vse`), OTIO's standard extension
mechanism. Other drivers MUST ignore metadata namespaces they do not recognize.

Drivers MAY implement only `dump` (read-only describe), only `apply`
(write-only target), or both. nle.api errors clearly when a verb requests a
capability the driver lacks.

## Interop

Because the on-disk form is canonical OTIO, files written by nle.api can be
fed to OTIO's `otioconvert` for export to FCP XML / AAF / EDL / etc., and read
by any OTIO-aware tool, without nle.api in the loop.
