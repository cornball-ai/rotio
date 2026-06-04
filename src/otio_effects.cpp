// Clone-based effect mutation over the OTIO object model.
//
// Generic per-clip effects (transform, crop, colour, ...) are arbitrary
// name+parameter sets, so they can't ride nle.api's scalar-table rebuild. The
// OTIO-idiomatic way to edit them is to deep-clone the Timeline (clone() copies
// every clip, gap, effect, and metadata entry), mutate the target clip in the
// clone, and return it. The original is untouched, so the verbs stay pure and
// nothing is dropped.
//
// Effect parameters are stored as individual entries in the OTIO Effect's
// metadata (an AnyDictionary), exactly as OTIO models metadata -- not a private
// blob. Speed (LinearTimeWarp) is handled separately by the rebuild's speed
// column; the structural rebuild clones non-time effects forward by clip id so
// they survive structural edits (see otio_build.cpp).

#include "otio_common.h"
#include <opentimelineio/timeline.h>
#include <opentimelineio/stack.h>
#include <opentimelineio/track.h>
#include <opentimelineio/clip.h>
#include <opentimelineio/composition.h>
#include <opentimelineio/effect.h>
#include <opentimelineio/linearTimeWarp.h>
#include <opentimelineio/errorStatus.h>
#include <string>

// Find a clip by name across all tracks. nullptr if absent.
static otio::Clip* find_clip(otio::Timeline* t, std::string const& id) {
    for (auto const& tc : t->tracks()->children()) {
        otio::Track* tr = dynamic_cast<otio::Track*>((otio::Composable*) tc);
        if (!tr) continue;
        for (auto const& ch : tr->children()) {
            otio::Clip* c = dynamic_cast<otio::Clip*>((otio::Composable*) ch);
            if (c && c->name() == id) return c;
        }
    }
    return nullptr;
}

// Deep-clone a Timeline (copies all clips/gaps/effects/metadata).
static otio::Timeline* clone_timeline(otio::Timeline* t) {
    otio::ErrorStatus err;
    otio::SerializableObject* c = t->clone(&err);
    if (otio::is_error(err)) Rcpp::stop("clone: %s", err.details);
    otio::Timeline* tl = dynamic_cast<otio::Timeline*>(c);
    if (!tl) {
        if (c) c->possibly_delete();
        Rcpp::stop("clone: result is not a Timeline");
    }
    return tl;
}

// R named list (length-1 numeric/string values) -> AnyDictionary.
static otio::AnyDictionary list_to_anydict(Rcpp::List params) {
    otio::AnyDictionary d;
    if (params.size() == 0) return d;
    if (Rf_isNull(params.names())) {
        Rcpp::stop("effect params must be a named list");
    }
    Rcpp::CharacterVector nm = params.names();
    for (int i = 0; i < params.size(); ++i) {
        std::string key = Rcpp::as<std::string>(nm[i]);
        if (key.empty()) Rcpp::stop("effect params must all be named");
        SEXP v = params[i];
        switch (TYPEOF(v)) {
        case REALSXP: d[key] = (double) REAL(v)[0]; break;
        case INTSXP:
        case LGLSXP:  d[key] = (double) Rcpp::as<double>(v); break;
        case STRSXP:  d[key] = Rcpp::as<std::string>(v); break;
        default:
            Rcpp::stop("effect param '%s' must be numeric or string", key);
        }
    }
    return d;
}

// AnyDictionary -> R named list (doubles and strings; other types skipped).
static Rcpp::List anydict_to_list(otio::AnyDictionary const& d) {
    std::vector<std::string> names;
    Rcpp::List out;
    for (auto const& kv : d) {
        std::any const& a = kv.second;
        if (a.type() == typeid(double)) {
            out.push_back(std::any_cast<double>(a));
        } else if (a.type() == typeid(std::string)) {
            out.push_back(std::any_cast<std::string>(a));
        } else {
            continue;
        }
        names.push_back(kv.first);
    }
    out.attr("names") = names;
    return out;
}

static otio::Clip* require_clip(otio::Timeline* t, std::string const& id) {
    otio::Clip* c = find_clip(t, id);
    if (!c) Rcpp::stop("no clip with id '%s'", id);
    return c;
}

// [[Rcpp::export]]
SEXP otio_timeline_clone(SEXP tl) {
    return wrap_otio<otio::Timeline>(clone_timeline(unwrap_otio<otio::Timeline>(tl)));
}

// Clone, attach a generic Effect (effect_name + metadata) to the clip, return.
// [[Rcpp::export]]
SEXP otio_clip_effect_add(SEXP tl, std::string clip_id, std::string effect_name,
                          Rcpp::List params, bool enabled) {
    otio::Timeline* c = clone_timeline(unwrap_otio<otio::Timeline>(tl));
    SEXP wrapped = wrap_otio<otio::Timeline>(c);
    otio::Clip* clip = require_clip(c, clip_id);
    otio::Effect* eff =
        new otio::Effect("", effect_name, list_to_anydict(params), enabled);
    clip->effects().push_back(Ret<otio::Effect>(eff));
    return wrapped;
}

// One row per effect on a clip: index, effect_name, enabled, time_scalar
// (the warp factor for LinearTimeWarp effects, else NA).
// [[Rcpp::export]]
Rcpp::DataFrame otio_clip_effects_df(SEXP tl, std::string clip_id) {
    otio::Clip* clip = require_clip(unwrap_otio<otio::Timeline>(tl), clip_id);
    std::vector<int> index;
    std::vector<std::string> effect_name;
    std::vector<bool> enabled;
    std::vector<double> time_scalar;
    int i = 0;
    for (auto const& e : clip->effects()) {
        otio::Effect* eff = e;
        index.push_back(i++);
        effect_name.push_back(eff->effect_name());
        enabled.push_back(eff->enabled());
        if (auto w = dynamic_cast<otio::LinearTimeWarp*>(eff)) {
            time_scalar.push_back(w->time_scalar());
        } else {
            time_scalar.push_back(NA_REAL);
        }
    }
    return Rcpp::DataFrame::create(
        Rcpp::Named("index") = index,
        Rcpp::Named("effect_name") = effect_name,
        Rcpp::Named("enabled") = enabled,
        Rcpp::Named("time_scalar") = time_scalar,
        Rcpp::Named("stringsAsFactors") = false);
}

// The metadata of the effect at 0-based index, as a named list.
// [[Rcpp::export]]
Rcpp::List otio_clip_effect_params(SEXP tl, std::string clip_id, int index) {
    otio::Clip* clip = require_clip(unwrap_otio<otio::Timeline>(tl), clip_id);
    int n = (int) clip->effects().size();
    if (index < 0 || index >= n) {
        Rcpp::stop("effect index %d out of range [0, %d)", index, n);
    }
    otio::Effect* eff = clip->effects()[index];
    return anydict_to_list(eff->metadata());
}

// Clone, remove the effect at 0-based index from the clip, return.
// [[Rcpp::export]]
SEXP otio_clip_effect_remove(SEXP tl, std::string clip_id, int index) {
    otio::Timeline* c = clone_timeline(unwrap_otio<otio::Timeline>(tl));
    SEXP wrapped = wrap_otio<otio::Timeline>(c);
    otio::Clip* clip = require_clip(c, clip_id);
    int n = (int) clip->effects().size();
    if (index < 0 || index >= n) {
        Rcpp::stop("effect index %d out of range [0, %d)", index, n);
    }
    clip->effects().erase(clip->effects().begin() + index);
    return wrapped;
}
