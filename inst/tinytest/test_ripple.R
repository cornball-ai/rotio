# shift_after - ripple-shift clips after a TL boundary.
#
# Gap model A: shifts must not push a clip onto an occupied span. The fixture
# leaves real gaps (90-150 and 240-300) so the shifts below stay valid.

timeline <- new_timeline(fps = 30L)
timeline <- track_add(timeline, "video", id = "v1")
timeline <- clip_add(timeline, "v1", tl_in = rational_time(0, 30),
                tl_out = rational_time(90, 30), asset = "a.mp4", id = "a")
timeline <- clip_add(timeline, "v1", tl_in = rational_time(150, 30),
                tl_out = rational_time(240, 30), asset = "b.mp4", id = "b")
timeline <- clip_add(timeline, "v1", tl_in = rational_time(300, 30),
                tl_out = rational_time(360, 30), asset = "c.mp4", id = "c")

# Pull everything from frame 120 onward back by 30 (close part of the gaps).
seq2 <- shift_after(timeline, after = rational_time(120, 30),
                    delta = rational_time(-30, 30))
expect_equal(seq2$clips$tl_in,  c(0, 120, 270))
expect_equal(seq2$clips$tl_out, c(90, 210, 330))

# Push everything from frame 120 onward forward by 30 (open the gaps).
seq3 <- shift_after(timeline, after = rational_time(120, 30),
                    delta = rational_time(30, 30))
expect_equal(seq3$clips$tl_in, c(0, 180, 330))

# inclusive = FALSE keeps a clip starting exactly at `after` in place.
seq4 <- shift_after(timeline, after = rational_time(150, 30),
                    delta = rational_time(30, 30), inclusive = FALSE)
expect_equal(seq4$clips$tl_in, c(0, 150, 330))

# Source in/out are untouched by a ripple.
expect_equal(seq2$clips$source_in,  timeline$clips$source_in)
expect_equal(seq2$clips$source_out, timeline$clips$source_out)

# delta = 0 is a no-op.
expect_equal(shift_after(timeline, after = 0, delta = 0)$clips$tl_in,
             timeline$clips$tl_in)

# Empty timeline is safe.
expect_silent(shift_after(new_timeline(), after = 0, delta = 100))

# Numeric seconds work too (30 fps -> 4 s = frame 120, -1 s = -30 frames).
seq5 <- shift_after(timeline, after = 4, delta = -1)
expect_equal(seq5$clips$tl_in, c(0, 120, 270))

# A shift that would overlap an earlier clip is an error.
expect_error(
    shift_after(timeline, after = rational_time(150, 30),
                delta = rational_time(-90, 30)),
    "overlap")
