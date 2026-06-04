# Driver registry.

# Clean slate (the registry is package-internal)
for (n in nle_drivers()) {
    rm(list = n, envir = nle.api:::.nle_registry)
}
expect_equal(length(nle_drivers()), 0L)

# Dump/apply on unregistered driver errors with a clear message
expect_error(dump_timeline("nope"))
expect_error(apply_timeline("nope", new_timeline()))

# Register a fake driver
fake_seq <- function() new_timeline(id = "fake", fps = 30L)
nle_register_driver(
    "fake",
    dump = function(...) fake_seq(),
    apply = function(timeline, ...) "applied",
    capabilities = function() list(formats = "memory", coords = "topleft",
                                   time = "frames", fields_preserved = "all",
                                   metadata = "fake")
)
expect_true(nle_driver_registered("fake"))
expect_true("fake" %in% nle_drivers())

# Dispatch
expect_true(is_timeline(dump_timeline("fake")))
expect_equal(apply_timeline("fake", new_timeline()), "applied")
caps <- driver_capabilities("fake")
expect_equal(caps$formats, "memory")
