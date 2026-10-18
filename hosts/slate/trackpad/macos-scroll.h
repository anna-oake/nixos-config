/*
 * Empirical scroll response for Mac14,5, macOS 26.5.1, 2026-10-17.
 * Input: physical mm and monotonic seconds. Output: Mac logical points.
 * The finger-down speed knots describe window-averaged AppKit output, including
 * its small-motion quantisation; they are not Apple's internal HID coefficients.
 * Momentum profiles contain cumulative travel from uninterrupted recorded flicks,
 * indexed by the preceding 80 ms of scrolling. Interpolation preserves positive
 * travel and gives consistent distance at different delivery/report rates.
 * This is a measured approximation, not event-for-event macOS equivalence.
 * SPDX-License-Identifier: MIT
 */
#ifndef SLATE_MACOS_SCROLL_H
#define SLATE_MACOS_SCROLL_H
#include <math.h>
#include <stdbool.h>
#include <string.h>

#define SLATE_SCROLL_SCALE ((301.78 / 1800.0) / (290.0 / 1504.0))
#define SLATE_SCROLL_HISTORY 32
struct slate_scroll_sample { double time, x, y; };
struct slate_scroll {
    double time, speed, dx, dy;
    struct slate_scroll_sample history[SLATE_SCROLL_HISTORY];
    unsigned int count;
    bool active;
    double start, previous, duration, distance, direction_x, direction_y, blend;
    unsigned int lower, upper;
};
struct slate_scroll_profile {
    double speed, duration, distance, cumulative[21];
};
static const struct slate_scroll_profile slate_scroll_profiles[] = {
    { 265.542396, 0.517241, 64.000000, { 0.00000000, 0.11440019, 0.22662090, 0.33733974, 0.43519107, 0.53188983, 0.62898666, 0.70980073, 0.76130592, 0.80951071, 0.85107392, 0.87501249, 0.89914960, 0.92424314, 0.94281815, 0.95474730, 0.96682465, 0.97894314, 0.98776012, 0.99389191, 1.00000000 } },
    { 580.983828, 0.734842, 203.000000, { 0.00000000, 0.12254594, 0.26638336, 0.39694180, 0.50779770, 0.59585657, 0.66689891, 0.73097579, 0.79020543, 0.83347084, 0.87783706, 0.90859006, 0.92982482, 0.95161298, 0.96426089, 0.97529691, 0.98303925, 0.98858890, 0.99407445, 0.99728598, 1.00000000 } },
    { 1007.066374, 0.901079, 490.000000, { 0.00000000, 0.14690855, 0.32548351, 0.46453525, 0.57963264, 0.67005726, 0.73982642, 0.79511834, 0.83886905, 0.87230770, 0.90658765, 0.93063795, 0.95162867, 0.96564743, 0.97674207, 0.98468644, 0.99019182, 0.99377267, 0.99653119, 0.99862384, 1.00000000 } },
    { 2691.771637, 1.134303, 1404.000000, { 0.00000000, 0.19494426, 0.37868924, 0.52829114, 0.64612999, 0.73108442, 0.80414705, 0.85330271, 0.89113164, 0.91899474, 0.93887750, 0.95339634, 0.96749347, 0.97720129, 0.98637522, 0.99144958, 0.99458988, 0.99702252, 0.99803839, 0.99928775, 1.00000000 } },
    { 4699.237493, 1.310268, 3393.500000, { 0.00000000, 0.20744739, 0.36835880, 0.50590449, 0.62618151, 0.72373038, 0.79773902, 0.85587592, 0.89874045, 0.92781095, 0.94945704, 0.96480894, 0.97510228, 0.98252897, 0.98870424, 0.99327712, 0.99629776, 0.99799253, 0.99913547, 0.99971399, 1.00000000 } },
    { 6785.100576, 1.310268, 3393.500000, { 0.00000000, 0.21451821, 0.38041869, 0.52337721, 0.64462587, 0.73895470, 0.81299724, 0.86815654, 0.90807777, 0.93585189, 0.95776273, 0.97079186, 0.97898883, 0.98591258, 0.99099767, 0.99494792, 0.99713087, 0.99831398, 0.99914013, 0.99971179, 1.00000000 } },
    { 8090.434967, 1.435196, 4596.000000, { 0.00000000, 0.21229932, 0.37070949, 0.50723141, 0.62291819, 0.72077976, 0.79841143, 0.85731084, 0.90102807, 0.93208837, 0.95352618, 0.96783028, 0.97787150, 0.98455174, 0.99014336, 0.99398043, 0.99665367, 0.99828481, 0.99922702, 0.99975217, 1.00000000 } },
    { 8694.406217, 1.469552, 4859.000000, { 0.00000000, 0.21071488, 0.37180253, 0.50945308, 0.62435594, 0.72073220, 0.79954061, 0.85902915, 0.90334007, 0.93449487, 0.95562318, 0.96973148, 0.97968987, 0.98598397, 0.99134448, 0.99497978, 0.99693871, 0.99854723, 0.99931376, 0.99976505, 1.00000000 } },
    { 11685.395992, 1.518343, 5445.000000, { 0.00000000, 0.21290170, 0.37059157, 0.50605146, 0.62109186, 0.71752564, 0.79645216, 0.85712960, 0.90210073, 0.93344977, 0.95460891, 0.96900072, 0.97920673, 0.98552104, 0.99054370, 0.99398503, 0.99680093, 0.99840983, 0.99924636, 0.99976670, 1.00000000 } },
};

static inline double
slate_scroll_speed(double speed)
{
    /* Finger mm/s -> measured logical points/s. Preserve the low-speed plateau
     * without rounding every Surface report up to a whole Mac point. */
    static const double v[] = {0, 4.8, 10, 22.5, 36, 50, 75, 110, 135, 175, 215, 275};
    static const double p[] = {0, 125, 220, 225, 280, 355, 550, 825, 1060, 1670, 2065, 2950};
    if (!(speed > 0) || !isfinite(speed))
        return 0;
    for (unsigned int i = 1; i < sizeof(v) / sizeof(v[0]); i++) {
        if (speed <= v[i])
            return p[i-1] + (p[i]-p[i-1]) * (speed-v[i-1]) / (v[i]-v[i-1]);
    }
    /* Outside the captured range, retain the last measured gain. */
    return speed * p[11] / v[11];
}

static inline void
slate_scroll_filter(struct slate_scroll *s, double x, double y, double now,
                    double *out_x, double *out_y)
{
    const double distance = hypot(x, y);
    /* Empty reports must not shorten the interval used for the next movement.
     * This matters when slow motion advances fewer than one sensor unit/frame. */
    if (!(distance > 0) || !isfinite(distance)) {
        *out_x = *out_y = 0;
        return;
    }
    double dt = now - s->time;
    bool fresh = !s->time || dt <= 0 || dt > .080 || x*s->dx + y*s->dy < 0;
    if (fresh) {
        dt = 1.0 / 135.0;
        s->speed = 0;
        s->count = 0;
    }
    s->time = now;
    s->dx = x;
    s->dy = y;
    double speed = distance / dt;
    s->speed = fresh ? speed : s->speed + (speed-s->speed) * (1-exp(-dt/.020));
    double gain = slate_scroll_speed(s->speed) / s->speed;
    *out_x = x * gain;
    *out_y = y * gain;
}

static inline void
slate_scroll_record(struct slate_scroll *s, double x, double y, double now)
{
    if (s->count == SLATE_SCROLL_HISTORY) {
        memmove(s->history, s->history + 1,
                (SLATE_SCROLL_HISTORY - 1) * sizeof(s->history[0]));
        s->count--;
    }
    s->history[s->count++] = (struct slate_scroll_sample){now, x, y};
}

static inline bool
slate_scroll_launch(struct slate_scroll *s, double now)
{
    if (s->count < 3 || now - s->history[s->count-1].time > .025)
        return false;
    unsigned int first = 0, last = s->count-1;
    while (first < last && now - s->history[first].time > .080)
        first++;
    double dt = s->history[last].time - s->history[first].time;
    if (dt < .020)
        return false;
    double x = 0, y = 0;
    for (unsigned int i = first+1; i <= last; i++) {
        x += s->history[i].x;
        y += s->history[i].y;
    }
    double length = hypot(x, y), speed = length / dt;
    if (speed < 250 || !isfinite(speed))
        return false;
    const unsigned int n = sizeof(slate_scroll_profiles) / sizeof(slate_scroll_profiles[0]);
    unsigned int hi = 0;
    while (hi+1 < n && speed > slate_scroll_profiles[hi].speed)
        hi++;
    unsigned int lo = hi ? hi-1 : 0;
    double blend = hi == lo ? 0 : fmin(1, fmax(0,
        (speed-slate_scroll_profiles[lo].speed) /
        (slate_scroll_profiles[hi].speed-slate_scroll_profiles[lo].speed)));
    s->lower = lo;
    s->upper = hi;
    s->blend = blend;
    s->duration = (1-blend)*slate_scroll_profiles[lo].duration + blend*slate_scroll_profiles[hi].duration;
    s->distance = (1-blend)*slate_scroll_profiles[lo].distance + blend*slate_scroll_profiles[hi].distance;
    if (speed < slate_scroll_profiles[0].speed)
        s->distance *= speed / slate_scroll_profiles[0].speed;
    if (speed > slate_scroll_profiles[n-1].speed)
        s->distance *= fmin(speed / slate_scroll_profiles[n-1].speed, 2);
    s->direction_x = x / length;
    s->direction_y = y / length;
    s->start = s->previous = now;
    s->active = true;
    return true;
}

static inline double
slate_scroll_cumulative(unsigned int profile, double fraction)
{
    const double *p = slate_scroll_profiles[profile].cumulative;
    if (fraction <= 0) return 0;
    if (fraction >= 1) return 1;
    double position = fraction * 20;
    unsigned int i = (unsigned int)position;
    double t = position-i, d = p[i+1]-p[i];
    double before = i ? p[i]-p[i-1] : d;
    double after = i < 19 ? p[i+2]-p[i+1] : 0;
    double m0 = before > 0 && d > 0 ? 2*before*d/(before+d) : 0;
    double m1 = after > 0 && d > 0 ? 2*after*d/(after+d) : 0;
    return (2*t*t*t-3*t*t+1)*p[i] + (t*t*t-2*t*t+t)*m0
         + (-2*t*t*t+3*t*t)*p[i+1] + (t*t*t-t*t)*m1;
}

static inline bool
slate_scroll_tick(struct slate_scroll *s, double now, double *x, double *y)
{
    *x = *y = 0;
    if (!s->active || now <= s->previous)
        return s->active;
    /* Do not dump accumulated travel after a compositor stall/suspend. */
    if (now-s->previous > .100) {
        s->active = false;
        return false;
    }
    double a = (s->previous-s->start) / s->duration;
    double b = (now-s->start) / s->duration;
    double delta = (1-s->blend)*(slate_scroll_cumulative(s->lower,b)-slate_scroll_cumulative(s->lower,a))
                 + s->blend*(slate_scroll_cumulative(s->upper,b)-slate_scroll_cumulative(s->upper,a));
    delta = fmax(0, delta) * s->distance;
    *x = delta*s->direction_x;
    *y = delta*s->direction_y;
    s->previous = now;
    s->active = b < 1;
    return s->active;
}
#endif
