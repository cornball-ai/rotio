# Tests for the OpenTimelineIO object model wrap (Timeline/Track/Clip) and
# JSON round-trip through the linked C++ library.

library(nle.api)

# Build a 3-clip video track in a timeline.
tl <- otio_timeline("demo")
expect_true(inherits(tl, "otio_timeline"))
expect_equal(otio_name(tl), "demo")

v1 <- otio_track("v1", "Video")
expect_equal(otio_kind(v1), "Video")
otio_add_track(tl, v1)

otio_add_clip(v1, otio_clip("a", "a.mp4", start = 0, duration = 90, rate = 30))
otio_add_clip(v1, otio_clip("b", "b.mp4", start = 90, duration = 90, rate = 30))
otio_add_clip(v1, otio_clip("c", "c.mp4", start = 180, duration = 60, rate = 30))

# Track view.
tracks <- otio_tracks(tl)
expect_equal(nrow(tracks), 1L)
expect_equal(tracks$kind, "Video")
expect_equal(tracks$n_children, 3L)

# Clip view: names, urls, source ranges.
clips <- otio_clips(v1)
expect_equal(nrow(clips), 3L)
expect_equal(clips$name, c("a", "b", "c"))
expect_equal(clips$target_url, c("a.mp4", "b.mp4", "c.mp4"))
expect_equal(clips$kind, rep("Clip", 3))
expect_equal(clips$start, c(0, 90, 180))
expect_equal(clips$rate, rep(30, 3))
expect_equal(clips$duration, c(90, 90, 60))

# JSON serialization is canonical OTIO (per-object OTIO_SCHEMA).
js <- otio_to_json(tl)
expect_true(grepl("\"OTIO_SCHEMA\"", js))
expect_true(grepl("Timeline\\.[0-9]+", js))

# Round-trip: parse back and verify shape is preserved.
tl2 <- otio_from_json(js)
expect_equal(otio_name(tl2), "demo")
t2 <- otio_tracks(tl2)
expect_equal(nrow(t2), 1L)
expect_equal(t2$n_children, 3L)

# Remove a clip (1-based); the track shrinks.
otio_remove_clip(v1, 2L)
expect_equal(otio_clips(v1)$name, c("a", "c"))

# Out-of-range removal errors.
expect_error(otio_remove_clip(v1, 99L), "out of range")

# Audio track kind round-trips.
a1 <- otio_track("a1", "Audio")
expect_equal(otio_kind(a1), "Audio")
