# shift_after — ripple-shift clips after a TL boundary

seq <- new_sequence(fps = 30L)
seq <- track_add(seq, "video", id = "v1")
seq <- clip_add(seq, "v1", tl_in = rational_time(0, 30),
                tl_out = rational_time(90, 30), asset = "a.mp4", id = "a")
seq <- clip_add(seq, "v1", tl_in = rational_time(90, 30),
                tl_out = rational_time(180, 30), asset = "b.mp4", id = "b")
seq <- clip_add(seq, "v1", tl_in = rational_time(180, 30),
                tl_out = rational_time(300, 30), asset = "c.mp4", id = "c")

# Pull everything from frame 90 onward back by 30 frames (close a gap).
# delta accepts rational_time for frame-exact semantics; numeric is seconds.
seq2 <- shift_after(seq, after = rational_time(90, 30),
                    delta = rational_time(-30, 30))
expect_equal(seq2$clips$tl_in,  c(0,  60, 150))
expect_equal(seq2$clips$tl_out, c(90, 150, 270))

# Push everything from frame 90 onward forward by 30 frames (open a gap)
seq3 <- shift_after(seq, after = rational_time(90, 30),
                    delta = rational_time(30, 30))
expect_equal(seq3$clips$tl_in,  c(0, 120, 210))

# inclusive = FALSE keeps the clip at the boundary in place
seq4 <- shift_after(seq, after = rational_time(90, 30),
                    delta = rational_time(-30, 30),
                    inclusive = FALSE)
expect_equal(seq4$clips$tl_in,  c(0, 90, 150))

# Source in/out untouched
expect_equal(seq2$clips$source_in,  seq$clips$source_in)
expect_equal(seq2$clips$source_out, seq$clips$source_out)

# delta = 0 is a no-op
expect_equal(shift_after(seq, after = 0, delta = 0)$clips$tl_in,
             seq$clips$tl_in)

# Empty sequence is safe
expect_silent(shift_after(new_sequence(), after = 0, delta = 100))

# Numeric seconds work too (30 fps -> 1s = 30 frames)
seq5 <- shift_after(seq, after = 3, delta = -1)   # >= frame 90, by -30
expect_equal(seq5$clips$tl_in, c(0, 60, 150))
