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

# upgrade machinery: an older-version object is migrated on read
register_upgrade_function("Marker", 2, function(d) {
    d$upgraded <- TRUE
    d
})
m1 <- from_json_string(paste0(
    '{"OTIO_SCHEMA":"Marker.1","metadata":{},"name":"m","color":"RED",',
    '"marked_range":{"OTIO_SCHEMA":"TimeRange.1",',
    '"start_time":{"OTIO_SCHEMA":"RationalTime.1","rate":24,"value":0},',
    '"duration":{"OTIO_SCHEMA":"RationalTime.1","rate":24,"value":0}}}'))
expect_equal(schema_version(m1), 2L)      # OTIO_SCHEMA bumped to current
expect_true(isTRUE(m1$upgraded))          # upgrade function ran

if (requireNamespace("rotio", quietly = TRUE)) {
    rcl <- rotio::Clip("a", rotio::ExternalReference("a.mov"))
    expect_equal(schema_name(cl), rotio::schema_name(rcl))
    expect_equal(schema_version(cl), rotio::schema_version(rcl))
    expect_equal(is_unknown_schema(cl), rotio::is_unknown_schema(rcl))
    rtv <- rotio::type_version_map()
    expect_equal(type_version_map(), rtv[names(type_version_map())])
}
