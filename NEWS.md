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
  transforms return with effects). `inst/schema/SEQUENCE_SCHEMA.md` rewritten
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
