# Plan: nle.api as full pure-R OpenTimelineIO

**Status: proposed (pre-Phase-1, for review).** Supersedes the "rotiolite"
(minimal subset) framing.

## Goal

nle.api becomes a **complete pure-R reimplementation of OpenTimelineIO** — every
function `rotio` exports, including the hard ones (the composition coordinate
model and the edit algorithms). No compiled code; `Imports: jsonlite` only.
`rotio` (the Rcpp/libopentimelineio binding) is retained as the **oracle** for
parity tests, in `Suggests`.

"Are we missing functions?" stops being a question: the target is 100% of
rotio's surface. See `OTIO_PARITY.md` for the function-by-function matrix
(35 done, 88 to build, 14 nle.api-only extras).

## Why this reverses the functional/value-semantics design

The hard parts need a real object graph:
- `range_in_parent` / `trimmed_range_in_parent` need a child to know its parent
  and siblings.
- The edit algorithms (`overwrite`, `insert`, `trim`, `slice`, `slip`, `slide`,
  `ripple`, `roll`, `fill`, `remove`) mutate a composition in place.
- `clone`, `parent`, single-parent enforcement are core OTIO semantics.

Value-semantics lists with no back-pointers can't model this cleanly, so the
core moves to an **environment-backed, reference-semantics** object model that
mirrors rotio's API. The target is **rotio API parity**, not a promise of
byte-for-byte interchange: once parity is proven, cornductor's low-level OTIO
construction/writing should become backend-swappable between rotio and pure-R
nle.api with minimal adapter code. The functional builders stay as compatibility
sugar so licuadora (which already targets them) keeps working.

(Cornductor remains the AI/project conductor — TTS/STT/XTX orchestration, asset
provenance, OTIOD layout, chunking, captions, render handoff. Parity only makes
its OTIO backend layer swappable; cornductor's purpose does not move into nle.api.)

## Object contract (binding; implement to this)

Each OTIO object is an **environment** with an S3 class
(`c("<Type>", <bases…>, "otio_object")`). Fields as today (`OTIO_SCHEMA`, `name`,
`metadata`, type fields), plus one internal binding `.parent`.

1. **Parent pointer is internal and never serialized.** `.parent` points to the
   containing composition/collection where OTIO exposes one, else `NULL`. A
   Timeline's root track Stack is parentless — `parent(tracks(tl))` is `NULL`
   (verified against rotio) — while tracks appended to that Stack have the Stack
   as their parent. `.parent` is stripped before JSON and excluded from equality.
2. **Tree mutation maintains parent pointers.** `append_child` / `insert_child` /
   `set_child` / `set_children` attach the child and set its `.parent` to the
   composition (in place). `remove_child` / `clear_children` detach and reset the
   removed child's `.parent` to `NULL`.
3. **Single-parent invariant.** Attaching a child whose `.parent` is non-`NULL`
   **errors** ("child already has a parent"), matching rotio/OTIO (verified
   against rotio). Moving a child means `remove_child` first (or a documented
   move helper that detaches then attaches).
4. **`clone(x)` is deep.** Returns a deep copy of the subtree; the returned
   root's `.parent` is `NULL`; every cloned descendant's `.parent` points to its
   cloned container (internally consistent, fully detached from the original).
   Verified: rotio resets the clone root's parent to `NULL`.
5. **JSON parse reconstructs parent pointers.** `from_json_string` / `_file`
   rebuild the tree and wire every child's `.parent` top-down, so a parsed tree
   satisfies the same invariants as a built one. Serialized output is unchanged
   (byte-compatible with rotio, `.parent` stripped).
6. **Functional sugar is values-on-top.** `add_child(x, child)` =
   `append_child(clone(x), clone(child))` returning the new parent;
   `add_track` likewise. Inputs untouched, so value-semantics callers keep
   working.
7. **Parity is judged externally, not by representation.** Equality/parity tests
   compare (a) normalized serialized OTIO JSON (round-tripped through rotio) and
   (b) selected behavioral queries (`range_in_parent`, `trimmed_range`,
   `find_clips`, `duration`, edit-algorithm results) against rotio on a fixture
   battery. Internal pointers and R representation are never compared.

## Phases (each validated against rotio before merge)

- **Phase 1 — env-backed core + tree ops.** Re-base objects on environments with
  `.parent`; `clone`, `append_child`/`insert_child`/`set_child`/`set_children`/
  `remove_child`/`clear_children`, `parent`, `has_child`/`has_clips`/
  `is_parent_of`/`index_of_child`, `color`, media-ref keys
  (`media_references`/`set_media_references`/`active_media_reference_key`/
  `default_media_key`), `SerializableCollection`. Keep serialize/parse (now
  parent-aware) and the functional sugar. **licuadora unaffected.**
  **Gate tests (must pass to merge Phase 1):** appending an already-parented
  child errors; `remove_child`/`clear_children` detach (child `.parent` -> `NULL`);
  `set_child` detaches the replaced child and attaches the new one; `clone` root
  `.parent` is `NULL` and cloned descendants point inside the clone; JSON parse
  rewires `.parent`; `parent(tracks(tl))` is `NULL` while appended tracks have the
  Stack as parent; functional `add_child()`/`add_track()` leave inputs untouched.
- **Phase 2 — time model.** `almost_equal`, `clamped`, `contains`, `intersects`,
  `extended_by`, `overlaps`, `end_time_inclusive`/`exclusive`, `to_timecode`/
  `from_timecode`, `to_time_string`/`from_time_string`, `frame_for_time`,
  `range_from_start_end_time`, `TimeTransform`.
- **Phase 3 — full object surface.** `GeneratorReference`,
  `ImageSequenceReference` (+ its fields), `MediaReference`, `is_missing_reference`,
  `available_range`/`<-`, `Marker` (+ `marked_range`/`color`/`comment`),
  `Transition` (+ `transition_type`/`in_offset`/`out_offset`), `TimeEffect`,
  `FreezeFrame`, `parameters`, `visible`.
- **Phase 4 — composition coordinate model.** `range_in_parent`, `trimmed_range`,
  `trimmed_range_in_parent`, `visible_range`, item `available_range`,
  `find_clips`, `flatten_stack`, `video_tracks`/`audio_tracks`,
  `global_start_time`, `is_equivalent_to`, `track_trimmed_to_range`.
- **Phase 5 — edit algorithms.** `overwrite`, `insert`, `trim`, `slice`, `slip`,
  `slide`, `ripple`, `roll`, `fill`, `remove`. Each diffed against rotio on a
  fixture battery (this is where OTIO's subtlety lives — highest test density).
- **Phase 6 — schema machinery.** `schema_name`, `schema_version`,
  `is_unknown_schema`, `register_upgrade_function`/`register_downgrade_function`,
  `type_version_map`.

## Validation strategy

- `rotio` as oracle, `Suggests`-gated and `at_home()`/`requireNamespace`-guarded
  so a portable `R CMD check` (no rotio) still passes.
- For every ported function: build the same object in nle.api and rotio, assert
  (a) the oracle round-trip matches —
  `rotio::to_json_string(rotio::from_json_string(nle.api::to_json_string(x)))`
  equals `rotio::to_json_string(rotio_native)` (rotio cannot serialize a pure-R
  nle.api object directly, so our JSON is parsed by rotio first) — and
  (b) behavioral queries match. Algorithm phases get a broad case battery
  (gaps, transitions, fill templates, boundaries, ripple across tracks).
- Keep `R CMD check` at 0 errors / 0 warnings throughout.

## Blast radius / coexistence

- **licuadora**: targets the functional sugar (`add_child`/`add_track`/
  `enabled<-`); kept as wrappers over the reference core, so it does not break.
  It can later adopt mutable `append_child` if desired, but isn't forced to.
- **cornductor**: stays the AI/project conductor. Full parity makes its
  low-level OTIO construction/writing layer backend-swappable between rotio and
  pure-R nle.api (ideally minimal adapter code) once parity is proven — not a
  promise of literal sed-level replacement up front.
- **"rotiolite" naming** is retired; nle.api is full pure-R OTIO. The Title/
  Description and memory notes update accordingly.

## Open question

- Effort is large (porting `opentime` + `opentimelineio` + `editAlgorithm`). One
  PR per phase, in order, since each builds on the last.
