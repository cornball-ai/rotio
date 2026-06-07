# Phase 3: media-ref subtypes, Marker, Transition, TimeEffect/FreezeFrame.

# construction + predicates
expect_equal(MediaReference("m")$OTIO_SCHEMA, "MediaReference.1")
expect_true(is_media_reference(GeneratorReference("g", "SMPTEBars")))
expect_true(is_media_reference(ImageSequenceReference("file:///s/")))
expect_true(is_missing_reference(MissingReference()))
expect_false(is_missing_reference(ExternalReference("a.mp4")))
expect_true(is_effect(FreezeFrame("f")))
expect_true(inherits(FreezeFrame("f"), "LinearTimeWarp"))
expect_equal(time_scalar(FreezeFrame("f")), 0)

# accessors round-trip
g <- GeneratorReference("g", "SMPTEBars")
generator_kind(g) <- "SMPTEColorBars"
expect_equal(generator_kind(g), "SMPTEColorBars")
parameters(g) <- list(foo = "bar")
expect_equal(parameters(g)$foo, "bar")

mk <- Marker("m", TimeRange(RationalTime(0, 24), RationalTime(5, 24)), "RED", "note")
expect_equal(color(mk), "RED")
expect_equal(comment(mk), "note")
expect_equal(value(duration(marked_range(mk))), 5)

tn <- Transition("t", "SMPTE_Dissolve", RationalTime(5, 24), RationalTime(5, 24))
expect_equal(transition_type(tn), "SMPTE_Dissolve")
expect_equal(value(in_offset(tn)), 5)
# Transition is composable (can be a track child)
trk <- append_child(Track("V1"), tn)
expect_equal(length(children(trk)), 1L)

# ImageSequenceReference computed methods (1-based image numbers)
isr <- ImageSequenceReference("file:///seq/", "frame.", ".exr", start_frame = 1L,
                              frame_step = 1L, rate = 24, frame_zero_padding = 4L,
                              available_range = TimeRange(RationalTime(0, 24),
                                                          RationalTime(48, 24)))
expect_equal(number_of_images_in_sequence(isr), 48L)
expect_equal(end_frame(isr), 48L)
expect_equal(target_url_for_image_number(isr, 0), "file:///seq/frame.0000.exr")
expect_equal(target_url_for_image_number(isr, 2), "file:///seq/frame.0002.exr")
expect_equal(value(presentation_time_for_image_number(isr, 2)), 1)

# round-trip through our own parser
expect_true(inherits(from_json_string(to_json_string(isr)), "ImageSequenceReference"))
expect_equal(transition_type(from_json_string(to_json_string(tn))), "SMPTE_Dissolve")

# ---- RcppOTIO JSON + behavior parity ----
if (requireNamespace("RcppOTIO", quietly = TRUE)) {
    norm <- function(x) RcppOTIO::to_json_string(RcppOTIO::from_json_string(to_json_string(x)))

    expect_identical(norm(MediaReference("m")),
                     RcppOTIO::to_json_string(RcppOTIO::MediaReference("m")))
    expect_identical(
        norm(Marker("m", TimeRange(RationalTime(0, 24), RationalTime(5, 24)), "RED", "note")),
        RcppOTIO::to_json_string(RcppOTIO::Marker("m",
            RcppOTIO::TimeRange(RcppOTIO::RationalTime(0, 24), RcppOTIO::RationalTime(5, 24)),
            "RED", "note")))
    expect_identical(
        norm(Transition("t", "SMPTE_Dissolve", RationalTime(5, 24), RationalTime(5, 24))),
        RcppOTIO::to_json_string(RcppOTIO::Transition("t", "SMPTE_Dissolve",
            RcppOTIO::RationalTime(5, 24), RcppOTIO::RationalTime(5, 24))))
    expect_identical(
        norm(GeneratorReference("g", "SMPTEBars",
            TimeRange(RationalTime(0, 24), RationalTime(10, 24)), list(foo = "bar"))),
        RcppOTIO::to_json_string(RcppOTIO::GeneratorReference("g", "SMPTEBars",
            RcppOTIO::TimeRange(RcppOTIO::RationalTime(0, 24), RcppOTIO::RationalTime(10, 24)),
            list(foo = "bar"))))
    expect_identical(norm(FreezeFrame("f")),
                     RcppOTIO::to_json_string(RcppOTIO::FreezeFrame("f")))
    expect_identical(norm(TimeEffect("te", "SomeWarp")),
                     RcppOTIO::to_json_string(RcppOTIO::TimeEffect("te", "SomeWarp")))

    risr <- RcppOTIO::ImageSequenceReference(target_url_base = "file:///seq/",
        name_prefix = "frame.", name_suffix = ".exr", start_frame = 1L,
        frame_step = 1L, rate = 24, frame_zero_padding = 4L,
        available_range = RcppOTIO::TimeRange(RcppOTIO::RationalTime(0, 24),
                                           RcppOTIO::RationalTime(48, 24)))
    expect_identical(norm(isr), RcppOTIO::to_json_string(risr))
    expect_equal(number_of_images_in_sequence(isr), RcppOTIO::number_of_images_in_sequence(risr))
    expect_equal(end_frame(isr), RcppOTIO::end_frame(risr))
    for (n in c(0, 1, 2, 5)) {
        expect_equal(target_url_for_image_number(isr, n),
                     RcppOTIO::target_url_for_image_number(risr, n), info = paste("url", n))
        expect_equal(value(presentation_time_for_image_number(isr, n)),
                     unname(RcppOTIO::presentation_time_for_image_number(risr, n)[["value"]]),
                     info = paste("ptime", n))
    }

    misr <- function(con, s, st, pad, dur) con(target_url_base = "b/", name_prefix = "f",
        name_suffix = ".png", start_frame = s, frame_step = st, rate = 24,
        frame_zero_padding = pad, available_range = if (is.null(dur)) NULL else
            (if (identical(con, ImageSequenceReference))
                TimeRange(RationalTime(0, 24), RationalTime(dur, 24))
             else RcppOTIO::TimeRange(RcppOTIO::RationalTime(0, 24), RcppOTIO::RationalTime(dur, 24))))

    # end_frame: step > 1 and no available_range
    expect_equal(end_frame(misr(ImageSequenceReference, 100L, 2L, 4L, 10)),
                 RcppOTIO::end_frame(misr(RcppOTIO::ImageSequenceReference, 100L, 2L, 4L, 10)))   # 109
    expect_equal(end_frame(misr(ImageSequenceReference, 1L, 1L, 4L, NULL)),
                 RcppOTIO::end_frame(misr(RcppOTIO::ImageSequenceReference, 1L, 1L, 4L, NULL)))   # 1

    # out-of-range image numbers error
    expect_error(target_url_for_image_number(isr, 49))
    expect_error(presentation_time_for_image_number(isr, 49))

    # frame_zero_padding = 0 -> no padding
    expect_equal(target_url_for_image_number(misr(ImageSequenceReference, 5L, 1L, 0L, 3), 1),
                 RcppOTIO::target_url_for_image_number(misr(RcppOTIO::ImageSequenceReference, 5L, 1L, 0L, 3), 1))

    # frame_for_time parity (in range) + out-of-range errors
    for (tv in c(0, 2, 10, 24, 47)) {
        expect_equal(frame_for_time(isr, RationalTime(tv, 24)),
                     RcppOTIO::frame_for_time(risr, RcppOTIO::RationalTime(tv, 24)),
                     info = paste("fft", tv))
    }
    expect_error(frame_for_time(isr, RationalTime(-1, 24)))
    expect_error(frame_for_time(isr, RationalTime(48, 24)))

    # end_frame when duration is not divisible by frame_step
    expect_equal(end_frame(misr(ImageSequenceReference, 100L, 3L, 4L, 10)),
                 RcppOTIO::end_frame(misr(RcppOTIO::ImageSequenceReference, 100L, 3L, 4L, 10)))   # 109

    # negative image numbers extrapolate (no error), matching RcppOTIO
    expect_equal(target_url_for_image_number(isr, -1),
                 RcppOTIO::target_url_for_image_number(risr, -1))
    expect_equal(value(presentation_time_for_image_number(isr, -1)),
                 unname(RcppOTIO::presentation_time_for_image_number(risr, -1)[["value"]]))
}

# ---- phase 3 source review fixes ----
isr_s2 <- ImageSequenceReference("file:///b/", "f", ".png", start_frame = 1L,
    frame_step = 2L, rate = 24, frame_zero_padding = 4L,
    available_range = TimeRange(RationalTime(0, 24), RationalTime(20, 24)))
expect_equal(frame_for_time(isr_s2, RationalTime(3, 24)), 4L)   # no frame_step quantization
expect_equal(frame_for_time(isr_s2, RationalTime(4, 24)), 5L)
isr_ns <- ImageSequenceReference("file:///path", "img.", ".exr", start_frame = 1L,
    frame_step = 1L, rate = 24, frame_zero_padding = 0L,
    available_range = TimeRange(RationalTime(0, 24), RationalTime(5, 24)))
expect_equal(target_url_for_image_number(isr_ns, 1), "file:///path/img.1.exr")  # auto separator
trk_lt <- Track("V")
append_child(trk_lt, Transition("T", "SMPTE_Dissolve", RationalTime(2, 24), RationalTime(3, 24)))
append_child(trk_lt, Clip("B", ExternalReference("b.mov"), source_range = TimeRange(RationalTime(0, 24), RationalTime(10, 24))))
expect_equal(value(duration(available_range(trk_lt))), 12)   # leading transition in_offset
expect_equal(value(duration(Transition("T", "SMPTE_Dissolve", RationalTime(2, 24), RationalTime(3, 24)))), 5)
if (requireNamespace("RcppOTIO", quietly = TRUE)) {
    risr_s2 <- RcppOTIO::ImageSequenceReference("file:///b/", "f", ".png", start_frame = 1L,
        frame_step = 2L, rate = 24, frame_zero_padding = 4L,
        available_range = RcppOTIO::TimeRange(RcppOTIO::RationalTime(0, 24), RcppOTIO::RationalTime(20, 24)))
    expect_equal(frame_for_time(isr_s2, RationalTime(3, 24)), RcppOTIO::frame_for_time(risr_s2, RcppOTIO::RationalTime(3, 24)))
    rtrk_lt <- RcppOTIO::Track("V")
    RcppOTIO::append_child(rtrk_lt, RcppOTIO::Transition("T", "SMPTE_Dissolve", RcppOTIO::RationalTime(2, 24), RcppOTIO::RationalTime(3, 24)))
    RcppOTIO::append_child(rtrk_lt, RcppOTIO::Clip("B", RcppOTIO::ExternalReference("b.mov"), source_range = RcppOTIO::TimeRange(RcppOTIO::RationalTime(0, 24), RcppOTIO::RationalTime(10, 24))))
    expect_equal(value(duration(available_range(trk_lt))), unname(RcppOTIO::available_range(rtrk_lt)$duration[["value"]]))
}
