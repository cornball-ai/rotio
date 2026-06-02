# Rational time basics.

r <- rational_time(4918, 30)
expect_true(is_rational_time(r))
expect_equal(r$num, 4918L)
expect_equal(r$den, 30L)
expect_equal(to_seconds(r), 4918 / 30)

# Conversion preserves exactness when den matches fps
expect_equal(to_frames(r, 30L), 4918L)

# Cross-fps rescale
r2 <- rational_time(48, 24)         # 2 seconds at 24 fps
expect_equal(to_seconds(r2), 2)
expect_equal(to_frames(r2, 30L), 60L)   # 2 seconds at 30 fps

# Constructor validation
expect_error(rational_time(1, 0))
expect_error(rational_time(1, -1))

# Round-trip seconds <-> rational
expect_equal(to_seconds(to_rational(1.5, 30L)), 1.5)
