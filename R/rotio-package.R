#' rotio: pure-R OpenTimelineIO document model
#'
#' A dependency-light ("rotiolite") OTIO document layer: pure-R constructors for
#' the OpenTimelineIO object model (Timeline, Track, Clip, Gap, media
#' references, RationalTime, TimeRange), functional builders that return new
#' objects, and JSON (de)serialization through \pkg{jsonlite} that emits
#' canonical \code{.otio}. The optional \pkg{RcppOTIO} package validates emitted
#' JSON against the real libopentimelineio. No compiled code.
#'
#' @keywords internal
"_PACKAGE"

