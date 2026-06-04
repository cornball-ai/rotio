# Sequence model (OTIO-backed), structural verbs, JSON + sequence.md IO.
#
# Times: numeric = seconds; rational_time = frame-exact. Under gap model A a
# track is sequential, so overlapping clips on one track are an error.

seq <- new_sequence(id = "demo", fps = 30L, canvas = c(1080L, 1080L))
seq <- track_add(seq, "video", id = "v1")
seq <- track_add(seq, "audio", id = "a1")
expect_equal(nrow(seq$tracks), 2L)
expect_equal(seq_fps(seq), 30)
expect_equal(seq$canvas$width, 1080)

# a: TL 0-90, source 0-90. b: TL 90-180 (contiguous), source_in 30 -> 30-120.
seq <- clip_add(seq, "v1", tl_in = rational_time(0, 30),
                tl_out = rational_time(90, 30), asset = "a.mp4", id = "a")
seq <- clip_add(seq, "v1", tl_in = rational_time(90, 30),
                tl_out = rational_time(180, 30), asset = "b.mp4", id = "b",
                source_in = rational_time(30, 30))
expect_equal(nrow(seq$clips), 2L)
expect_equal(seq$clips$tl_in,      c(0, 90))
expect_equal(seq$clips$tl_out,     c(90, 180))
expect_equal(seq$clips$source_in,  c(0, 30))
expect_equal(seq$clips$source_out, c(90, 120))
expect_equal(seq_duration_frames(seq), 180L)
expect_silent(validate_sequence(seq))

# c after a 60-frame gap: TL 240-300 (gap 180-240 becomes an OTIO Gap).
seq <- clip_add(seq, "v1", tl_in = rational_time(240, 30),
                tl_out = rational_time(300, 30), asset = "c.mp4", id = "c")
expect_equal(seq$clips$tl_in, c(0, 90, 240))
expect_equal(seq_duration_frames(seq), 300L)

# clip_move: slide c earlier into its gap (no overlap).
seqm <- clip_move(seq, "c", tl_in = rational_time(210, 30))
expect_equal(seqm$clips$tl_in[seqm$clips$id == "c"],  210)
expect_equal(seqm$clips$tl_out[seqm$clips$id == "c"], 270)

# clip_move onto an occupied span overlaps -> error.
expect_error(clip_move(seq, "c", tl_in = rational_time(90, 30)), "overlap")

# clip_trim right edge of b (shrink); source span follows.
seqt <- clip_trim(seq, "b", tl_out = rational_time(150, 30))
b <- seqt$clips[seqt$clips$id == "b", ]
expect_equal(b$tl_out, 150)
expect_equal(b$source_out - b$source_in, 60)

# clip_trim left edge of a; source in-point follows the edge.
seqt2 <- clip_trim(seq, "a", tl_in = rational_time(30, 30))
a2 <- seqt2$clips[seqt2$clips$id == "a", ]
expect_equal(a2$tl_in, 30)
expect_equal(a2$source_in, 30)

# clip_split a at frame 45.
seqs <- clip_split(seq, "a", at = rational_time(45, 30))
expect_equal(nrow(seqs$clips), 4L)
expect_true("a_split" %in% seqs$clips$id)
asp <- seqs$clips[seqs$clips$id == "a_split", ]
expect_equal(asp$tl_in, 45)
expect_equal(asp$tl_out, 90)

# clip_delete.
seqd <- clip_delete(seq, "b")
expect_equal(nrow(seqd$clips), 2L)
expect_false("b" %in% seqd$clips$id)

# Effect-dependent verbs are deferred to PR 4.
expect_error(clip_speed(seq, "a", 2), "PR 4")
expect_error(clip_transform(seq, "a", pos_x = 1), "PR 4")
expect_error(clip_crop(seq, "a"), "PR 4")
expect_error(clip_set(seq, "a"), "PR 4")
expect_error(
    clip_add(seq, "v1", tl_in = rational_time(300, 30),
             tl_out = rational_time(360, 30), asset = "x.mp4", id = "x",
             speed = 2),
    "PR 4")

# JSON round-trip: canonical OTIO, shape and config preserved.
js <- sequence_to_json(seq)
expect_true(grepl("Timeline\\.[0-9]", js))
seq_rt <- sequence_from_json(js)
expect_equal(seq_rt$clips$id,    seq$clips$id)
expect_equal(seq_rt$clips$tl_in, seq$clips$tl_in)
expect_equal(seq_rt$clips$tl_out, seq$clips$tl_out)
expect_equal(seq_fps(seq_rt), 30)

# sequence.md round-trip with the otio marker.
tmp <- tempfile(fileext = ".md")
on.exit(unlink(tmp), add = TRUE)
write_sequence(seq, tmp)
md <- readLines(tmp)
expect_true(any(grepl("sequence:state otio", md)))
expect_true(any(grepl("/sequence:state", md)))
seq_rt2 <- read_sequence(tmp)
expect_equal(seq_rt2$clips$id, seq$clips$id)

# Strict parser: missing close marker.
bad <- tempfile(fileext = ".md")
on.exit(unlink(bad), add = TRUE)
writeLines(c("# x", "<!-- sequence:state otio -->", "{}"), bad)
expect_error(read_sequence(bad))

# Duplicated open marker.
bad2 <- tempfile(fileext = ".md")
on.exit(unlink(bad2), add = TRUE)
writeLines(c("<!-- sequence:state otio -->", "{}", "<!-- /sequence:state -->",
             "<!-- sequence:state otio -->", "{}", "<!-- /sequence:state -->"),
           bad2)
expect_error(read_sequence(bad2))
