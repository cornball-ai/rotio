# Sequence S3, verbs, JSON round-trip, sequence.md marker IO.

# Build a small sequence. Times are seconds; use rational_time for
# frame-exact values.
seq <- new_sequence(id = "demo", fps = 30L, canvas = c(1080L, 1080L))
seq <- track_add(seq, "video", id = "v1")
seq <- track_add(seq, "audio", id = "a1")
# intro: TL 0-90 frames = 0-3 s, source from frame 0
seq <- clip_add(seq, track = "v1",
                tl_in  = rational_time(0,  30),
                tl_out = rational_time(90, 30),
                asset = "intro.mp4", id = "intro", speed = 1)
# shot: TL 90-180 frames = 3-6 s, source_in at frame 30 = 1 s, speed 1.5
seq <- clip_add(seq, track = "v1",
                tl_in  = rational_time(90,  30),
                tl_out = rational_time(180, 30),
                asset = "shot.mp4", id = "shot",
                source_in = rational_time(30, 30), speed = 1.5)

expect_equal(nrow(seq$tracks), 2L)
expect_equal(nrow(seq$clips),  2L)
expect_equal(seq_duration_frames(seq), 180L)

# Validation passes
expect_silent(validate_sequence(seq))

# clip_move shifts tl_in but preserves duration (10 frames = 1/3 s)
seq2 <- clip_move(seq, "intro", tl_in = rational_time(10, 30))
expect_equal(seq2$clips$tl_in[1],  10L)
expect_equal(seq2$clips$tl_out[1], 100L)

# clip_trim recomputes source range (60 frames = 2 s)
seq3 <- clip_trim(seq, "intro", tl_out = rational_time(60, 30))
expect_equal(seq3$clips$tl_out[1], 60L)
expect_equal(seq3$clips$source_out[1] - seq3$clips$source_in[1], 60L)

# clip_speed adjusts tl_out to keep source span fixed
seq4 <- clip_speed(seq, "shot", 3)
expect_equal(seq4$clips$speed[2], 3)

# clip_transform: topleft is identity
seq5 <- clip_transform(seq, "intro", pos_x = 100, pos_y = 200)
expect_equal(seq5$clips$pos_x[1], 100)
expect_equal(seq5$clips$pos_y[1], 200)

# clip_split halves a clip (at frame 45 = 1.5 s)
seq6 <- clip_split(seq, "intro", at = rational_time(45, 30))
expect_equal(nrow(seq6$clips), 3L)
expect_equal(seq6$clips$tl_out[1], 45L)
expect_true("intro_split" %in% seq6$clips$id)

# JSON round-trip
js <- sequence_to_json(seq)
seq_rt <- sequence_from_json(js)
expect_equal(nrow(seq_rt$tracks), 2L)
expect_equal(nrow(seq_rt$clips),  2L)
expect_equal(seq_rt$clips$id,    seq$clips$id)
expect_equal(seq_rt$clips$tl_in, seq$clips$tl_in)
expect_equal(seq_rt$clips$tl_out, seq$clips$tl_out)
expect_equal(seq_rt$clips$speed, seq$clips$speed)

# sequence.md round-trip
tmp <- tempfile(fileext = ".md")
on.exit(unlink(tmp), add = TRUE)
write_sequence(seq, tmp)
md <- readLines(tmp)
expect_true(any(grepl("sequence:state json cornball.sequence.v1", md)))
expect_true(any(grepl("/sequence:state", md)))

seq_rt2 <- read_sequence(tmp)
expect_equal(seq_rt2$clips$id, seq$clips$id)

# Strict parser: missing close marker is an error
bad <- tempfile(fileext = ".md")
on.exit(unlink(bad), add = TRUE)
writeLines(c("# x", "<!-- sequence:state json cornball.sequence.v1 -->", "{}"),
           bad)
expect_error(read_sequence(bad))

# Duplicated open marker is an error
bad2 <- tempfile(fileext = ".md")
on.exit(unlink(bad2), add = TRUE)
writeLines(c("<!-- sequence:state json cornball.sequence.v1 -->",
             "{}",
             "<!-- /sequence:state -->",
             "<!-- sequence:state json cornball.sequence.v1 -->",
             "{}",
             "<!-- /sequence:state -->"),
           bad2)
expect_error(read_sequence(bad2))

# Schema mismatch is an error
bad3 <- tempfile(fileext = ".md")
on.exit(unlink(bad3), add = TRUE)
writeLines(c("<!-- sequence:state json cornball.sequence.v2 -->",
             "{}",
             "<!-- /sequence:state -->"),
           bad3)
expect_error(read_sequence(bad3))
