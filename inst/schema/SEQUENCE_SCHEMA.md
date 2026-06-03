# cornball.sequence.v1

The neutral wire format and on-disk schema for a non-linear edit sequence.
Owned by `nle.api`; targeted by drivers (e.g. `blendR` for Blender VSE).

## File layout

`sequence.md` is the canonical sequence artifact for the cornyverse stack.
It **replaces** the earlier `*.cb.md` (e.g. `FileName.cb.md`) convention,
which conflated human-editable project briefs with structural sequence
state and had no strict parser. New projects, tools, and agents use
`sequence.md` exclusively; `cornductor` still parses `*.cb.md` for
import-only legacy support.

Markdown prose, with a single delimited state block carrying the
structural data:

```
<!-- sequence:state json cornball.sequence.v1 -->
{ ...JSON... }
<!-- /sequence:state -->
```

The opening marker MUST carry three fields:

1. literal `sequence:state`
2. encoding — `json` for v1; `yaml` reserved
3. schema identifier — `cornball.sequence.v1`

`nle.api::read_sequence("sequence.md")` returns the parsed sequence with
the surrounding prose attached. `nle.api::write_sequence()` preserves all
prose and surgically replaces the state block.

`sequence.json` is an optional sibling produced by
`nle.api::export_sequence_json()`. It is a cache for non-Markdown
consumers and is never authoritative.

Strict parser rules:

- Exactly one opening marker and exactly one closing marker.
- Error if either marker is missing, duplicated, or malformed.
- Schema version mismatch is an error (not a warning).
- Comments inside the JSON payload are forbidden; durable commentary
  lives in explicit `notes` arrays on the relevant object.

## Top-level shape

```json
{
  "schema": "cornball.sequence.v1",
  "id": "string",
  "meta": { "title": "string", "notes": ["..."] },
  "timebase": { "fps": { "num": 30, "den": 1 }, "sample_rate": 48000 },
  "canvas": { "width": 1080, "height": 1080 },
  "tracks": [ { ... } ],
  "clips":  [ { ... } ],
  "extensions": { "blender_vse": { ... }, "kerNLE": { ... } }
}
```

`extensions.<driver_name>` is the namespaced sandbox where each driver
stores backend-specific fields it needs to round-trip lossless state
(Blender's `frame_start`, `frame_offset_start`/`end`, speed-strip
channel, etc.). Other drivers MUST ignore extensions they do not
recognize.

## Time

All time values are rational seconds:

```json
{ "num": 4918, "den": 30 }
```

Both integers. `num/den` is the value in seconds. `den` MUST be > 0;
`num` may be negative (e.g. for clips parked left of the playhead).

Helpers in `nle.api` convert to/from `seconds`, frame counts at a given
fps, and SMPTE timecode. Floats never enter the wire format.

## Coordinates

Canonical storage and JSON are **top-left origin, +Y down**, canvas
pixels. This matches ffmpeg, web canvas, FCP XML / OTIO-like
interchange, and most NLE conventions.

The R verb surface accepts three coordinate systems at the call boundary
via a `coord` argument or `options(nle.coords = ...)`. All convert to
canonical top-left on entry:

| `coord`       | Origin       | Y direction | Native to |
|---------------|--------------|-------------|-----------|
| `"topleft"`   | top-left     | down        | canonical (default) |
| `"cartesian"` | bottom-left  | up          | R plotting |
| `"center"`    | canvas centre| up          | Blender VSE |

No `coord` field is ever stored in the JSON payload.

## Tracks

```json
{
  "id": "v1",
  "idx": 1,
  "kind": "video" | "audio" | "image" | "subtitle",
  "label": "string"
}
```

`idx = 1` is the topmost track in the timeline UI (top-left convention).
Lower `idx` composites above higher `idx` for video; mixing order is
unconstrained for audio.

## Clips

```json
{
  "id":       "ch07_v",
  "track":    "v1",
  "kind":     "video" | "audio" | "image" | "subtitle",
  "asset":    "path/or/asset-id",
  "tl_in":    { "num": 4918, "den": 30 },
  "tl_out":   { "num": 5787, "den": 30 },
  "in":       { "num": 36270, "den": 30 },
  "out":      { "num": 37574, "den": 30 },
  "speed":    1.5,
  "transform": {
    "pos_x": 480,
    "pos_y": 20,
    "scale_x": 0.604,
    "scale_y": 0.604,
    "rotation_deg": 0
  },
  "crop": {
    "left":   0.0,
    "right":  0.25,
    "top":    0.0,
    "bottom": 0.0
  },
  "blend":   "alpha_over" | "normal" | "add" | "multiply" | ...,
  "opacity": 1.0,
  "mute":    false,
  "label":   "string",
  "notes":   ["..."]
}
```

Field semantics:

- `tl_in` / `tl_out`: timeline in/out points, rational seconds.
- `in` / `out`: source media in/out points, rational seconds. Source
  consumed = `out - in`; must equal `(tl_out - tl_in) * speed`.
- `speed`: playback multiplier. `1.0` = no rate change; `1.5` = source
  plays 1.5x faster; `0.5` = half speed.
- `transform.pos_x` / `pos_y`: top-left of the displayed unrotated
  bounding box, in canvas pixels, +Y down.
- `transform.scale_x` / `scale_y`: scalar multipliers on the source
  size. `1.0` = native pixels.
- `transform.rotation_deg`: clockwise degrees, applied around the
  displayed bounding box centre AFTER positioning.
- `crop.left` / `right` / `top` / `bottom`: normalized [0, 1] from each
  edge of the source. Drivers may store pixel-exact values in
  `extensions.<driver>` if they need them.
- `blend`: composition mode. `"normal"` (a.k.a. `replace`) is the
  default. Drivers map to their native enums.
- `opacity`: scalar [0, 1].
- `mute`: skip during render and preview.
- `notes`: free-form commentary; survives round-trip.

Operation order (applied in sequence):

1. Apply source trim (`in` / `out`) and crop.
2. Scale to displayed width/height.
3. Place unrotated displayed rectangle at `pos_x`, `pos_y`.
4. Rotate around its centre by `rotation_deg`.
5. Composite using `blend` at `opacity`.

## Drivers and capabilities

Backends register with `nle.api::nle_register_driver(name, dump, apply,
capabilities)`. Each driver SHOULD expose a `capabilities()` function
returning a list:

```r
list(
    formats        = c("blend"),                  # file extensions
    coords         = "video",                     # native coord system
    time           = "frames",                    # native time unit
    fields_preserved = c(...),                    # canonical fields round-tripped
    extensions       = "extensions.blender_vse"   # namespace this driver uses
)
```

Drivers MAY implement only `dump` (read-only describe), only `apply`
(write-only target), or both. nle.api errors clearly when a verb
requests a capability the driver lacks.

## Fidelity statement (each driver SHOULD document)

A driver SHOULD include a short fidelity statement explaining:

- Which canonical fields round-trip losslessly.
- Which fields are lossily approximated (e.g. crop in pixels vs
  normalized).
- Which driver-specific state lives in its `extensions.<driver>`
  namespace.
- Any operations that cannot be expressed in the driver's native model
  (e.g. rotation in a driver without rotation support).

## Blender VSE driver fidelity (`extensions.blender_vse`)

Provided by `blendR::dump_sequence_blender()` /
`blendR::apply_sequence_blender()`.

**Canonical fields round-tripped losslessly:**

- `clip.id` ↔ Blender strip `name`
- `clip.track` (+ `track.idx`) ↔ Blender `channel`
- `clip.asset` ↔ Blender strip `filepath` (for MOVIE/IMAGE) or
  `sound.filepath` (for SOUND)
- `clip.kind` ↔ Blender strip type (movie/sound/image/text)
- `clip.tl_in` / `tl_out` ↔ Blender `frame_final_start` / `frame_final_end`
- `clip.source_in` / `source_out` ↔ derived from
  `frame_offset_start` / `frame_offset_end` and total source duration
- `clip.speed` ↔ Blender SPEED-effect strip's `speed_factor`
- `clip.blend` ↔ Blender `blend_type` (string mapping; `"alpha_over"` ↔
  `ALPHA_OVER`, etc.)
- `clip.opacity` ↔ Blender `blend_alpha` (when static)
- `clip.mute` ↔ Blender `mute`
- `clip.transform.scale_x` / `scale_y` ↔ Blender
  `transform.scale_x` / `scale_y`
- `clip.transform.pos_x` / `pos_y` ↔ Blender
  `transform.offset_x` / `offset_y`, after top-left ↔ center conversion
- `clip.crop.{left,right,top,bottom}` ↔ Blender `crop.{min_x,max_x,min_y,max_y}`
  divided by source dimensions (normalized)

**Stored in `extensions.blender_vse` for lossless round-trip:**

```json
"extensions": {
  "blender_vse": {
    "clip_name_overrides": { "clip_id_in_seq": "raw_blender_name" },
    "clips": {
      "ch07_v": {
        "frame_start":         -31352,   // Blender's tl_in - source_in trick
        "frame_offset_start":  36270,    // raw pixel/frame offsets
        "frame_offset_end":    85750,
        "crop_px": { "min_x": 0, "max_x": 960, "min_y": 0, "max_y": 0 },
        "speed_strip_channel": 3,        // SPEED-effect's channel (parent_channel + 1)
        "speed_control":       "MULTIPLY",
        "keyframes": {                   // animated property values
          "blend_alpha": [
            { "frame": 4918, "value": 1.0 },
            { "frame": 4919, "value": 0.0 }
          ]
        }
      }
    }
  }
}
```

**Operations not expressed in canonical v1 (live in extensions only):**

- **Animation / keyframes.** `blend_alpha` keyframes (used for flicker
  effects, fade in/out via animation rather than precomputed audio
  fades). v1 schema does not model animation curves. A future v2 may
  promote `keyframes` to canonical when other drivers need it.
- **Effect strips other than SPEED** (CROSS, GAUSSIAN_BLUR, GLOW,
  TRANSFORM, etc.). v1 represents these implicitly as canonical clip
  properties (blend, opacity, transform, etc.). Driver can still attach
  raw effect-strip records under `extensions.blender_vse.effects` if
  it round-trips a `.blend` it didn't author.

**Blender-specific operations preserved via extensions:**

- `bl_render_frame()`, `bl_save()`, `bl_exec()`, `bl_render()` — these
  are Blender lifecycle / output operations that don't fit the
  sequence-edit model. They stay as escape-hatch verbs in blendR and
  are invoked outside the `apply_sequence` path.
