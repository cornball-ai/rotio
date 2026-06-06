# Effects: construction, attachment, accessors, JSON shape, rotio equivalence.

eff <- Effect("blur", "GaussianBlur", metadata = list(size = 4))
expect_true(is_effect(eff))
expect_equal(eff$OTIO_SCHEMA, "Effect.1")
expect_equal(effect_name(eff), "GaussianBlur")
expect_true(enabled(eff))

warp <- LinearTimeWarp(effect_name = "LinearTimeWarp", time_scalar = 2)
expect_true(is_effect(warp))                 # LinearTimeWarp is an Effect
expect_equal(warp$OTIO_SCHEMA, "LinearTimeWarp.1")
expect_equal(time_scalar(warp), 2)
time_scalar(warp) <- 0.5
expect_equal(time_scalar(warp), 0.5)

# Defaults match OTIO: effect_name empty, enabled TRUE.
expect_equal(effect_name(LinearTimeWarp()), "")
expect_true(enabled(LinearTimeWarp()))

# enabled<- (mute maps to enabled == FALSE on items).
clip <- Clip("a", ExternalReference("a.mp4"))
expect_true(enabled(clip))
enabled(clip) <- FALSE
expect_false(enabled(clip))

# add_effect is functional and appends to the effects list.
clip <- Clip("a", ExternalReference("a.mp4"))
expect_equal(length(effects(clip)), 0L)
clip2 <- add_effect(clip, warp)
expect_equal(length(effects(clip)), 0L)       # input untouched
expect_equal(length(effects(clip2)), 1L)
expect_error(add_effect(clip, clip))          # not an Effect
expect_error(add_effect(RationalTime(0, 30), warp))  # no effects list

# Effects round-trip through JSON.
clip3 <- add_effect(add_effect(Clip("c", ExternalReference("c.mp4")),
                               Effect("blur", "GaussianBlur")),
                    LinearTimeWarp(effect_name = "LinearTimeWarp", time_scalar = 2))
js <- to_json_string(clip3)
back <- from_json_string(js)
expect_equal(length(effects(back)), 2L)
expect_true(is_effect(effects(back)[[1]]))
expect_equal(time_scalar(effects(back)[[2]]), 2)
expect_identical(to_json_string(back), js)

# rotio accepts our effect JSON and re-emits it equivalently to its own.
# (Metadata numerics are left out here: jsonlite emits a whole double as `4`
# while rotio re-emits `4.0`. Both parse fine and our own round-trip is stable;
# the divergence is only rotio's typed re-serialization of untyped metadata.)
if (requireNamespace("rotio", quietly = TRUE)) {
    expect_identical(
        rotio::to_json_string(rotio::from_json_string(to_json_string(
            Effect("blur", "GaussianBlur")))),
        rotio::to_json_string(rotio::Effect("blur", "GaussianBlur")))
    expect_identical(
        rotio::to_json_string(rotio::from_json_string(to_json_string(
            LinearTimeWarp("speed", time_scalar = 2)))),
        rotio::to_json_string(rotio::LinearTimeWarp("speed", time_scalar = 2)))
}
