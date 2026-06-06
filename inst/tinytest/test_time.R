# RationalTime / TimeRange construction and conversion.

rt <- RationalTime(180, 30)
expect_true(is_rational_time(rt))
expect_equal(value(rt), 180)
expect_equal(rate(rt), 30)
expect_equal(to_seconds(rt), 6)
expect_equal(to_frames(rt), 180L)
expect_equal(to_frames(rescaled_to(rt, 60)), 360L)
expect_equal(to_frames(rt, rate = 60), 360L)

expect_equal(value(from_seconds(6, 30)), 180)
expect_equal(value(from_frames(180, 30)), 180)

expect_error(RationalTime(1, 0))
expect_error(RationalTime(1, -5))

tr <- TimeRange(RationalTime(0, 30), RationalTime(180, 30))
expect_true(is_time_range(tr))
expect_equal(value(start_time(tr)), 0)
expect_equal(value(duration(tr)), 180)
expect_error(TimeRange(1, 2))
