# Emitted JSON is accepted by the real OpenTimelineIO library (via rotio).
# Suggests-gated and local-only: rotio carries compiled libopentimelineio and
# is not present during a portable R CMD check.

if (requireNamespace("rotio", quietly = TRUE)) {

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

    # rotio parses our JSON without error.
    obj <- rotio::from_json_string(to_json_string(tl))

    # Build the equivalent timeline natively in rotio; the normalized JSON of
    # our-parsed-by-rotio matches rotio's own.
    rtl <- rotio::Timeline("demo")
    rotio::metadata(rtl) <- list(cornball = list(preset = "shorts"))
    rv <- rotio::Track("V1", kind = "Video")
    rref <- rotio::ExternalReference("media/chunk01.mp4")
    rotio::metadata(rref) <- list(cornball = list(backend = "wan2gp_api"))
    rclip <- rotio::Clip("chunk01", rref,
                         source_range = rotio::TimeRange(rotio::RationalTime(0, 30),
                                                         rotio::RationalTime(180, 30)))
    rotio::append_child(rv, rclip)
    rcc <- rotio::Clip("cap01", rotio::MissingReference(),
                       source_range = rotio::TimeRange(rotio::RationalTime(0, 30),
                                                       rotio::RationalTime(180, 30)))
    rotio::metadata(rcc) <- list(cornball = list(kind = "caption", text = "hello"))
    rcap <- rotio::Track("captions", kind = "Video")
    rotio::append_child(rcap, rcc)
    rotio::append_child(rotio::tracks(rtl), rv)
    rotio::append_child(rotio::tracks(rtl), rcap)

    expect_identical(rotio::to_json_string(obj), rotio::to_json_string(rtl))

    # validate_with_rotio reports valid.
    expect_equal(validate_with_rotio(tl)$status, "valid")
}
