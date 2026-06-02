# Coordinate system conversions. Cornelius PIP scenario:
#   source 960x960, scale 0.604, canvas 1080x1080
#   displayed = 580 x 580
#   topleft   = (480, 20)    canonical
#   cartesian = (480, 480)   bottom-left + Y up
#   center    = (230, 230)   Blender-native (centre origin + Y up)

canvas_w <- 1080; canvas_h <- 1080
src_w    <- 960;  src_h    <- 960
# Use exact 580/960 to avoid float drift in the test
disp_w   <- 580
disp_h   <- 580

# topleft is canonical -> identity
tl <- to_topleft(480, 20, "topleft", canvas_w, canvas_h, disp_w, disp_h)
expect_equal(unname(tl), c(480, 20))

# cartesian: pos_y is bottom-left of bbox in +Y-up; topleft pos_y =
# canvas_h - pos_y - disp_h
tl_c <- to_topleft(480, 480, "cartesian", canvas_w, canvas_h, disp_w, disp_h)
expect_equal(unname(tl_c), c(480, 20))

# center: pos_x = canvas_w/2 + offset_x - disp_w/2; pos_y = canvas_h/2 - offset_y - disp_h/2
tl_ctr <- to_topleft(230, 230, "center", canvas_w, canvas_h, disp_w, disp_h)
expect_equal(unname(tl_ctr), c(480, 20))

# from_topleft is the inverse for cartesian (round-trip)
cart <- from_topleft(480, 20, "cartesian", canvas_w, canvas_h, disp_w, disp_h)
expect_equal(unname(cart), c(480, 480))

# default coords falls back to "topleft" when option not set
old <- options(nle.coords = NULL)
expect_equal(resolve_coords(), "topleft")
options(nle.coords = "cartesian")
expect_equal(resolve_coords(), "cartesian")
options(old)
