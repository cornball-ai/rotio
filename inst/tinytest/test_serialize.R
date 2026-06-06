# Serialization round-trips and emits the right JSON shapes.

build_demo <- function() {
    tl <- Timeline("demo")
    metadata(tl) <- list(cornball = list(preset = "shorts"))
    v <- Track("V1", kind = "Video")
    ref <- ExternalReference("media/chunk01.mp4")
    metadata(ref) <- list(cornball = list(backend = "wan2gp_api"))
    clip <- Clip("chunk01", ref,
                 source_range = TimeRange(RationalTime(0, 30), RationalTime(180, 30)))
    v <- add_child(v, clip)
    cc <- Clip("cap01", MissingReference(),
               source_range = TimeRange(RationalTime(0, 30), RationalTime(180, 30)))
    metadata(cc) <- list(cornball = list(kind = "caption", text = "hello"))
    cap <- add_child(Track("captions", kind = "Video"), cc)
    tl <- add_track(tl, v)
    tl <- add_track(tl, cap)
    tl
}

tl <- build_demo()
js <- to_json_string(tl)

# Empty metadata is an object, arrays are arrays, nulls are null.
expect_true(grepl('"metadata": \\{', js))
expect_true(grepl('"effects": \\[', js))
expect_true(grepl('"global_start_time": null', js))
expect_true(grepl('"OTIO_SCHEMA": "Timeline.1"', js, fixed = TRUE))
expect_true(grepl('"OTIO_SCHEMA": "Clip.2"', js, fixed = TRUE))
expect_true(grepl('"active_media_reference_key": "DEFAULT_MEDIA"', js, fixed = TRUE))

# Round-trip through our own parser.
tl2 <- from_json_string(js)
expect_true(is_timeline(tl2))
expect_equal(name(tl2), "demo")
expect_equal(metadata(tl2)$cornball$preset, "shorts")
expect_equal(length(children(tracks(tl2))), 2L)
v <- children(tracks(tl2))[[1]]
expect_equal(kind(v), "Video")
clip <- children(v)[[1]]
expect_equal(target_url(clip), "media/chunk01.mp4")
expect_equal(value(duration(source_range(clip))), 180)

# Re-serializing the parsed tree reproduces the JSON byte-for-byte.
expect_identical(to_json_string(tl2), js)

# File round-trip.
tmp <- tempfile(fileext = ".otio")
to_json_file(tl, tmp)
expect_equal(name(from_json_file(tmp)), "demo")
unlink(tmp)
