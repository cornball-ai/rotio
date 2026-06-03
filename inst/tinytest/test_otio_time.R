# Tests for the OpenTimelineIO-backed time type (otio_time), which wraps
# opentime::RationalTime through Rcpp. These exercise the C++ build chain:
# construction, XPtr round-trip, and OTIO-computed conversions.

library(nle.api)

# The build links a real OTIO; report a sane version string.
v <- otio_version()
expect_true(is.character(v) && grepl("^[0-9]+\\.[0-9]+", v))

# Construct and read back value/rate (num == value, den == rate).
t <- otio_time(4918, 30)
expect_true(is_otio_time(t))
expect_equal(otio_value(t), 4918)
expect_equal(otio_rate(t), 30)

# Seconds and frame conversions are computed by OTIO.
expect_equal(otio_to_seconds(t), 4918 / 30)
expect_equal(otio_to_frames(t, 30), 4918L)
# Rescale to 24 fps then read frames: int(4918 * 24 / 30) = 3934.
expect_equal(otio_to_frames(t, 24), 3934L)

# rescaled_to consumes an XPtr and returns a fresh one; seconds are preserved.
r <- otio_rescaled_to(t, 24)
expect_true(is_otio_time(r))
expect_equal(otio_rate(r), 24)
expect_equal(otio_to_seconds(r), otio_to_seconds(t), tolerance = 1e-9)

# A whole-second value round-trips through SMPTE timecode.
# 90 frames @ 30 fps = 3 s -> 00:00:03:00.
expect_equal(otio_timecode(otio_time(90, 30), 30), "00:00:03:00")

# den (rate) must be positive.
expect_error(otio_time(10, 0), "rate")
expect_error(otio_time(10, -5), "rate")

# format() shows value/rate.
expect_equal(format(otio_time(60, 1)), "60/1")
