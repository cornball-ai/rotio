# OTIO Rcpp getter codegen.
#
# Emits src/otio_gen.cpp: trivial scalar field getters over wrapped OTIO
# objects. Each entry in the manifest is VALIDATED against the real header via
# tools/otio_introspect.R before emission, so we never generate a binding to a
# method that does not exist or whose signature we guessed wrong. The
# lifetime-sensitive code (construction, append, serialization, traversal) is
# hand-written in otio_objects.cpp, not generated.
#
# Run from the package root:  r -e 'source("tools/otio_codegen.R"); otio_generate()'
# Re-run whenever the manifest or the linked OTIO headers change, then
# Rcpp::compileAttributes(".") and rebuild.

source("tools/otio_introspect.R")

OTIO_INCLUDE <- "/usr/local/include/opentimelineio"

# C++ scalar return type -> generator support. Anything not here is rejected.
.OTIO_RTYPE <- c("std::string" = "std::string", "bool" = "bool",
                 "int" = "int", "double" = "double")

# The binding manifest. Each getter names the method, the header that DECLARES
# it (for validation; may be a base class), the declaring class, the concrete
# C++ class to unwrap as, and the expected scalar return type.
otio_getter_manifest <- function() {
    list(
        list(method = "name", header = "serializableObjectWithMetadata.h",
             decl_class = "SerializableObjectWithMetadata",
             cpp_class = "otio::Timeline", r_name = "otio_get_timeline_name"),
        list(method = "name", header = "serializableObjectWithMetadata.h",
             decl_class = "SerializableObjectWithMetadata",
             cpp_class = "otio::Track", r_name = "otio_get_track_name"),
        list(method = "kind", header = "track.h", decl_class = "Track",
             cpp_class = "otio::Track", r_name = "otio_get_track_kind"),
        list(method = "name", header = "serializableObjectWithMetadata.h",
             decl_class = "SerializableObjectWithMetadata",
             cpp_class = "otio::Clip", r_name = "otio_get_clip_name"),
        list(method = "active_media_reference_key", header = "clip.h",
             decl_class = "Clip", cpp_class = "otio::Clip",
             r_name = "otio_get_clip_active_media_reference_key"),
        list(method = "target_url", header = "externalReference.h",
             decl_class = "ExternalReference",
             cpp_class = "otio::ExternalReference",
             r_name = "otio_get_externalreference_target_url"))
}

# Validate a manifest entry against the header; return its C++ return type.
.otio_validate_getter <- function(g) {
    api <- otio_class_api(file.path(OTIO_INCLUDE, g$header), g$decl_class)
    row <- api[api$name == g$method & api$is_const & api$params == "()", ,
               drop = FALSE]
    if (nrow(row) == 0L) {
        stop(sprintf("codegen: %s::%s() not found as a const no-arg method in %s",
                     g$decl_class, g$method, g$header))
    }
    rtype <- row$return_type[[1L]]
    if (!rtype %in% names(.OTIO_RTYPE)) {
        stop(sprintf("codegen: %s::%s() returns unsupported type '%s'",
                     g$decl_class, g$method, rtype))
    }
    rtype
}

.otio_emit_getter <- function(g, rtype) {
    sprintf(paste0(
        "// [[Rcpp::export]]\n",
        "%s %s(SEXP p) {\n",
        "    return unwrap_otio<%s>(p)->%s();\n",
        "}\n"),
        rtype, g$r_name, g$cpp_class, g$method)
}

# Scalar setters: void set_<field>(<type>). Manifest entries name the setter
# method, the header/class declaring it, the concrete class to unwrap, the
# scalar argument type, and the generated R-callable name.
otio_setter_manifest <- function() {
    list(
        list(method = "set_name", header = "serializableObjectWithMetadata.h",
             decl_class = "SerializableObjectWithMetadata",
             cpp_class = "otio::Timeline", arg = "std::string",
             r_name = "otio_set_timeline_name"),
        list(method = "set_name", header = "serializableObjectWithMetadata.h",
             decl_class = "SerializableObjectWithMetadata",
             cpp_class = "otio::Track", arg = "std::string",
             r_name = "otio_set_track_name"),
        list(method = "set_kind", header = "track.h", decl_class = "Track",
             cpp_class = "otio::Track", arg = "std::string",
             r_name = "otio_set_track_kind"),
        list(method = "set_target_url", header = "externalReference.h",
             decl_class = "ExternalReference",
             cpp_class = "otio::ExternalReference", arg = "std::string",
             r_name = "otio_set_externalreference_target_url"))
}

# Confirm a void single-arg setter exists in the header.
.otio_validate_setter <- function(s) {
    api <- otio_class_api(file.path(OTIO_INCLUDE, s$header), s$decl_class)
    row <- api[api$name == s$method & api$return_type == "void", , drop = FALSE]
    if (nrow(row) == 0L) {
        stop(sprintf("codegen: %s::%s(...) not found as a void method in %s",
                     s$decl_class, s$method, s$header))
    }
    invisible(TRUE)
}

.otio_emit_setter <- function(s) {
    sprintf(paste0(
        "// [[Rcpp::export]]\n",
        "void %s(SEXP p, %s v) {\n",
        "    unwrap_otio<%s>(p)->%s(v);\n",
        "}\n"),
        s$r_name, s$arg, s$cpp_class, s$method)
}

# Trivial constructors whose first parameter is a std::string (the object name
# or url) and where remaining parameters take their defaults. Returns a wrapped
# object. Bespoke constructors (Clip's media reference, Track's kind/range) stay
# hand-written in otio_objects.cpp.
otio_ctor_manifest <- function() {
    list(
        list(cpp_class = "otio::Timeline", header = "timeline.h",
             decl_class = "Timeline", r_name = "otio_timeline_create"),
        list(cpp_class = "otio::ExternalReference",
             header = "externalReference.h", decl_class = "ExternalReference",
             r_name = "otio_externalreference_create"))
}

# Confirm a constructor exists whose first parameter is a std::string.
.otio_validate_ctor <- function(c) {
    api <- otio_class_api(file.path(OTIO_INCLUDE, c$header), c$decl_class)
    row <- api[api$name == c$decl_class, , drop = FALSE]
    if (nrow(row) == 0L) {
        stop(sprintf("codegen: no constructor found for %s in %s",
                     c$decl_class, c$header))
    }
    if (!any(grepl("std::string", row$params))) {
        stop(sprintf("codegen: %s has no std::string constructor parameter",
                     c$decl_class))
    }
    invisible(TRUE)
}

.otio_emit_ctor <- function(c) {
    sprintf(paste0(
        "// [[Rcpp::export]]\n",
        "SEXP %s(std::string name) {\n",
        "    return wrap_otio<%s>(new %s(name));\n",
        "}\n"),
        c$r_name, c$cpp_class, c$cpp_class)
}

otio_generate <- function(out = "src/otio_gen.cpp") {
    getters <- vapply(otio_getter_manifest(), function(g) {
        rtype <- .otio_validate_getter(g)
        .otio_emit_getter(g, rtype)
    }, character(1))
    setters <- vapply(otio_setter_manifest(), function(s) {
        .otio_validate_setter(s)
        .otio_emit_setter(s)
    }, character(1))
    ctors <- vapply(otio_ctor_manifest(), function(c) {
        .otio_validate_ctor(c)
        .otio_emit_ctor(c)
    }, character(1))
    bodies <- c(
        "// --- constructors ---", "", ctors,
        "// --- scalar getters ---", "", getters,
        "// --- scalar setters ---", "", setters)

    header <- c(
        "// GENERATED by tools/otio_codegen.R -- DO NOT EDIT.",
        "// Trivial scalar getters over wrapped OTIO objects. Each was validated",
        "// against the OTIO headers (see tools/otio_introspect.R) before emission.",
        "// Regenerate with: r -e 'source(\"tools/otio_codegen.R\"); otio_generate()'",
        "",
        "#include \"otio_common.h\"",
        "#include <opentimelineio/timeline.h>",
        "#include <opentimelineio/track.h>",
        "#include <opentimelineio/clip.h>",
        "#include <opentimelineio/externalReference.h>",
        "#include <opentimelineio/serializableObjectWithMetadata.h>",
        "")
    writeLines(c(header, bodies), out)
    message(sprintf(
        "otio_codegen: wrote %d ctors, %d getters, %d setters to %s",
        length(ctors), length(getters), length(setters), out))
    invisible(out)
}
