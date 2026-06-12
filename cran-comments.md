# cran-comments

## New submission

rotio 0.1.0 is a first submission: a pure-R OpenTimelineIO (OTIO) document
model, reader/writer, and edit-algorithm layer. The only hard dependency
is jsonlite.

## Suggested package not on CRAN: RcppOTIO

RcppOTIO appears in Suggests and is not on CRAN. It is strictly optional:
an Rcpp binding to the OpenTimelineIO C++ library, used only as a
validation oracle in parity tests that confirm rotio's JSON and
edit-algorithm behavior match the reference implementation.

* Every use is guarded with `requireNamespace("RcppOTIO", quietly = TRUE)`;
  all examples, tests, and functions run without it (verified: the full
  250-test suite passes with RcppOTIO absent from the library path).
* It is installable from the repository declared in
  `Additional_repositories` (https://cornball-ai.github.io/drat). It
  carries SystemRequirements (the OTIO C++ library and Imath headers),
  which is why it is distributed there rather than on CRAN.

## Test environments

* Ubuntu 24.04, R 4.6.x: 0 errors, 0 warnings, 0 notes
* Windows (local), R 4.4.3 (declared floor), R 4.6.0, R-devel: 1 note
  (new-submission incoming feasibility)
* win-builder R-devel

No reverse dependencies (first release).
