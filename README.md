# rotio

A pure-R [OpenTimelineIO](https://github.com/AcademySoftwareFoundation/OpenTimelineIO)
(OTIO) document model. Constructors for the OTIO object model (`Timeline`,
`Track`, `Clip`, `Gap`, media references, `RationalTime`, `TimeRange`),
functional builders that return new objects, the edit algorithms
(`overwrite`, `insert`, `trim`, `slice`, `slip`, `slide`, `ripple`, `roll`,
`fill`, `remove`), schema upgrade/downgrade hooks, and readers and writers
for canonical `.otio` JSON through jsonlite. Directory bundles
(`content.otio` + `media/`) are covered by `read_otiod()` / `write_otiod()`.

No compiled code. The only hard dependency is jsonlite.

## Relationship to RcppOTIO

[RcppOTIO](https://github.com/cornball-ai/RcppOTIO) wraps the OTIO C++
library itself (Rcpp over libopentimelineio). rotio is the lightweight
sibling: same object model and naming, implemented entirely in R.

rotio lists RcppOTIO in Suggests as a **validation oracle**: the parity
tests serialize rotio's output through real libopentimelineio and check the
JSON and edit-algorithm behavior match the reference implementation. The
oracle is optional. Without RcppOTIO installed, the full test suite still
passes and the parity tests skip, so rotio runs anywhere R runs, no C++
toolchain needed.

Parity testing these packages against libopentimelineio is what surfaced
[OpenTimelineIO#2025](https://github.com/AcademySoftwareFoundation/OpenTimelineIO/pull/2025),
an upstream edit-algorithm fix.

## Install

```r
remotes::install_github("cornball-ai/rotio")
```

The optional oracle (needs the OpenTimelineIO C++ library >= 0.18 and Imath
headers installed):

```r
install.packages("RcppOTIO", repos = c(
  "https://cornball-ai.github.io/drat",
  "https://cloud.r-project.org"
))
```

## Example

```r
library(rotio)

ref  <- ExternalReference("shot.mov")
clip <- Clip("shot", ref,
             source_range = TimeRange(RationalTime(0, 24), RationalTime(48, 24)))
trk  <- add_child(Track("V1", kind = "Video"), clip)
tl   <- add_track(Timeline("my timeline"), trk)

find_clips(tl)            # list of clips, recursively
js  <- to_json_string(tl) # canonical OTIO JSON
tl2 <- from_json_string(js)
```

With RcppOTIO installed, `validate_with_RcppOTIO(tl)` round-trips the JSON
through libopentimelineio to confirm real OTIO accepts it.

## License

Apache License 2.0, matching upstream OpenTimelineIO.
