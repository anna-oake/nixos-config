/* Included by evdev-mt-touchpad-gestures.c; only this device owns its inertia.
 * Use CONTINUOUS for the complete stream so clients do not launch an additional
 * finger-scroll fling. Niri forwards the explicit axis-stop at its end.
 * SPDX-License-Identifier: MIT
 */
static enum libinput_pointer_axis_source
tp_mac_scroll_source(struct tp_dispatch *tp)
{
    return tp->mac_scroll.enabled ? LIBINPUT_POINTER_AXIS_SOURCE_CONTINUOUS
                                  : LIBINPUT_POINTER_AXIS_SOURCE_FINGER;
}

/* One device-wide output gain for Linux clients, shared by finger motion and
 * momentum. This is a compatibility calibration, not a Wayland unit definition.
 * Keep the measured model, launch history and axis thresholds in their original
 * units; scale only when publishing the final event. */
#define SLATE_SCROLL_OUTPUT_GAIN 0.1

static void
tp_mac_scroll_emit(struct tp_dispatch *tp,
                   const struct normalized_coords *delta, usec_t time)
{
    evdev_post_scroll_scaled(tp->device, time, tp_mac_scroll_source(tp), delta,
                            tp->mac_scroll.enabled ? SLATE_SCROLL_OUTPUT_GAIN : 1.0);
}

void
tp_mac_scroll_cancel(struct tp_dispatch *tp, usec_t time)
{
    if (!tp->mac_scroll.enabled)
        return;
    /* The contact that catches a fling is not a tap-click. Keep this flag
     * outside the reset model until every finger in that contact lifts. */
    if (tp->mac_scroll.model.active && tp->nfingers_down)
        tp->mac_scroll.consume_tap = true;
    libinput_timer_cancel(&tp->mac_scroll.timer);
    if (tp->mac_scroll.model.active)
        evdev_stop_scroll(tp->device, time, tp_mac_scroll_source(tp));
    memset(&tp->mac_scroll.model, 0, sizeof(tp->mac_scroll.model));
}

static void
tp_mac_scroll_timeout(usec_t now, void *data)
{
    struct tp_dispatch *tp = data;
    if (tp->nfingers_down || tp->buttons.state || tp->device->is_suspended ||
        tp->dwt.keyboard_active || tp->palm.trackpoint_active) {
        tp_mac_scroll_cancel(tp, now);
        return;
    }
    struct normalized_coords delta;
    bool active = slate_scroll_tick(&tp->mac_scroll.model,
                                   usec_as_uint64_t(now) / 1000000.0,
                                   &delta.x, &delta.y);
    delta.x *= SLATE_SCROLL_SCALE;
    delta.y *= SLATE_SCROLL_SCALE;
    if (!normalized_is_zero(delta))
        tp_mac_scroll_emit(tp, &delta, now);
    if (active)
        libinput_timer_set(&tp->mac_scroll.timer,
                          usec_add(now, usec_from_uint64_t(8333)));
    else {
        evdev_stop_scroll(tp->device, now, tp_mac_scroll_source(tp));
        tp_mac_scroll_cancel(tp, now);
    }
}

static void
tp_mac_scroll_init(struct tp_dispatch *tp)
{
    tp->mac_scroll.enabled =
        libevdev_get_id_vendor(tp->device->evdev) == 0x045e &&
        libevdev_get_id_product(tp->device->evdev) == 0x09af;
    libinput_timer_init(&tp->mac_scroll.timer, tp_libinput_context(tp),
                        "slate-macos-scroll", tp_mac_scroll_timeout, tp);
}

static bool
tp_mac_scroll_launch(struct tp_dispatch *tp, usec_t time)
{
    if (!tp->mac_scroll.enabled || tp->nfingers_down || tp->buttons.state ||
        tp->device->is_suspended || tp->dwt.keyboard_active ||
        tp->palm.trackpoint_active || !tp->device->scroll.direction)
        return false;
    if (!slate_scroll_launch(&tp->mac_scroll.model,
                             usec_as_uint64_t(time) / 1000000.0))
        return false;
    libinput_timer_set(&tp->mac_scroll.timer,
                      usec_add(time, usec_from_uint64_t(8333)));
    return true;
}

static struct normalized_coords
tp_mac_scroll_filter(struct tp_dispatch *tp,
                     const struct device_float_coords *raw, usec_t time)
{
    if (!tp->mac_scroll.enabled)
        return tp_filter_scroll(tp, raw, time);
    struct phys_coords mm = tp_phys_delta(tp, *raw);
    struct normalized_coords delta;
    slate_scroll_filter(&tp->mac_scroll.model, mm.x, mm.y,
                        usec_as_uint64_t(time) / 1000000.0, &delta.x, &delta.y);
    delta.x *= SLATE_SCROLL_SCALE;
    delta.y *= SLATE_SCROLL_SCALE;
    return delta;
}

static void
tp_mac_scroll_post(struct tp_dispatch *tp,
                   struct normalized_coords *delta, usec_t time)
{
    if (tp->mac_scroll.enabled) {
        /* Match evdev's axis lock before remembering the launch direction. */
        struct normalized_coords motion = *delta;
        if (!(tp->device->scroll.direction & bit(LIBINPUT_POINTER_AXIS_SCROLL_HORIZONTAL)))
            motion.x = 0;
        if (!(tp->device->scroll.direction & bit(LIBINPUT_POINTER_AXIS_SCROLL_VERTICAL)))
            motion.y = 0;
        if (!normalized_is_zero(motion))
            slate_scroll_record(&tp->mac_scroll.model,
                                motion.x / SLATE_SCROLL_SCALE,
                                motion.y / SLATE_SCROLL_SCALE,
                                usec_as_uint64_t(time) / 1000000.0);
    }
}
