# Additional structural verbs: track_delete, track_move, ripple_delete,
# clip_slip, clip_duplicate.

mk <- function() {
    tl <- new_timeline(fps = 30L)
    tl <- track_add(tl, "video", id = "v1")
    tl <- track_add(tl, "audio", id = "a1")
    # a: 0-90, b: 90-180 (contiguous), c: 240-300 (gap 180-240).
    tl <- clip_add(tl, "v1", tl_in = rational_time(0, 30),
                   tl_out = rational_time(90, 30), asset = "a.mp4", id = "a")
    tl <- clip_add(tl, "v1", tl_in = rational_time(90, 30),
                   tl_out = rational_time(180, 30), asset = "b.mp4", id = "b")
    tl <- clip_add(tl, "v1", tl_in = rational_time(240, 30),
                   tl_out = rational_time(300, 30), asset = "c.mp4", id = "c")
    tl
}

# track_delete removes the track and its clips.
tl <- mk()
td <- track_delete(tl, "v1")
expect_equal(nrow(td$tracks), 1L)
expect_equal(td$tracks$id, "a1")
expect_equal(nrow(td$clips), 0L)
expect_error(track_delete(tl, "nope"), "no track")

# track_move reorders compositing order.
tm <- track_move(tl, "a1", 1L)
expect_equal(tm$tracks$id, c("a1", "v1"))
expect_equal(tm$tracks$idx, c(1L, 2L))
# clips still belong to v1.
expect_equal(sort(unique(tm$clips$track)), "v1")

# ripple_delete closes the gap left by the removed clip.
rd <- ripple_delete(tl, "b")  # b was 90-180; c (240) shifts left by 90 -> 150
expect_false("b" %in% rd$clips$id)
expect_equal(rd$clips$id, c("a", "c"))
expect_equal(rd$clips$tl_in,  c(0, 150))
expect_equal(rd$clips$tl_out, c(90, 210))
# plain clip_delete leaves the gap (c stays at 240).
cd <- clip_delete(tl, "b")
expect_equal(cd$clips$tl_in[cd$clips$id == "c"], 240)

# clip_slip shifts source, not timeline position.
sl <- clip_slip(tl, "a", by = rational_time(15, 30))
a <- sl$clips[sl$clips$id == "a", ]
expect_equal(a$tl_in, 0)            # position unchanged
expect_equal(a$tl_out, 90)
expect_equal(a$source_in, 15)       # source moved
expect_equal(a$source_out, 105)
expect_error(clip_slip(tl, "a", by = rational_time(-30, 30)), "before the source")

# clip_duplicate: default lands right after the original (errors as overlap if
# the slot is taken, so duplicate c which has open space after it).
dup <- clip_duplicate(tl, "c")
expect_equal(nrow(dup$clips), 4L)
cc <- dup$clips[grepl("^c", dup$clips$id) & dup$clips$id != "c", ]
expect_equal(cc$tl_in, 300)         # right after c (240-300)
expect_equal(cc$tl_out, 360)
expect_equal(cc$source_in, dup$clips$source_in[dup$clips$id == "c"])

# Explicit placement / track / id.
dup2 <- clip_duplicate(tl, "a", tl_in = rational_time(400, 30),
                       track = "v1", id = "a_clone")
expect_true("a_clone" %in% dup2$clips$id)
ac <- dup2$clips[dup2$clips$id == "a_clone", ]
expect_equal(ac$tl_in, 400)
expect_equal(ac$tl_out, 490)
