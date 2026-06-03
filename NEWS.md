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
