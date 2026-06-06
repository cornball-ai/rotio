# OTIOD bundle read/write.

dir <- file.path(tempdir(), "bundle_test")
unlink(dir, recursive = TRUE)

tl <- add_track(Timeline("demo"),
                add_child(Track("V1", kind = "Video"),
                          Clip("a", ExternalReference("media/a.mp4"))))

out <- write_otiod(tl, dir)
expect_true(file.exists(out))
expect_true(dir.exists(file.path(dir, "media")))
expect_equal(basename(out), "content.otio")

back <- read_otiod(dir)
expect_true(is_timeline(back))
expect_equal(name(back), "demo")
expect_equal(target_url(children(children(tracks(back))[[1]])[[1]]), "media/a.mp4")

expect_error(read_otiod(file.path(tempdir(), "nope_no_bundle")))
unlink(dir, recursive = TRUE)
