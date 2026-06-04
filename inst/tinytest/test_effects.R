# clip_speed via OTIO LinearTimeWarp, and the deferred generic-effect verbs.

tl <- new_timeline(fps = 30L)
tl <- track_add(tl, "video", id = "v1")
tl <- clip_add(tl, "v1", tl_in = rational_time(0, 30),
               tl_out = rational_time(90, 30), asset = "a.mp4", id = "a")

# Default speed is 1.
expect_equal(tl$clips$speed, 1)

# clip_speed records a LinearTimeWarp; footprint is unchanged (OTIO model).
ts <- clip_speed(tl, "a", 2)
expect_equal(ts$clips$speed, 2)
expect_equal(ts$clips$tl_in, 0)
expect_equal(ts$clips$tl_out, 90)
expect_true(grepl("LinearTimeWarp", timeline_to_json(ts)))

# Round-trips through OTIO JSON.
ts_rt <- timeline_from_json(timeline_to_json(ts))
expect_equal(ts_rt$clips$speed, 2)

# speed = 1 clears the warp.
tc <- clip_speed(ts, "a", 1)
expect_equal(tc$clips$speed, 1)
expect_false(grepl("LinearTimeWarp", timeline_to_json(tc)))

# clip_add accepts a speed and records it.
tl <- clip_add(tl, "v1", tl_in = rational_time(90, 30),
               tl_out = rational_time(180, 30), asset = "b.mp4", id = "b",
               speed = 0.5)
expect_equal(tl$clips$speed[tl$clips$id == "b"], 0.5)

# Speed survives a structural edit (rebuild carries the speed column).
tmv <- clip_move(clip_speed(tl, "b", 4), "b", tl_in = rational_time(120, 30))
expect_equal(tmv$clips$speed[tmv$clips$id == "b"], 4)

# Non-positive speed errors.
expect_error(clip_speed(tl, "a", 0), "positive")
expect_error(clip_add(tl, "v1", tl_in = rational_time(200, 30),
                       tl_out = rational_time(260, 30), asset = "x.mp4",
                       id = "x", speed = -1), "positive")

# Compositing-effect verbs are still deferred (generic OTIO Effect API later).
expect_error(clip_transform(tl, "a", pos_x = 1), "generic OTIO Effect")
expect_error(clip_crop(tl, "a"), "generic OTIO Effect")
expect_error(clip_set(tl, "a"), "generic OTIO Effect")
