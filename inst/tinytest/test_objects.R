# Object construction, predicates, and functional builders.

ref <- ExternalReference("a.mp4")
expect_true(is_media_reference(ref))
expect_equal(ref$target_url, "a.mp4")
expect_equal(ref$OTIO_SCHEMA, "ExternalReference.1")

miss <- MissingReference()
expect_true(is_media_reference(miss))
expect_equal(miss$OTIO_SCHEMA, "MissingReference.1")

clip <- Clip("a", ref, source_range = TimeRange(RationalTime(0, 30), RationalTime(90, 30)))
expect_true(is_otio(clip))
expect_equal(clip$OTIO_SCHEMA, "Clip.2")
expect_equal(target_url(clip), "a.mp4")
expect_identical(media_reference(clip), ref)

# Clip defaults to a MissingReference.
expect_true(inherits(media_reference(Clip("x")), "MissingReference"))
expect_error(Clip("bad", media_reference = list()))

g <- Gap(RationalTime(15, 30))
expect_equal(g$OTIO_SCHEMA, "Gap.1")
expect_equal(value(duration(source_range(g))), 15)

# Functional builders return new objects; inputs unchanged.
v <- Track("V1", kind = "Video")
expect_equal(length(children(v)), 0L)
v2 <- add_child(v, clip)
expect_equal(length(children(v)), 0L)      # original untouched
expect_equal(length(children(v2)), 1L)
expect_equal(kind(v2), "Video")

tl <- Timeline("demo")
expect_true(is_timeline(tl))
tl2 <- add_track(tl, v2)
expect_equal(length(children(tracks(tl))), 0L)   # original untouched
expect_equal(length(children(tracks(tl2))), 1L)

# Accessors / replacement functions (value semantics).
metadata(tl) <- list(cornball = list(preset = "shorts"))
expect_equal(metadata(tl)$cornball$preset, "shorts")
name(tl) <- "renamed"
expect_equal(name(tl), "renamed")

# add_child type checks.
expect_error(add_child(clip, clip))        # clip is not a composition
expect_error(add_track(v2, v2))            # v2 is not a timeline
expect_error(add_child(v, RationalTime(0, 30)))  # not a composable child
expect_error(add_track(tl, clip))          # track must be a Track

# target_url<- on a default (Missing-ref) clip promotes the ref to External.
cx <- Clip("x")
expect_true(inherits(media_reference(cx), "MissingReference"))
target_url(cx) <- "a.mp4"
expect_equal(target_url(cx), "a.mp4")
expect_true(inherits(media_reference(cx), "ExternalReference"))
# and it serializes as a proper ExternalReference, not a Missing one with a url.
js <- to_json_string(cx)
expect_true(grepl("ExternalReference.1", js, fixed = TRUE))
expect_false(grepl("MissingReference", js, fixed = TRUE))
# setting url on an existing ExternalReference clip just updates it.
ce <- Clip("y", ExternalReference("old.mp4"))
target_url(ce) <- "new.mp4"
expect_equal(target_url(ce), "new.mp4")
