# nle.api 0.0.2.22 (dev)

## Fixes

* `trimmed_range_in_parent` errors on exact boundary contact with the parent
  source range (no overlap), matching opentime. Validated against rotio.

# nle.api 0.0.2.21 (dev)

## Fixes: source-fidelity pass across phases 1-4

* Audited against the OTIO C++/Python source: to_frames/from_frames truncate;
  end_time_exclusive at duration rate; to_time_string negatives; to_timecode
  infers drop-frame; frame_for_time without frame_step quantization; ISR URL
  separator; trimmed_range_in_parent parent-coords + out-of-range error; Track
  available_range edge transitions; flatten disabled-track filter only for Stack;
  Transition duration(). All validated against rotio.

# nle.api 0.0.2.20 (dev)

## Fixes: flatten length-normalization

* `flatten_stack` pads a shorter top track so longer tracks below show through;
  filters disabled tracks. `track_trimmed_to_range` mirrors the OTIO source. Found
  by reading OpenTimelineIO C++ source directly.

# nle.api 0.0.2.19 (dev)

## Fixes: transition parity in trim and flatten

* `track_trimmed_to_range` keeps/drops/errors transitions correctly; `flatten_stack`
  is gap-filling and preserves transitions. Validated against rotio.

# nle.api 0.0.2.18 (dev)

## Fixes: Stack parallel semantics + transitions in algorithms

* Stack children are parallel (range_in_parent starts at 0; available_range is
  the max child span); track_trimmed_to_range and flatten_stack handle tracks
  with transitions. Validated against rotio.

# nle.api 0.0.2.17 (dev)

## Fixes: ImageSequenceReference parity (round 2)

* `end_frame` correct for non-divisible durations; `frame_for_time` errors out of
  range; negative image numbers extrapolate (no error); signed zero-padding.

# nle.api 0.0.2.16 (dev)

## Fixes: coordinate model (transitions, tracks, rates)

* `range_in_parent`/`visible_range` handle Transitions; `available_range`/
  `trimmed_range` work for tracks; `track_trimmed_to_range` is rate-faithful;
  `flatten_stack` honours `enabled`; `visible`/`overlapping` corrected. Validated
  against rotio.

# nle.api 0.0.2.15 (dev)

## Fixes: ImageSequenceReference parity

* `end_frame` (correct for frame_step>1 and no available_range), out-of-range
  errors for `target_url_for_image_number`/`presentation_time_for_image_number`,
  no zero-padding when `frame_zero_padding == 0`, and `frame_for_time` (the
  ImageSequenceReference method). Validated against rotio.

# nle.api 0.0.2.14 (dev)

## Phase 4 of full OTIO parity: composition coordinate model

* `range_in_parent`, `trimmed_range`, `trimmed_range_in_parent`, `visible_range`,
  item `available_range`, `video_tracks`/`audio_tracks`, `global_start_time`,
  `is_equivalent_to`, `visible`, `overlapping`, `track_trimmed_to_range`, and
  `flatten_stack` -- positions from gaps + child order, validated against rotio.

# nle.api 0.0.2.13 (dev)

## Fixes: time-model rate fidelity

* `range_from_start_end_time`/`extended_by` keep the start rate; `clamped` uses
  opentime operator- rate; `end_time_inclusive` returns the start for spans <= 1
  frame; `almost_equal` rescales to the second arg; `to_timecode`/`from_timecode`
  are faithful for non-integer and drop-frame rates; `from_time_string` keeps the
  fractional value. Validated against rotio (value AND rate).

# nle.api 0.0.2.12 (dev)

## Phase 3 of full OTIO parity: object surface

* Media-reference subtypes (`MediaReference`, `GeneratorReference`,
  `ImageSequenceReference` with its computed frame/url methods), `Marker`,
  `Transition` (composable), and `TimeEffect`/`FreezeFrame` -- JSON-shape and
  behavior matched to rotio.

# nle.api 0.0.2.11 (dev)

## Phase 2 of full OTIO parity: time model

* RationalTime/TimeRange arithmetic and queries matching libopentime exactly
  (validated against rotio): `almost_equal`, `end_time_exclusive`/`inclusive`,
  `range_from_start_end_time`, `contains`, `intersects`, `overlaps`, `extended_by`,
  `clamped`, `to_timecode`/`from_timecode`, `to_time_string`/`from_time_string`,
  and `TimeTransform`.

# nle.api 0.0.2.10 (dev)

## Phase 1 of full OTIO parity: environment-backed core

* The object model is now environment-backed with reference semantics (internal
  `.parent` pointers, never serialized), the foundation for full rotio parity
  (see PLAN.md / OTIO_PARITY.md). Mutating tree ops mirror rotio: `append_child`,
  `insert_child`, `set_child`, `set_children`, `remove_child`, `clear_children`
  (attaching an already-parented child errors); plus `parent`, `children`,
  `has_child`, `has_clips`, `is_parent_of`, `index_of_child`, `find_clips`,
  `clone` (deep, parent-aware), `color`, `kind<-`, `media_reference<-`,
  media-reference keys, and `SerializableCollection`.
* The functional builders (`add_child`/`add_track`/`add_effect`) remain as
  value-semantics sugar over the mutating core, so existing callers (licuadora)
  are unaffected. Serialized OTIO JSON is unchanged (still rotio-equivalent).

# nle.api 0.0.2.9 (dev)

## New: OTIO effects

* `Effect()` and `LinearTimeWarp()` constructors (mirroring rotio's JSON shapes
  and defaults), plus functional `add_effect()` and the accessors `effects()`,
  `effect_name()`/`<-`, `time_scalar()`/`<-`, and `enabled()`/`<-` (a disabled
  clip is muted; a disabled effect is bypassed). Effects round-trip through JSON
  and are accepted by the real OTIO library via `rotio`. This is the surface the
  blendR bridge uses to carry speed (`LinearTimeWarp`) and Blender compositing.

# nle.api 0.0.2.8 (dev)

## Rewrite: pure-R OpenTimelineIO ("rotiolite")

* nle.api is now a dependency-light, pure-R OTIO document layer. **All compiled
  code is gone** — no `Rcpp`, no `LinkingTo`, no `SystemRequirements`,
  no libopentimelineio. `Imports: jsonlite` only; `rotio` moves to `Suggests`.
  (Reason: `rotio`'s OTIO C++ is hard to get on CRAN; nle.api becomes the
  CRAN-clean layer the cornyverse can depend on.)
* New object model: list-based constructors `Timeline()`, `Track()`, `Stack()`,
  `Clip()`, `Gap()`, `ExternalReference()`, `MissingReference()`,
  `RationalTime()`, `TimeRange()` — names and JSON shapes match `rotio` so output
  is interchangeable.
* Functional, value-semantics builders: `add_child()` and `add_track()` return a
  new object rather than mutating in place. Accessors `metadata()`/`metadata<-`,
  `name()`/`name<-`, `kind()`, `children()`, `tracks()`, `source_range()`,
  `media_reference()`, `target_url()`, plus time helpers `value()`, `rate()`,
  `start_time()`, `duration()`, `to_seconds()`/`from_seconds()`,
  `to_frames()`/`from_frames()`, `rescaled_to()`.
* Serialization: `to_json_string()` / `to_json_file()` emit canonical OTIO JSON
  via `jsonlite`; `from_json_string()` / `from_json_file()` parse it back.
  Verified byte-equivalent against `rotio` (and thus real libopentimelineio).
* OTIOD bundles: `read_otiod()` / `write_otiod()` for `content.otio` + `media/`
  directory bundles.
* Optional `validate_with_rotio()` round-trips emitted JSON through the real OTIO
  library when `rotio` is installed; unverified otherwise.
* **Removed** (return in a later pass, re-backed on the new objects): the
  `nle_timeline` verb layer (`clip_*`/`track_*`/`ripple_delete`/`shift_after`),
  the driver registry, the `timeline.md` Markdown carrier, and the old `otio_*`
  Rcpp object/ time wrappers.

# nle.api 0.0.2.7 (dev)

## New: generic clip effects (clone-based)

* `clip_effect_add()`, `clip_effects()`, `clip_effect_params()`,
  `clip_effect_remove()` — attach, list, read, and remove arbitrary OTIO
  `Effect`s on a clip. An effect is an `effect_name` plus a metadata dictionary,
  modelled directly on OTIO's `Effect` schema; parameters are stored as
  individual OTIO metadata entries. A driver maps `effect_name` + params to its
  engine (e.g. Kdenlive/MLT filters). Transform, crop, colour, etc. are generic
  effects via this API rather than fixed fields.
* These verbs are **clone-based**: each deep-clones the timeline (OTIO `clone()`
  copies every clip/gap/effect/metadata), mutates the target clip, and returns
  the clone, leaving the input untouched. Effects added this way survive
  subsequent structural edits — the scalar-table rebuild clones non-time
  effects forward by clip id — and survive JSON round-trips.
* Removed the Blender-shaped `clip_transform`/`clip_crop`/`clip_set` stubs;
  compositing is now generic OTIO effects via `clip_effect_add()`. `clip_speed`
  (an OTIO `LinearTimeWarp`) is unchanged and lists alongside generic effects in
  `clip_effects()`.

# nle.api 0.0.2.6 (dev)

## Changes

* OTIO migration PR 4 (effects, part 1): `clip_speed()` is implemented, modelled
  on OTIO's own effect schema. Speed is recorded as a `LinearTimeWarp`
  (`time_scalar = speed`, >1 faster) on the clip. Per OTIO's model the warp is an
  annotation, so it does **not** change the clip's timeline footprint — the
  source range still defines what is shown and a player/driver applies the rate.
  `clip_add()` accepts a `speed`, and `timeline$clips` gains a `speed` column.
  Speed survives serialization and structural edits.
* Wrapped OTIO's `LinearTimeWarp` (the speed effect). The effect set OTIO codes
  is `Effect` -> `TimeEffect` -> `LinearTimeWarp` -> `FreezeFrame`; OTIO has no
  spatial-transform or crop schema, so those will be generic `Effect` objects.

## Still deferred

* `clip_transform`, `clip_crop`, `clip_set` — these become a **generic OTIO
  `Effect` API** (`clip_effect_add`/`clip_effects`), modelled on OTIO rather than
  Blender-shaped fixed fields. That needs a clone-based mutation path (the
  scalar-table rebuild can't carry arbitrary per-clip effects), which lands in
  its own PR. They error with a pointer for now.

# nle.api 0.0.2.5 (dev)

## New verbs

Structural edit verbs that round out the surface (no new C++; all expressible
in the gap model):

* `track_delete()` - remove a track and its clips.
* `track_move()` - reorder a track in the compositing stack.
* `ripple_delete()` - delete a clip and close the gap (vs `clip_delete`, which
  leaves one).
* `clip_slip()` - shift a clip's source in/out without moving its timeline
  position.
* `clip_duplicate()` - copy a clip to a new position (defaults to right after
  the original).

# nle.api 0.0.2.4 (dev)

## Changes

* Renamed the `sequence` vocabulary to OTIO's `timeline` throughout. OTIO's
  top-level object is a `Timeline`, so the wrapper now speaks the format's own
  language. Exported renames: `new_sequence` -> `new_timeline`, `nle_sequence`
  (class) -> `nle_timeline`, `is_sequence` -> `is_timeline`, `seq_fps` ->
  `timeline_fps`, `seq_duration_frames` -> `timeline_duration_frames`,
  `sequence_summary` -> `timeline_summary`, `read_sequence`/`write_sequence` ->
  `read_timeline`/`write_timeline`, `sequence_to_json`/`sequence_from_json` ->
  `timeline_to_json`/`timeline_from_json`, `validate_sequence` ->
  `validate_timeline`, `extract_sequence_state_md`/`replace_sequence_state_md`
  -> `*_timeline_state_md`, `dump_sequence`/`apply_sequence` ->
  `dump_timeline`/`apply_timeline`.
* The canonical artifact is now `timeline.md` with a `<!-- timeline:state otio
  -->` state block; `inst/schema/SEQUENCE_SCHEMA.md` -> `TIMELINE_SCHEMA.md`.
* No behaviour change. (blendR's driver bridge picks up the new names in PR 5.)

# nle.api 0.0.2.3 (dev)

## Changes

* OTIO migration PR 3: the sequence model is now OTIO-backed. `new_sequence()`
  returns an `nle_sequence` wrapping a live OTIO `Timeline`; `seq$clips` and
  `seq$tracks` materialise data.frame views from C++ on read, and edits go
  through the verbs only.
* Structural verbs reimplemented on OTIO: `track_add`, `clip_add`,
  `clip_delete`, `clip_move`, `clip_trim`, `clip_split`, `shift_after`. Each
  reads the current state, applies the edit, and rebuilds the Timeline.
* **Gap model A.** A track is sequential; a clip's timeline position is encoded
  by OTIO `Gap`s computed from `tl_in`. Overlapping clips on one track are now
  an error (use separate tracks). fps/canvas/sample_rate live in the Timeline
  metadata and survive serialization.
* `sequence.md` now carries raw OTIO JSON in a `<!-- sequence:state otio -->`
  block (was `cornball.sequence.v1`). `read_sequence`/`write_sequence` and
  `sequence_to_json`/`sequence_from_json` go through OTIO's serializer. Old
  `cornball.sequence.v1` files no longer load.
* New OTIO object API exposed: `otio_external_reference()`, `otio_target_url()`,
  `otio_set_target_url()`, `otio_set_name()`, `otio_set_kind()`.
* Codegen extended: `tools/otio_codegen.R` now emits trivial constructors and
  scalar setters (in addition to getters), each validated against the headers
  via treesitR. The gap-model rebuild/materialize is bespoke and hand-written.
* `R/json.R` and `R/coords.R` removed (OTIO owns serialization; coordinate
  transforms return with effects). `inst/schema/TIMELINE_SCHEMA.md` rewritten
  to describe the carrier and point at the OTIO docs.

## Deferred to PR 4

* `clip_speed`, `clip_transform`, `clip_crop`, `clip_set`, and `clip_add`'s
  `speed != 1` error with a pointer to PR 4; they migrate to OTIO Effects /
  `LinearTimeWarp` / per-clip metadata.

# nle.api 0.0.2.2 (dev)

## Changes

* OTIO migration PR 2: wrap the OpenTimelineIO object model. Adds C++ bindings
  for Timeline, Track, Clip, and ExternalReference, with construction,
  population (`otio_add_track`, `otio_add_clip`, `otio_remove_clip`), data.frame
  views (`otio_tracks`, `otio_clips`), and JSON (de)serialization through OTIO's
  own serializer (`otio_to_json` / `otio_from_json`). A timeline can be built,
  serialized to canonical `.otio` JSON, and parsed back entirely through the
  wrapped C++ — no R-side schema code in the data path.
* Objects use OTIO's intrusive ref-counting (`SerializableObject::Retainer`)
  held through `Rcpp::XPtr`; OTIO objects are never `delete`d directly.
* Header-driven codegen: `tools/otio_introspect.R` parses the OTIO C++ headers
  with treesitR to extract each class's API; `tools/otio_codegen.R` validates a
  binding manifest against those headers and emits the trivial scalar field
  getters (`src/otio_gen.cpp`). The lifetime-sensitive code is hand-written.
* The pure-R `rational_time()`/`new_sequence()` model and `otio_time()` are
  unchanged. The user-facing verb layer migrates onto these objects in PR 3.

# nle.api 0.0.2.1 (dev)

## Changes

* Begin the OpenTimelineIO migration (PLAN.md, PR 1: build chain). nle.api now
  links the C++ OpenTimelineIO library through Rcpp. OTIO is built from source
  and installed under `/usr/local` (it is not packaged for apt and ships no
  pkg-config file); `src/Makevars` hard-codes the include and link paths.
* Add `otio_time()`, an OTIO-backed time value wrapping
  `opentime::RationalTime` as an external pointer, with `otio_value()`,
  `otio_rate()`, `otio_to_seconds()`, `otio_to_frames()`, `otio_rescaled_to()`,
  and `otio_timecode()`. All conversions are computed by the OTIO library
  rather than reimplemented in R. `otio_version()` reports the linked version.
* The pure-R `rational_time()` and the existing sequence model are unchanged;
  `otio_time()` is additive. The data model migrates onto the C++ objects in
  later PRs (Timeline/Clip in PR 2).

## Dependencies

* New `Imports: Rcpp` and `LinkingTo: Rcpp`.
* New `SystemRequirements`: C++17 and libopentimelineio (>= 0.17), built from
  source. See PLAN.md for the recipe.
