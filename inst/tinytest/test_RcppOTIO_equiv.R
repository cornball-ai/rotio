# Emitted JSON is accepted by the real OpenTimelineIO library (via RcppOTIO).
# Suggests-gated and local-only: RcppOTIO carries compiled libopentimelineio and
# is not present during a portable R CMD check.

if (requireNamespace("RcppOTIO", quietly = TRUE)) {

    tl <- Timeline("demo")
    metadata(tl) <- list(cornball = list(preset = "shorts"))
    ref <- ExternalReference("media/chunk01.mp4")
    metadata(ref) <- list(cornball = list(backend = "wan2gp_api"))
    clip <- Clip("chunk01", ref,
                 source_range = TimeRange(RationalTime(0, 30), RationalTime(180, 30)))
    v <- add_child(Track("V1", kind = "Video"), clip)
    cc <- Clip("cap01", MissingReference(),
               source_range = TimeRange(RationalTime(0, 30), RationalTime(180, 30)))
    metadata(cc) <- list(cornball = list(kind = "caption", text = "hello"))
    cap <- add_child(Track("captions", kind = "Video"), cc)
    tl <- add_track(add_track(tl, v), cap)

    # RcppOTIO parses our JSON without error.
    obj <- RcppOTIO::from_json_string(to_json_string(tl))

    # Build the equivalent timeline natively in RcppOTIO; the normalized JSON of
    # our-parsed-by-RcppOTIO matches RcppOTIO's own.
    rtl <- RcppOTIO::Timeline("demo")
    RcppOTIO::metadata(rtl) <- list(cornball = list(preset = "shorts"))
    rv <- RcppOTIO::Track("V1", kind = "Video")
    rref <- RcppOTIO::ExternalReference("media/chunk01.mp4")
    RcppOTIO::metadata(rref) <- list(cornball = list(backend = "wan2gp_api"))
    rclip <- RcppOTIO::Clip("chunk01", rref,
                         source_range = RcppOTIO::TimeRange(RcppOTIO::RationalTime(0, 30),
                                                         RcppOTIO::RationalTime(180, 30)))
    RcppOTIO::append_child(rv, rclip)
    rcc <- RcppOTIO::Clip("cap01", RcppOTIO::MissingReference(),
                       source_range = RcppOTIO::TimeRange(RcppOTIO::RationalTime(0, 30),
                                                       RcppOTIO::RationalTime(180, 30)))
    RcppOTIO::metadata(rcc) <- list(cornball = list(kind = "caption", text = "hello"))
    rcap <- RcppOTIO::Track("captions", kind = "Video")
    RcppOTIO::append_child(rcap, rcc)
    RcppOTIO::append_child(RcppOTIO::tracks(rtl), rv)
    RcppOTIO::append_child(RcppOTIO::tracks(rtl), rcap)

    expect_identical(RcppOTIO::to_json_string(obj), RcppOTIO::to_json_string(rtl))

    # validate_with_RcppOTIO reports valid.
    expect_equal(validate_with_RcppOTIO(tl)$status, "valid")
}
