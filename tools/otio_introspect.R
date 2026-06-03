# OTIO header introspection via treesitR.
#
# Parses an OpenTimelineIO C++ header and extracts the public method surface of
# a named class: method name, return type, parameter list, and the static/const
# qualifiers. This is the front half of the Rcpp binding codegen (see
# otio_codegen.R) and a reusable map of the API we are wrapping.
#
# Not shipped in the package (tools/ is .Rbuildignore'd); a dev-time generator.

suppressMessages(library(treesitR))

# Visibility/export macros OTIO and opentime put between `class` and the class
# name, and in front of method return types. tree-sitter-cpp mis-parses these
# attribute macros (it reads the macro as the class name), so strip them to
# bare whitespace before parsing.
.OTIO_MACROS <- c("OTIO_API_TYPE", "OTIO_API",
                  "OPENTIME_API_TYPE", "OPENTIME_API")

.otio_scrub_macros <- function(src) {
    for (m in .OTIO_MACROS) {
        src <- gsub(paste0("\\b", m, "\\b"), "", src)
    }
    src
}

# Parse `src` (C++) and return the tree-sitter root node + retained source.
.otio_parse <- function(src) {
    src <- .otio_scrub_macros(src)
    p <- ts_parser_new()
    ts_parser_set_language(p, ts_language_cpp())
    tree <- ts_parse(p, src)
    list(root = ts_tree_root_node(tree), src = src, tree = tree)
}

# Depth-first collect every node of `type` under `node`.
.otio_find <- function(node, type, acc = list()) {
    if (ts_node_type(node) == type) acc[[length(acc) + 1L]] <- node
    for (ch in ts_node_children(node, named = TRUE)) {
        acc <- .otio_find(ch, type, acc)
    }
    acc
}

# Locate the class_specifier node for `class_name` within the parse.
.otio_class_node <- function(parse, class_name) {
    for (cls in .otio_find(parse$root, "class_specifier")) {
        nm <- ts_node_child_by_field(cls, "name")
        if (!ts_node_is_null(nm) && ts_node_text(nm) == class_name) {
            return(cls)
        }
    }
    NULL
}

# Extract public methods of a class as a data.frame:
#   name, return_type, params (raw text), is_static, is_const
otio_class_api <- function(header_path, class_name) {
    parse <- .otio_parse(paste(readLines(header_path), collapse = "\n"))
    cls <- .otio_class_node(parse, class_name)
    if (is.null(cls)) {
        stop("class not found in header: ", class_name)
    }
    body <- ts_node_child_by_field(cls, "body")
    if (ts_node_is_null(body)) return(.otio_empty_api())

    # Track access state while walking the class body top to bottom. Class
    # bodies default to private.
    access <- "private"
    rows <- list()
    for (member in ts_node_children(body, named = TRUE)) {
        mtype <- ts_node_type(member)
        if (mtype == "access_specifier") {
            access <- trimws(gsub(":", "", ts_node_text(member)))
            next
        }
        if (access != "public") next
        # declaration / field_declaration: methods declared without a body
        # (OTIO_API-exported). function_definition: inline methods with a body
        # (the simple getters: name(), kind(), target_url(), ...).
        if (!mtype %in% c("declaration", "field_declaration",
                          "function_definition")) next

        decl <- ts_node_child_by_field(member, "declarator")
        if (ts_node_is_null(decl)) next
        # Unwrap reference/pointer declarators to reach the function_declarator.
        fds <- .otio_find(decl, "function_declarator")
        if (length(fds) == 0L) next
        fd <- fds[[1L]]

        fname_node <- ts_node_child_by_field(fd, "declarator")
        params_node <- ts_node_child_by_field(fd, "parameters")
        type_node <- ts_node_child_by_field(member, "type")

        full <- ts_node_text(member)
        rows[[length(rows) + 1L]] <- data.frame(
            name = if (ts_node_is_null(fname_node)) NA_character_
                   else ts_node_text(fname_node),
            return_type = if (ts_node_is_null(type_node)) ""
                          else gsub("\\s+", " ", trimws(ts_node_text(type_node))),
            params = if (ts_node_is_null(params_node)) "()"
                     else gsub("\\s+", " ", trimws(ts_node_text(params_node))),
            is_static = grepl("\\bstatic\\b", full),
            is_const = grepl(") const", full, fixed = TRUE) ||
                       grepl(") const noexcept", full, fixed = TRUE),
            stringsAsFactors = FALSE)
    }
    if (length(rows) == 0L) return(.otio_empty_api())
    out <- do.call(rbind, rows)
    out <- out[!is.na(out$name) & nzchar(out$name), , drop = FALSE]
    rownames(out) <- NULL
    out
}

.otio_empty_api <- function() {
    data.frame(name = character(), return_type = character(),
               params = character(), is_static = logical(),
               is_const = logical(), stringsAsFactors = FALSE)
}
