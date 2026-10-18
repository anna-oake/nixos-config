/*
 * Mac14,5 (14-inch M2 Max), tracking speed 0.6875, macOS 26.5.1.
 * Apple IOHIDFamily's public parametric curve, with the observed integer-count
 * input model from Trackpad Plus (MIT, Andrew Kent / David Fano):
 * https://github.com/davefano/omarchy-trackpad-plus/blob/34646090e7c516d8a3a801621767b2052f4d3858/pointer_profiles.py
 *
 * Evaluate the model directly instead of sampling into 64 libinput points.
 * The reference reports 400 counts/inch at 124.9 events/s, with a 120 Hz HID
 * report-rate clamp. Averaging its count quantisation preserves the measured
 * speed response on Slate's different-resolution, ~135 Hz touchpad without
 * buffering events or adding a resampling delay.
 *
 * Copyright (c) 2026 Andrew Kent
 * Copyright (c) 2026 David Fano
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
#ifndef SLATE_MACOS_POINTER_H
#define SLATE_MACOS_POINTER_H

#include <math.h>

static inline double
slate_mac_polynomial(double x)
{
    const double linear = 62915.0 / 65536.0;
    const double parabolic = 54395.0 / 65536.0;
    const double cubic = 7864.0 / 65536.0;
    return linear * x + pow(parabolic * x, 2) + pow(cubic * x, 3);
}

static inline double
slate_mac_curve(double x)
{
    const double tangent = 465306.0 / 65536.0;
    const double root = 18.0;
    const double linear = 62915.0 / 65536.0;
    const double parabolic = 54395.0 / 65536.0;
    const double cubic = 7864.0 / 65536.0;
    const double slope = linear + 2 * tangent * parabolic * parabolic
                         + 3 * tangent * tangent * pow(cubic, 3);
    const double offset = slate_mac_polynomial(tangent) - slope * tangent;
    if (x <= tangent)
        return slate_mac_polynomial(x);
    if (x <= root)
        return slope * x + offset;
    const double y = slope * root + offset;
    return sqrt(fmax(0, 2 * y * slope * x + y * y - 2 * y * slope * root));
}

static inline double
slate_mac_count_gain(double count, double rate_multiplier)
{
    const double velocity = fmax(count * rate_multiplier, 1.0 / 65536.0);
    return slate_mac_curve(velocity * 67.0 / 400.0) * (96.0 / 67.0) / velocity;
}

/* Physical finger speed in inches/s -> macOS logical points/s. */
static inline double
slate_mac_cursor_speed(double inches_per_second)
{
    const double rate = 124.9;
    const double counts = 400.0 * inches_per_second / rate;
    if (!(counts > 0) || !isfinite(counts))
        return 0;
    if (counts >= 1) {
        const double whole = floor(counts), part = counts - whole;
        return rate * ((1 - part) * whole * slate_mac_count_gain(whole, 1)
                       + part * (whole + 1) * slate_mac_count_gain(whole + 1, 1));
    }
    /* At low speeds, zero-count frames are omitted; the next event carries
     * the resulting longer timestamp gap through Apple's rate clamp. */
    const double gap = 1.0 / counts, whole = floor(gap), part = gap - whole;
    const double gain = (1 - part) * slate_mac_count_gain(1, fmin(rate / 120.0 / whole, 1))
                        + part * slate_mac_count_gain(1, fmin(rate / 120.0 / (whole + 1), 1));
    return rate * counts * gain;
}

static inline double
slate_mac_pointer_factor(double distance, double dpi, double seconds)
{
    /* Preserve physical cursor travel: Mac 301.78 mm / 1800 points,
     * Surface 290 mm / (2256 physical pixels / 1.5 output scale). */
    const double output_scale = (301.78 / 1800.0) / (290.0 / 1504.0);
    if (!(distance > 0) || !(dpi > 0))
        return 0;
    /* Apple gives the first event after a pause near-minimum gain. Do not
     * turn the time since the preceding stroke into a velocity estimate. */
    if (!(seconds > 0) || seconds > 0.080)
        return (62915.0 / 65536.0) * 96.0 / dpi * output_scale;
    return slate_mac_cursor_speed(distance / dpi / seconds) * seconds
           / distance * output_scale;
}

#endif
