# Phase 6: schema machinery.

cl <- Clip("a", ExternalReference("a.mov"))
expect_equal(schema_name(cl), "Clip")
expect_equal(schema_version(cl), 2L)
expect_false(is_unknown_schema(cl))
expect_equal(schema_name(Marker("m")), "Marker")
expect_equal(schema_version(Marker("m")), 2L)
expect_equal(schema_version(Track("V1")), 1L)
expect_false(is_unknown_schema(Timeline("t")))

tv <- type_version_map()
expect_equal(length(tv), 23L)
expect_equal(tv[["Clip"]], 2L)
expect_equal(tv[["Marker"]], 2L)
expect_equal(tv[["Track"]], 1L)

# unknown schema parsed from JSON
u <- from_json_string('{"OTIO_SCHEMA": "Frobnicator.1", "value": 5}')
expect_true(is_unknown_schema(u))
expect_equal(schema_name(u), "UnknownSchema")
expect_equal(schema_version(u), 1L)

# registration semantics: TRUE fresh, FALSE on duplicate / unknown / built-in
expect_true(register_upgrade_function("Timeline", 9L, function(d) d))
expect_false(register_upgrade_function("Timeline", 9L, function(d) d))     # duplicate
expect_false(register_upgrade_function("NotASchema", 2L, function(d) d))   # unknown
expect_false(register_upgrade_function("Clip", 2L, function(d) d))         # built-in
expect_true(register_downgrade_function("Timeline", 9L, function(d) d))
expect_false(register_downgrade_function("Clip", 2L, function(d) d))       # built-in

# built-in Marker.1 -> Marker.2: range -> marked_range
m1 <- from_json_string(paste0(
    '{"OTIO_SCHEMA":"Marker.1","metadata":{},"name":"m","color":"RED",',
    '"range":{"OTIO_SCHEMA":"TimeRange.1",',
    '"start_time":{"OTIO_SCHEMA":"RationalTime.1","rate":24,"value":2},',
    '"duration":{"OTIO_SCHEMA":"RationalTime.1","rate":24,"value":3}}}'))
expect_equal(schema_version(m1), 2L)
expect_equal(value(start_time(marked_range(m1))), 2)

# built-in Clip.1 -> Clip.2: media_reference -> media_references
c1 <- from_json_string(paste0(
    '{"OTIO_SCHEMA":"Clip.1","metadata":{},"name":"c","source_range":null,',
    '"media_reference":{"OTIO_SCHEMA":"ExternalReference.1","metadata":{},',
    '"name":"","available_range":null,"available_image_bounds":null,',
    '"target_url":"c.mov"}}'))
expect_equal(schema_version(c1), 2L)
expect_equal(target_url(media_reference(c1)), "c.mov")

# downgrade Clip.2 -> Clip.1 on write, then round-trips back to Clip.2
dn <- to_json_string(Clip("c", ExternalReference("c.mov")), target_schema_versions = c(Clip = 1L))
expect_true(grepl('"Clip.1"', dn, fixed = TRUE))
expect_true(grepl('"media_reference"', dn, fixed = TRUE))
expect_false(grepl("media_references", dn, fixed = TRUE))
expect_equal(target_url(media_reference(from_json_string(dn))), "c.mov")

# a third-party schema cannot have migrations registered
expect_false(is.null(register_upgrade_function))   # function exists

# target_schema_versions validation (matches RcppOTIO's guard)
cl2 <- Clip("c", ExternalReference("c.mov"))
expect_error(to_json_string(cl2, target_schema_versions = c(1L)))                # unnamed
expect_error(to_json_string(cl2, target_schema_versions = c(Clip = NA_integer_)))  # NA
expect_error(to_json_string(cl2, target_schema_versions = c(Clip = 1.5)))         # non-whole
expect_error(to_json_string(cl2, target_schema_versions = c(Clip = "1")))         # character
dup <- c(1L, 1L); names(dup) <- c("Clip", "Clip")
expect_error(to_json_string(cl2, target_schema_versions = dup))                   # duplicate

# a minimal parsed Clip materializes current-schema defaults
mc <- from_json_string(paste0(
    '{"OTIO_SCHEMA":"Clip.1","name":"c","source_range":null,',
    '"media_reference":{"OTIO_SCHEMA":"ExternalReference.1","target_url":"c.mov"}}'))
expect_true(isTRUE(mc$enabled))     # would be NULL without default materialization
expect_equal(mc$effects, list())
expect_equal(mc$markers, list())
expect_true("color" %in% mc$.keys)
expect_true(visible(mc))            # enabled clip is visible
expect_equal(target_url(media_reference(mc)), "c.mov")

if (requireNamespace("RcppOTIO", quietly = TRUE)) {
    rcl <- RcppOTIO::Clip("a", RcppOTIO::ExternalReference("a.mov"))
    expect_equal(schema_name(cl), RcppOTIO::schema_name(rcl))
    expect_equal(schema_version(cl), RcppOTIO::schema_version(rcl))
    expect_equal(is_unknown_schema(cl), RcppOTIO::is_unknown_schema(rcl))
    rtv <- RcppOTIO::type_version_map()
    expect_equal(type_version_map(), rtv[names(type_version_map())])
    # downgrade output matches RcppOTIO (compared via canonical round-trip)
    ncl <- Clip("c", ExternalReference("c.mov"))
    njs <- to_json_string(ncl, target_schema_versions = c(Clip = 1L))
    rjs <- RcppOTIO::to_json_string(RcppOTIO::Clip("c", RcppOTIO::ExternalReference("c.mov")),
                                 target_schema_versions = c(Clip = 1L))
    expect_equal(RcppOTIO::to_json_string(RcppOTIO::from_json_string(njs)),
                 RcppOTIO::to_json_string(RcppOTIO::from_json_string(rjs)))
}
