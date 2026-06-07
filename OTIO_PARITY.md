# OTIO parity matrix (nle.api vs rotio)

Target: nle.api exports everything `rotio` does, in pure R. ✅ done · ⬜ to build.
Progress: Phases 1-6 complete and merged (env core, time model, object surface,
composition coordinate model, edit algorithms, schema machinery). Validated
against rotio; schema migrations mirror OTIO's typeRegistry. Replacement
functions (`x<-`) are grouped with their getter and flagged separately where the
getter exists but the setter doesn't yet. Plus nle.api-only extras (sugar /
OTIOD / predicates).

## Phase 1 — environment-backed object core + tree ops

| function | status |
|---|---|
| Timeline, Stack, Track, Clip, Gap | ✅ (re-base on env core) |
| ExternalReference, MissingReference | ✅ (re-base) |
| metadata/`<-`, name/`<-`, kind/`<-`, source_range/`<-`, enabled/`<-` | ✅ (incl. kind<-) |
| children, tracks/`<-`, target_url/`<-`, media_reference/`<-` | ✅ getters; `media_reference<-` ✅ |
| append_child | ✅ |
| insert_child | ✅ |
| remove_child | ✅ |
| set_child | ✅ |
| set_children/`<-` | ✅ |
| clear_children | ✅ |
| clone | ✅ |
| parent | ✅ |
| has_child | ✅ |
| has_clips | ✅ |
| is_parent_of | ✅ |
| index_of_child | ✅ |
| color/`<-` | ✅ |
| media_references | ✅ |
| set_media_references | ✅ |
| active_media_reference_key/`<-` | ✅ |
| default_media_key | ✅ |
| SerializableCollection | ✅ |

## Phase 2 — time model

| function | status |
|---|---|
| RationalTime, TimeRange | ✅ |
| value, rate, start_time, duration | ✅ |
| to_seconds, from_seconds, to_frames, from_frames, rescaled_to | ✅ |
| almost_equal | ✅ |
| clamped | ✅ |
| contains | ✅ |
| intersects | ✅ |
| extended_by | ✅ |
| overlaps | ✅ |  (overlapping is track-level -> Phase 4) |
| end_time_inclusive | ✅ |
| end_time_exclusive | ✅ |
| to_timecode, from_timecode | ✅ |
| to_time_string, from_time_string | ✅ |
| range_from_start_end_time | ✅ |
| TimeTransform | ✅ |

## Phase 3 — full object surface

| function | status |
|---|---|
| Effect, LinearTimeWarp, effect_name/`<-`, time_scalar/`<-` | ✅ |
| MediaReference | ✅ |
| GeneratorReference, generator_kind/`<-`, parameters/`<-` | ✅ |
| ImageSequenceReference | ✅ |
| target_url_base/`<-`, name_prefix, name_suffix | ✅ |
| start_frame, end_frame, frame_step, frame_zero_padding | ✅ |
| number_of_images_in_sequence | ✅ |
| presentation_time_for_image_number, target_url_for_image_number | ✅ |
| is_missing_reference | ✅ |
| available_range/`<-` (media ref) | ✅ |
| Marker, marked_range/`<-`, comment/`<-` | ✅ |
| Transition, transition_type/`<-`, in_offset/`<-`, out_offset/`<-` | ✅ |
| TimeEffect, FreezeFrame | ✅ |

## Phase 4 — composition coordinate model

| function | status |
|---|---|
| range_in_parent | ✅ |
| trimmed_range | ✅ |
| trimmed_range_in_parent | ✅ |
| visible_range | ✅ |
| available_range (item) | ✅ |
| find_clips | ✅ |
| flatten_stack | ✅ |
| video_tracks, audio_tracks | ✅ |
| frame_for_time | ✅ (ImageSequenceReference method) |
| overlapping (track-level) | ✅ |
| visible (track-level) | ✅ |
| global_start_time/`<-` | ✅ |
| is_equivalent_to | ✅ |
| track_trimmed_to_range | ✅ |

## Phase 5 — edit algorithms (highest test density vs rotio)

| function | status |
|---|---|
| overwrite | ✅ |
| insert | ✅ |
| trim | ✅ |
| slice | ✅ |
| slip | ✅ |
| slide | ✅ |
| ripple | ✅ |
| roll | ✅ |
| fill | ✅ |
| remove | ✅ |

## Phase 6 — schema machinery

| function | status |
|---|---|
| schema_name | ✅ |
| schema_version | ✅ |
| is_unknown_schema | ✅ |
| register_upgrade_function | ✅ |
| register_downgrade_function | ✅ |
| type_version_map | ✅ |

## Done already (serialization)

| function | status |
|---|---|
| to_json_string, to_json_file | ✅ |
| from_json_string, from_json_file | ✅ (becomes parent-aware in Phase 1) |

## nle.api-only extras (not in rotio; keep)

`add_child`, `add_track`, `add_effect`, `effects` (functional sugar) ·
`read_otiod`, `write_otiod` (OTIOD bundles) · `validate_with_rotio` (oracle) ·
predicates `is_otio`, `is_timeline`, `is_composition`, `is_media_reference`,
`is_effect`, `is_rational_time`, `is_time_range`.
