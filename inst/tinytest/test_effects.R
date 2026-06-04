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

# --- generic OTIO Effect API (clone-based) ---

te <- clip_effect_add(tl, "a", "transform",
                      list(x = 100, y = 50, scale = 0.5, label = "hero"))
fx <- clip_effects(te, "a")
expect_equal(nrow(fx), 1L)
expect_equal(fx$index, 1L)                    # 1-based on the R side
expect_equal(fx$effect_name, "transform")
expect_true(fx$enabled)
expect_true(is.na(fx$time_scalar))            # not a time warp

# Parameters round-trip as individual metadata entries.
p <- clip_effect_params(te, "a", 1)
expect_equal(p$x, 100); expect_equal(p$scale, 0.5); expect_equal(p$label, "hero")

# The input timeline is untouched (clone-based, pure).
expect_equal(nrow(clip_effects(tl, "a")), 0L)

# Effect survives a structural edit of another clip AND of itself.
expect_equal(nrow(clip_effects(clip_move(te, "b", tl_in = rational_time(300, 30)),
                               "a")), 1L)
expect_equal(nrow(clip_effects(clip_move(te, "a", tl_in = rational_time(300, 30)),
                               "a")), 1L)

# Effect survives JSON round-trip.
expect_equal(clip_effects(timeline_from_json(timeline_to_json(te)), "a")$effect_name,
             "transform")

# A clip can carry both a speed (LinearTimeWarp) and a generic effect; both are
# listed (the warp keeps the speed column and clip_effects in sync).
tsf <- clip_speed(te, "a", 2)
expect_equal(tsf$clips$speed[tsf$clips$id == "a"], 2)
fx2 <- clip_effects(tsf, "a")
expect_equal(nrow(fx2), 2L)
expect_true("transform" %in% fx2$effect_name)        # generic effect survived
expect_true(any(!is.na(fx2$time_scalar)))            # the LinearTimeWarp

# Remove it.
tr0 <- clip_effect_remove(te, "a", 1)
expect_equal(nrow(clip_effects(tr0, "a")), 0L)
expect_error(clip_effect_remove(te, "a", 5), "out of range")

# Effect on an unknown clip errors.
expect_error(clip_effect_add(tl, "nope", "x"), "no clip")
