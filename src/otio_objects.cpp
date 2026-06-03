// Rcpp shim over the OpenTimelineIO object model: Timeline, Track, Clip,
// ExternalReference, plus JSON (de)serialization and data.frame views.
//
// LIFETIME. OTIO objects derive from SerializableObject, whose destructor is
// protected: you must never `delete` them. Ownership is intrusive ref-counting
// via SerializableObject::Retainer<T>. We hold each object through a
// heap-allocated Retainer wrapped in an Rcpp::XPtr; the XPtr finalizer deletes
// the Retainer, releasing one managed reference. When a parent (a Track holding
// a Clip, a Stack holding a Track) also retains the object, the object survives
// R-side garbage collection of its XPtr and is freed only when the last
// reference goes away. See PLAN.md open question 1.
//
// The hand-written core lives here (construction, append, serialization,
// child traversal). The uniform scalar field getters are generated from the
// headers by tools/otio_codegen.R into otio_gen.cpp.

#include "otio_common.h"
#include <opentimelineio/timeline.h>
#include <opentimelineio/stack.h>
#include <opentimelineio/track.h>
#include <opentimelineio/clip.h>
#include <opentimelineio/gap.h>
#include <opentimelineio/externalReference.h>
#include <opentimelineio/composition.h>
#include <opentimelineio/errorStatus.h>
#include <opentime/timeRange.h>
#include <optional>

using otio::RationalTime;
using otio::TimeRange;

static void check(otio::ErrorStatus const& err, const char* what) {
    if (otio::is_error(err)) Rcpp::stop("%s: %s", what, err.details);
}

// ---- construction -------------------------------------------------------

// [[Rcpp::export]]
SEXP otio_timeline_create(std::string name) {
    return wrap_otio<otio::Timeline>(new otio::Timeline(name));
}

// [[Rcpp::export]]
SEXP otio_track_create(std::string name, std::string kind) {
    return wrap_otio<otio::Track>(new otio::Track(name, std::nullopt, kind));
}

// Build a Clip backed by an ExternalReference, with a source_range built from
// (start, duration) RationalTimes. The Clip retains the ExternalReference.
// [[Rcpp::export]]
SEXP otio_clip_create(std::string name, std::string target_url,
                      double start_value, double start_rate,
                      double dur_value, double dur_rate) {
    otio::ExternalReference* ref = new otio::ExternalReference(target_url);
    TimeRange range(RationalTime(start_value, start_rate),
                    RationalTime(dur_value, dur_rate));
    return wrap_otio<otio::Clip>(new otio::Clip(name, ref, range));
}

// ---- population ---------------------------------------------------------

// [[Rcpp::export]]
bool otio_timeline_add_track(SEXP tl, SEXP track) {
    otio::Timeline* t = unwrap_otio<otio::Timeline>(tl);
    otio::Track* tr = unwrap_otio<otio::Track>(track);
    otio::ErrorStatus err;
    bool ok = t->tracks()->append_child(tr, &err);
    check(err, "add_track");
    return ok;
}

// [[Rcpp::export]]
bool otio_track_add_clip(SEXP track, SEXP clip) {
    otio::Track* tr = unwrap_otio<otio::Track>(track);
    otio::Clip* c = unwrap_otio<otio::Clip>(clip);
    otio::ErrorStatus err;
    bool ok = tr->append_child(c, &err);
    check(err, "add_clip");
    return ok;
}

// Remove the child at 0-based index from a track.
// [[Rcpp::export]]
bool otio_track_remove_clip(SEXP track, int index) {
    otio::Track* tr = unwrap_otio<otio::Track>(track);
    int n = (int) tr->children().size();
    if (index < 0 || index >= n) {
        Rcpp::stop("remove_clip: index %d out of range [0, %d)", index, n);
    }
    otio::ErrorStatus err;
    bool ok = tr->remove_child(index, &err);
    check(err, "remove_clip");
    return ok;
}

// ---- serialization ------------------------------------------------------

// [[Rcpp::export]]
std::string otio_timeline_to_json(SEXP tl) {
    otio::Timeline* t = unwrap_otio<otio::Timeline>(tl);
    otio::ErrorStatus err;
    std::string s = t->to_json_string(&err);
    check(err, "to_json");
    return s;
}

// [[Rcpp::export]]
SEXP otio_timeline_from_json(std::string json) {
    otio::ErrorStatus err;
    otio::SerializableObject* obj =
        otio::SerializableObject::from_json_string(json, &err);
    check(err, "from_json");
    otio::Timeline* tl = dynamic_cast<otio::Timeline*>(obj);
    if (!tl) {
        if (obj) obj->possibly_delete();
        Rcpp::stop("from_json: top-level object is not a Timeline");
    }
    return wrap_otio<otio::Timeline>(tl);
}

// ---- traversal views ----------------------------------------------------
// (Scalar field getters like otio_get_timeline_name live in the generated
// otio_gen.cpp.)

// One row per track in the timeline's stack.
// [[Rcpp::export]]
Rcpp::DataFrame otio_timeline_tracks_df(SEXP tl) {
    otio::Timeline* t = unwrap_otio<otio::Timeline>(tl);
    std::vector<int> index, n_children;
    std::vector<std::string> name, kind;
    int i = 0;
    for (auto const& child : t->tracks()->children()) {
        otio::Composable* comp = child; // Retainer::operator Composable*()
        otio::Track* tr = dynamic_cast<otio::Track*>(comp);
        if (!tr) { i++; continue; }
        index.push_back(i++);
        name.push_back(tr->name());
        kind.push_back(tr->kind());
        n_children.push_back((int) tr->children().size());
    }
    return Rcpp::DataFrame::create(
        Rcpp::Named("index") = index,
        Rcpp::Named("name") = name,
        Rcpp::Named("kind") = kind,
        Rcpp::Named("n_children") = n_children,
        Rcpp::Named("stringsAsFactors") = false);
}

// One row per child (Clip or Gap) in a track, with source_range as
// (start value, rate, duration value) in the range's own rate.
// [[Rcpp::export]]
Rcpp::DataFrame otio_track_clips_df(SEXP track) {
    otio::Track* tr = unwrap_otio<otio::Track>(track);
    std::vector<int> index;
    std::vector<std::string> name, kind, target_url;
    std::vector<double> start, rate, duration;
    int i = 0;
    for (auto const& child : tr->children()) {
        otio::Composable* comp = child;
        std::string knd = "Other", nm = comp ? comp->name() : std::string();
        std::string url;
        double sv = NA_REAL, sr = NA_REAL, dv = NA_REAL;
        std::optional<TimeRange> srng;
        if (otio::Clip* c = dynamic_cast<otio::Clip*>(comp)) {
            knd = "Clip";
            if (auto ext =
                    dynamic_cast<otio::ExternalReference*>(c->media_reference())) {
                url = ext->target_url();
            }
            srng = c->source_range();
        } else if (otio::Gap* g = dynamic_cast<otio::Gap*>(comp)) {
            knd = "Gap";
            srng = g->source_range();
        }
        if (srng) {
            sv = srng->start_time().value();
            sr = srng->start_time().rate();
            dv = srng->duration().value();
        }
        index.push_back(i++);
        name.push_back(nm);
        kind.push_back(knd);
        target_url.push_back(url);
        start.push_back(sv);
        rate.push_back(sr);
        duration.push_back(dv);
    }
    return Rcpp::DataFrame::create(
        Rcpp::Named("index") = index,
        Rcpp::Named("name") = name,
        Rcpp::Named("kind") = kind,
        Rcpp::Named("target_url") = target_url,
        Rcpp::Named("start") = start,
        Rcpp::Named("rate") = rate,
        Rcpp::Named("duration") = duration,
        Rcpp::Named("stringsAsFactors") = false);
}
