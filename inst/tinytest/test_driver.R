# Driver registry.

# Clean slate (the registry is package-internal)
for (n in nle_drivers()) {
    rm(list = n, envir = nle.api:::.nle_registry)
}
expect_equal(length(nle_drivers()), 0L)

# Dump/apply on unregistered driver errors with a clear message
expect_error(dump_sequence("nope"))
expect_error(apply_sequence("nope", new_sequence()))

# Register a fake driver
fake_seq <- function() new_sequence(id = "fake", fps = 30L)
nle_register_driver(
    "fake",
    dump = function(...) fake_seq(),
    apply = function(seq, ...) "applied",
    capabilities = function() list(formats = "memory", coords = "topleft",
                                   time = "frames", fields_preserved = "all",
                                   extensions = "extensions.fake")
)
expect_true(nle_driver_registered("fake"))
expect_true("fake" %in% nle_drivers())

# Dispatch
expect_true(is_sequence(dump_sequence("fake")))
expect_equal(apply_sequence("fake", new_sequence()), "applied")
caps <- driver_capabilities("fake")
expect_equal(caps$formats, "memory")
