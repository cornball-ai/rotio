// Rcpp shim over opentime::RationalTime (OpenTimelineIO's time type).
//
// This is the first piece of nle.api's C++ wrap. Its job in PR 1 is to prove
// the build chain end to end: the linker finds libopentime, an OTIO value
// object can be heap-allocated, carried through R as an external pointer, and
// have its real OTIO methods (rescaling, timecode) called from R.
//
// opentime::RationalTime is a value type of (value, rate) doubles. We map it
// onto nle.api's (num, den) naming: value == num, rate == den. The object is
// heap-allocated and owned by an Rcpp::XPtr finalizer (default `delete`).

#include <Rcpp.h>
#include <opentime/rationalTime.h>
#include <opentime/errorStatus.h>

using opentime::RationalTime;
using opentime::ErrorStatus;
using opentime::IsDropFrameRate;

typedef Rcpp::XPtr<RationalTime> RTPtr;

// [[Rcpp::export]]
SEXP otio_rt_create(double value, double rate) {
    if (!(rate > 0)) {
        Rcpp::stop("rational_time: rate (den) must be > 0; got %f", rate);
    }
    RationalTime* rt = new RationalTime(value, rate);
    return RTPtr(rt, true);
}

// [[Rcpp::export]]
double otio_rt_value(SEXP ptr) {
    RTPtr rt(ptr);
    return rt->value();
}

// [[Rcpp::export]]
double otio_rt_rate(SEXP ptr) {
    RTPtr rt(ptr);
    return rt->rate();
}

// [[Rcpp::export]]
double otio_rt_to_seconds(SEXP ptr) {
    RTPtr rt(ptr);
    return rt->to_seconds();
}

// [[Rcpp::export]]
int otio_rt_to_frames(SEXP ptr, double rate) {
    RTPtr rt(ptr);
    return rt->to_frames(rate);
}

// Rescale to a new rate, returning a fresh wrapped RationalTime. Proves an
// XPtr can be consumed and a new one returned.
// [[Rcpp::export]]
SEXP otio_rt_rescaled_to(SEXP ptr, double new_rate) {
    if (!(new_rate > 0)) {
        Rcpp::stop("rescaled_to: new_rate must be > 0; got %f", new_rate);
    }
    RTPtr rt(ptr);
    RationalTime* out = new RationalTime(rt->rescaled_to(new_rate));
    return RTPtr(out, true);
}

// SMPTE timecode string at the given rate. A non-trivial OTIO routine that a
// hand-rolled R implementation would have to reproduce (drop-frame rules,
// rate validation), so it demonstrates the real payoff of binding the library.
// [[Rcpp::export]]
std::string otio_rt_to_timecode(SEXP ptr, double rate) {
    RTPtr rt(ptr);
    ErrorStatus err;
    std::string tc = rt->to_timecode(rate, IsDropFrameRate::InferFromRate, &err);
    if (is_error(err)) {
        Rcpp::stop("to_timecode: %s", err.details);
    }
    return tc;
}

// The OTIO version this build links against, for diagnostics.
// [[Rcpp::export]]
std::string otio_opentime_version() {
    return std::to_string(OPENTIME_VERSION_MAJOR) + "." +
           std::to_string(OPENTIME_VERSION_MINOR) + "." +
           std::to_string(OPENTIME_VERSION_PATCH);
}
