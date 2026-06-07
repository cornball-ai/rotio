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

# ---- rotio JSON + behavior parity ----
if (requireNamespace("rotio", quietly = TRUE)) {
    norm <- function(x) rotio::to_json_string(rotio::from_json_string(to_json_string(x)))

    expect_identical(norm(MediaReference("m")),
                     rotio::to_json_string(rotio::MediaReference("m")))
    expect_identical(
        norm(Marker("m", TimeRange(RationalTime(0, 24), RationalTime(5, 24)), "RED", "note")),
        rotio::to_json_string(rotio::Marker("m",
            rotio::TimeRange(rotio::RationalTime(0, 24), rotio::RationalTime(5, 24)),
            "RED", "note")))
    expect_identical(
        norm(Transition("t", "SMPTE_Dissolve", RationalTime(5, 24), RationalTime(5, 24))),
        rotio::to_json_string(rotio::Transition("t", "SMPTE_Dissolve",
            rotio::RationalTime(5, 24), rotio::RationalTime(5, 24))))
    expect_identical(
        norm(GeneratorReference("g", "SMPTEBars",
            TimeRange(RationalTime(0, 24), RationalTime(10, 24)), list(foo = "bar"))),
        rotio::to_json_string(rotio::GeneratorReference("g", "SMPTEBars",
            rotio::TimeRange(rotio::RationalTime(0, 24), rotio::RationalTime(10, 24)),
            list(foo = "bar"))))
    expect_identical(norm(FreezeFrame("f")),
                     rotio::to_json_string(rotio::FreezeFrame("f")))
    expect_identical(norm(TimeEffect("te", "SomeWarp")),
                     rotio::to_json_string(rotio::TimeEffect("te", "SomeWarp")))

    risr <- rotio::ImageSequenceReference(target_url_base = "file:///seq/",
        name_prefix = "frame.", name_suffix = ".exr", start_frame = 1L,
        frame_step = 1L, rate = 24, frame_zero_padding = 4L,
        available_range = rotio::TimeRange(rotio::RationalTime(0, 24),
                                           rotio::RationalTime(48, 24)))
    expect_identical(norm(isr), rotio::to_json_string(risr))
    expect_equal(number_of_images_in_sequence(isr), rotio::number_of_images_in_sequence(risr))
    expect_equal(end_frame(isr), rotio::end_frame(risr))
    for (n in c(0, 1, 2, 5)) {
        expect_equal(target_url_for_image_number(isr, n),
                     rotio::target_url_for_image_number(risr, n), info = paste("url", n))
        expect_equal(value(presentation_time_for_image_number(isr, n)),
                     unname(rotio::presentation_time_for_image_number(risr, n)[["value"]]),
                     info = paste("ptime", n))
    }

    misr <- function(con, s, st, pad, dur) con(target_url_base = "b/", name_prefix = "f",
        name_suffix = ".png", start_frame = s, frame_step = st, rate = 24,
        frame_zero_padding = pad, available_range = if (is.null(dur)) NULL else
            (if (identical(con, ImageSequenceReference))
                TimeRange(RationalTime(0, 24), RationalTime(dur, 24))
             else rotio::TimeRange(rotio::RationalTime(0, 24), rotio::RationalTime(dur, 24))))

    # end_frame: step > 1 and no available_range
    expect_equal(end_frame(misr(ImageSequenceReference, 100L, 2L, 4L, 10)),
                 rotio::end_frame(misr(rotio::ImageSequenceReference, 100L, 2L, 4L, 10)))   # 109
    expect_equal(end_frame(misr(ImageSequenceReference, 1L, 1L, 4L, NULL)),
                 rotio::end_frame(misr(rotio::ImageSequenceReference, 1L, 1L, 4L, NULL)))   # 1

    # out-of-range image numbers error
    expect_error(target_url_for_image_number(isr, 49))
    expect_error(presentation_time_for_image_number(isr, 49))

    # frame_zero_padding = 0 -> no padding
    expect_equal(target_url_for_image_number(misr(ImageSequenceReference, 5L, 1L, 0L, 3), 1),
                 rotio::target_url_for_image_number(misr(rotio::ImageSequenceReference, 5L, 1L, 0L, 3), 1))

    # frame_for_time parity (in range) + out-of-range errors
    for (tv in c(0, 2, 10, 24, 47)) {
        expect_equal(frame_for_time(isr, RationalTime(tv, 24)),
                     rotio::frame_for_time(risr, rotio::RationalTime(tv, 24)),
                     info = paste("fft", tv))
    }
    expect_error(frame_for_time(isr, RationalTime(-1, 24)))
    expect_error(frame_for_time(isr, RationalTime(48, 24)))

    # end_frame when duration is not divisible by frame_step
    expect_equal(end_frame(misr(ImageSequenceReference, 100L, 3L, 4L, 10)),
                 rotio::end_frame(misr(rotio::ImageSequenceReference, 100L, 3L, 4L, 10)))   # 109

    # negative image numbers extrapolate (no error), matching rotio
    expect_equal(target_url_for_image_number(isr, -1),
                 rotio::target_url_for_image_number(risr, -1))
    expect_equal(value(presentation_time_for_image_number(isr, -1)),
                 unname(rotio::presentation_time_for_image_number(risr, -1)[["value"]]))
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
if (requireNamespace("rotio", quietly = TRUE)) {
    risr_s2 <- rotio::ImageSequenceReference("file:///b/", "f", ".png", start_frame = 1L,
        frame_step = 2L, rate = 24, frame_zero_padding = 4L,
        available_range = rotio::TimeRange(rotio::RationalTime(0, 24), rotio::RationalTime(20, 24)))
    expect_equal(frame_for_time(isr_s2, RationalTime(3, 24)), rotio::frame_for_time(risr_s2, rotio::RationalTime(3, 24)))
    rtrk_lt <- rotio::Track("V")
    rotio::append_child(rtrk_lt, rotio::Transition("T", "SMPTE_Dissolve", rotio::RationalTime(2, 24), rotio::RationalTime(3, 24)))
    rotio::append_child(rtrk_lt, rotio::Clip("B", rotio::ExternalReference("b.mov"), source_range = rotio::TimeRange(rotio::RationalTime(0, 24), rotio::RationalTime(10, 24))))
    expect_equal(value(duration(available_range(trk_lt))), unname(rotio::available_range(rtrk_lt)$duration[["value"]]))
}
