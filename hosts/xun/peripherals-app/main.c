#define _POSIX_C_SOURCE 200809L
#include <gtk/gtk.h>
#include <glib/gstdio.h>
#include <signal.h>

typedef struct {
    GtkWidget *canvas;
    GtkLabel *touch_count;
    GtkLabel *keys;
    GHashTable *touches;
    guint peak;
    gboolean touchscreen_present;
    gboolean touch_started;
    gboolean keys_started;

    GtkWidget *audio_buttons[4];
    GtkRange *volume;
    GtkLabel *audio_status;
    GSubprocess *audio;
    guint record_timer;
    char *scratch;
    char *recording;
    gboolean recorded;

    GtkWidget *swatch;
    GtkLabel *color_name;
    GtkLabel *brightness;
    guint color;

    GtkLabel *status;
    GDBusProxy *battery;
    GDBusProxy *bluetooth;
} App;

#define RECORD_SAMPLES 192000

typedef graphene_point_t Contact;

typedef struct {
    GtkWidget parent;
    GHashTable *touches;
} TouchCanvas;

typedef GtkWidgetClass TouchCanvasClass;

G_DEFINE_TYPE(TouchCanvas, touch_canvas, GTK_TYPE_WIDGET)

static void touch_canvas_snapshot(GtkWidget *widget, GtkSnapshot *snapshot)
{
    TouchCanvas *canvas = (TouchCanvas *)widget;
    float width = gtk_widget_get_width(widget);
    float height = gtk_widget_get_height(widget);
    const GdkRGBA background = { .07, .11, .13, 1 };
    const GdkRGBA grid = { .24, .31, .33, 1 };
    const GdkRGBA dot = { .54, .94, .81, 1 };

    gtk_snapshot_append_color(snapshot, &background, &GRAPHENE_RECT_INIT(0, 0, width, height));
    for (int i = 1; i < 8; i++) {
        gtk_snapshot_append_color(snapshot, &grid, &GRAPHENE_RECT_INIT(width * i / 8, 0, 1, height));
        gtk_snapshot_append_color(snapshot, &grid, &GRAPHENE_RECT_INIT(0, height * i / 8, width, 1));
    }

    GHashTableIter iter;
    gpointer item;
    g_hash_table_iter_init(&iter, canvas->touches);
    while (g_hash_table_iter_next(&iter, NULL, &item)) {
        Contact *contact = item;
        graphene_rect_t bounds = GRAPHENE_RECT_INIT(contact->x - 26, contact->y - 26, 52, 52);
        GskRoundedRect circle;
        gsk_rounded_rect_init_from_rect(&circle, &bounds, 26);
        gtk_snapshot_push_rounded_clip(snapshot, &circle);
        gtk_snapshot_append_color(snapshot, &dot, &bounds);
        gtk_snapshot_pop(snapshot);
    }
}

static void touch_canvas_class_init(TouchCanvasClass *class)
{
    class->snapshot = touch_canvas_snapshot;
}

static void touch_canvas_init(TouchCanvas *canvas)
{
    gtk_widget_set_overflow(GTK_WIDGET(canvas), GTK_OVERFLOW_HIDDEN);
}

static const struct {
    const char *name;
    double r, g, b;
} colors[] = {
    { "White", 1, 1, 1 }, { "Black", 0, 0, 0 }, { "Red", 1, 0, 0 },
    { "Green", 0, 1, 0 }, { "Blue", 0, 0, 1 }, { "Gray", 0.5, 0.5, 0.5 },
};

static GtkLabel *label(GtkBox *box, const char *text)
{
    GtkLabel *result = GTK_LABEL(gtk_label_new(text));
    gtk_label_set_xalign(result, 0);
    gtk_label_set_wrap(result, TRUE);
    gtk_box_append(box, GTK_WIDGET(result));
    return result;
}

static GtkButton *button(GtkBox *box, const char *text, GCallback clicked, App *app)
{
    GtkButton *result = GTK_BUTTON(gtk_button_new_with_label(text));
    gtk_widget_set_size_request(GTK_WIDGET(result), -1, 52);
    g_signal_connect(result, "clicked", clicked, app);
    gtk_box_append(box, GTK_WIDGET(result));
    return result;
}

static GtkBox *page(GtkStack *stack, const char *name, const char *title)
{
    GtkBox *box = GTK_BOX(gtk_box_new(GTK_ORIENTATION_VERTICAL, 14));
    gtk_stack_add_titled(stack, GTK_WIDGET(box), name, title);
    return box;
}

static void update_touches(App *app)
{
    guint count = g_hash_table_size(app->touches);
    app->peak = MAX(app->peak, count);
    g_autofree char *text = g_strdup_printf(
        "%u down  /  %u peak%s", count, app->peak,
        app->touchscreen_present ? "" : "  ·  No touchscreen reported by Wayland");
    gtk_label_set_text(app->touch_count, text);
    gtk_widget_queue_draw(app->canvas);
}

static void start_touch(GtkButton *sender, gpointer data)
{
    App *app = data;
    app->touch_started = TRUE;
    app->peak = 0;
    g_hash_table_remove_all(app->touches);
    gtk_button_set_label(sender, "Reset touch count");
    update_touches(app);
}

static gboolean touch_event(GtkEventControllerLegacy *controller, GdkEvent *event, gpointer data)
{
    (void)controller;
    App *app = data;
    if (!app->touch_started)
        return FALSE;
    GdkEventType type = gdk_event_get_event_type(event);
    GdkEventSequence *sequence = gdk_event_get_event_sequence(event);
    gboolean count_changed;
    if (type == GDK_TOUCH_END || type == GDK_TOUCH_CANCEL) {
        count_changed = g_hash_table_remove(app->touches, sequence);
    } else if (type == GDK_TOUCH_BEGIN || type == GDK_TOUCH_UPDATE) {
        double x, y, tx, ty;
        GtkNative *native = gtk_widget_get_native(app->canvas);
        graphene_point_t local;
        if (!gdk_event_get_position(event, &x, &y))
            return FALSE;
        gtk_native_get_surface_transform(native, &tx, &ty);
        graphene_point_t surface = GRAPHENE_POINT_INIT(x + tx, y + ty);
        if (!gtk_widget_compute_point(GTK_WIDGET(native), app->canvas, &surface, &local))
            return FALSE;
        Contact *contact = g_hash_table_lookup(app->touches, sequence);
        count_changed = !contact || !app->touchscreen_present;
        if (!contact) {
            contact = g_new(Contact, 1);
            g_hash_table_insert(app->touches, sequence, contact);
        }
        *contact = local;
        app->touchscreen_present = TRUE;
    } else {
        return FALSE;
    }
    if (count_changed)
        update_touches(app);
    else
        gtk_widget_queue_draw(app->canvas);
    return TRUE;
}

static void touchscreen_changed(GdkSeat *seat, GdkDevice *device, gpointer data)
{
    (void)device;
    App *app = data;
    app->touchscreen_present = (gdk_seat_get_capabilities(seat) & GDK_SEAT_CAPABILITY_TOUCH) != 0;
    if (!app->touchscreen_present)
        g_hash_table_remove_all(app->touches);
    update_touches(app);
}

static gboolean key_pressed(GtkEventControllerKey *controller, guint keyval,
                            guint keycode, GdkModifierType modifiers, gpointer data)
{
    (void)controller;
    (void)modifiers;
    App *app = data;
    if (!app->keys_started)
        return FALSE;
    const char *name = gdk_keyval_name(keyval);
    g_autofree char *text = g_strdup_printf("Last key  ·  %s (%u)", name ? name : "Unknown key", keycode);
    gtk_label_set_text(app->keys, text);
    return FALSE;
}

static void start_keys(GtkButton *sender, gpointer data)
{
    App *app = data;
    app->keys_started = TRUE;
    gtk_button_set_label(sender, "Reset key test");
    gtk_label_set_text(app->keys, "Waiting for a key…");
}

static void audio_controls(App *app)
{
    for (guint i = 0; i < G_N_ELEMENTS(app->audio_buttons); i++)
        gtk_widget_set_sensitive(app->audio_buttons[i], !app->audio && (i != 3 || app->recorded));
    gtk_widget_set_sensitive(GTK_WIDGET(app->volume), !app->audio);
}

static gboolean stop_recording(gpointer data)
{
    App *app = data;
    app->record_timer = 0;
    g_subprocess_send_signal(app->audio, SIGINT);
    return G_SOURCE_REMOVE;
}

static void audio_done(GObject *object, GAsyncResult *result, gpointer data)
{
    App *app = data;
    GSubprocess *process = G_SUBPROCESS(object);
    g_autoptr(GError) error = NULL;
    g_autofree char *stderr_text = NULL;
    gboolean recording = GPOINTER_TO_INT(g_object_get_data(object, "recording"));
    if (app->record_timer)
        g_clear_handle_id(&app->record_timer, g_source_remove);

    gboolean communicated = g_subprocess_communicate_utf8_finish(
        process, result, NULL, &stderr_text, &error);
    GStatBuf info;
    /* pw-record exits nonzero even after saving all requested samples. */
    if (recording && communicated && g_stat(app->recording, &info) == 0 &&
        info.st_size >= 44 + RECORD_SAMPLES * 2) {
        app->recorded = TRUE;
        gtk_label_set_text(app->audio_status, "Recording ready. Tap Play recording.");
    } else if (!recording && communicated && g_subprocess_get_successful(process)) {
        gtk_label_set_text(app->audio_status, "Playback finished.");
    } else {
        const char *detail = error ? error->message : stderr_text;
        if (recording && (!detail || !*detail))
            detail = "The microphone did not deliver four seconds of audio.";
        g_autofree char *message = g_strdup_printf("%s failed%s%s", recording ? "Recording" : "Playback",
                                                  detail && *detail ? " · " : "", detail ? detail : "");
        gtk_label_set_text(app->audio_status, message);
    }
    g_clear_object(&app->audio);
    audio_controls(app);
}

static void audio_action(GtkButton *sender, gpointer data)
{
    App *app = data;
    const char *file = g_object_get_data(G_OBJECT(sender), "file");
    gboolean recording = GTK_WIDGET(sender) == app->audio_buttons[2];
    if (!file)
        file = app->recording;
    if (!file) {
        gtk_label_set_text(app->audio_status, "Could not create a temporary recording directory.");
        return;
    }

    g_autoptr(GError) error = NULL;
    const char *record[] = {
        PIPEWIRE_BIN "/pw-record", "--rate=48000", "--channels=1", "--channel-map=FL",
        "--format=s16", "--sample-count=" G_STRINGIFY(RECORD_SAMPLES), file, NULL
    };
    char level[G_ASCII_DTOSTR_BUF_SIZE];
    g_ascii_formatd(level, sizeof(level), "%.2f", gtk_range_get_value(app->volume) / 100.0);
    const char *play[] = { PIPEWIRE_BIN "/pw-play", "--volume", level, file, NULL };
    if (recording) {
        app->recorded = FALSE;
        g_unlink(app->recording);
    }
    app->audio = g_subprocess_newv(recording ? record : play, G_SUBPROCESS_FLAGS_STDERR_PIPE, &error);
    if (!app->audio) {
        gtk_label_set_text(app->audio_status, error->message);
        audio_controls(app);
        return;
    }
    g_object_set_data(G_OBJECT(app->audio), "recording", GINT_TO_POINTER(recording));
    if (recording)
        app->record_timer = g_timeout_add_seconds(8, stop_recording, app);
    audio_controls(app);
    gtk_label_set_text(app->audio_status, recording ? "Recording for four seconds…" : "Playing…");
    g_subprocess_communicate_utf8_async(app->audio, NULL, NULL, audio_done, app);
}

static char *format_volume(GtkScale *scale, double value, gpointer data)
{
    (void)scale;
    (void)data;
    return g_strdup_printf("%.0f%%", value);
}

static void draw_color(GtkDrawingArea *area, cairo_t *cr, int w, int h, gpointer data)
{
    (void)area;
    (void)w;
    (void)h;
    App *app = data;
    cairo_set_source_rgb(cr, colors[app->color].r, colors[app->color].g, colors[app->color].b);
    cairo_paint(cr);
}

static void next_color(GtkButton *sender, gpointer data)
{
    (void)sender;
    App *app = data;
    app->color = (app->color + 1) % G_N_ELEMENTS(colors);
    gtk_widget_queue_draw(app->swatch);
    gtk_label_set_text(app->color_name, colors[app->color].name);
}

static void brightness_done(GObject *object, GAsyncResult *result, gpointer data)
{
    GtkLabel *status = data;
    g_autoptr(GError) error = NULL;
    g_autoptr(GVariant) reply = g_dbus_connection_call_finish(G_DBUS_CONNECTION(object), result, &error);
    gtk_label_set_text(status, reply ? "Brightness set." : error->message);
    g_object_unref(status);
}

static void set_brightness(GtkButton *sender, gpointer data)
{
    App *app = data;
    g_autoptr(GError) error = NULL;
    g_autoptr(GDBusConnection) bus = g_bus_get_sync(G_BUS_TYPE_SYSTEM, NULL, &error);
    if (!bus) {
        gtk_label_set_text(app->brightness, error->message);
        return;
    }
    guint level = GPOINTER_TO_UINT(g_object_get_data(G_OBJECT(sender), "level"));
    gtk_label_set_text(app->brightness, "Setting brightness…");
    g_dbus_connection_call(bus, "org.freedesktop.login1", "/org/freedesktop/login1/session/auto",
                           "org.freedesktop.login1.Session", "SetBrightness",
                           g_variant_new("(ssu)", "backlight", "5e94000.dsi.0", level),
                           NULL, G_DBUS_CALL_FLAGS_NONE, 3000, NULL,
                           brightness_done, g_object_ref(app->brightness));
}

static void update_status(App *app)
{
    g_autoptr(GVariant) state = app->battery ?
        g_dbus_proxy_get_cached_property(app->battery, "State") : NULL;
    g_autoptr(GVariant) percentage = app->battery ?
        g_dbus_proxy_get_cached_property(app->battery, "Percentage") : NULL;
    g_autoptr(GVariant) present = app->battery ?
        g_dbus_proxy_get_cached_property(app->battery, "IsPresent") : NULL;
    g_autoptr(GVariant) powered = app->bluetooth ?
        g_dbus_proxy_get_cached_property(app->bluetooth, "Powered") : NULL;

    const char *states[] = {
        "unknown", "charging", "discharging", "empty", "full", "pending charge", "pending discharge"
    };
    guint battery_state = state ? g_variant_get_uint32(state) : 0;
    const char *battery_status = battery_state < G_N_ELEMENTS(states) ? states[battery_state] : states[0];
    g_autofree char *battery = percentage && present && g_variant_get_boolean(present) ?
        g_strdup_printf("%.0f%% · %s", g_variant_get_double(percentage), battery_status) :
        g_strdup("unavailable");
    GNetworkConnectivity connection = g_network_monitor_get_connectivity(g_network_monitor_get_default());
    const char *network[] = {
        "unknown", "local", "portal", "limited", "online"
    };
    g_autofree char *text = g_strdup_printf("Battery  ·  %s\nNetwork  ·  %s\nBluetooth adapter  ·  %s",
        battery, network[connection], powered ? (g_variant_get_boolean(powered) ? "on" : "off") : "unavailable");
    gtk_label_set_text(app->status, text);
}

static void status_changed(GDBusProxy *proxy, GVariant *changed, const char *const *invalidated, gpointer data)
{
    (void)proxy;
    (void)changed;
    (void)invalidated;
    update_status(data);
}

static void network_changed(GNetworkMonitor *monitor, GParamSpec *property, gpointer data)
{
    (void)monitor;
    (void)property;
    update_status(data);
}

static void refresh_status(GtkButton *sender, gpointer data)
{
    (void)sender;
    update_status(data);
}

static GDBusProxy *watch_status(const char *name, const char *path, const char *interface, App *app)
{
    GDBusProxy *proxy = g_dbus_proxy_new_for_bus_sync(G_BUS_TYPE_SYSTEM, G_DBUS_PROXY_FLAGS_NONE,
                                                     NULL, name, path, interface, NULL, NULL);
    if (proxy)
        g_signal_connect(proxy, "g-properties-changed", G_CALLBACK(status_changed), app);
    return proxy;
}

static void activate(GtkApplication *application, gpointer data)
{
    App *app = data;
    GtkWindow *window = gtk_application_get_active_window(application);
    if (window) {
        gtk_window_present(window);
        return;
    }

    window = GTK_WINDOW(gtk_application_window_new(application));
    gtk_window_set_title(window, "Tablet peripherals");
    GtkBox *root = GTK_BOX(gtk_box_new(GTK_ORIENTATION_VERTICAL, 14));
    gtk_widget_set_margin_start(GTK_WIDGET(root), 20);
    gtk_widget_set_margin_end(GTK_WIDGET(root), 20);
    gtk_widget_set_margin_top(GTK_WIDGET(root), 20);
    gtk_widget_set_margin_bottom(GTK_WIDGET(root), 20);
    gtk_window_set_child(window, GTK_WIDGET(root));
    gtk_widget_add_css_class(GTK_WIDGET(label(root, "Tablet peripherals")), "title-1");

    GtkStack *stack = GTK_STACK(gtk_stack_new());
    gtk_stack_set_hhomogeneous(stack, FALSE);
    gtk_stack_set_vhomogeneous(stack, FALSE);
    gtk_widget_set_vexpand(GTK_WIDGET(stack), TRUE);
    gtk_box_append(root, GTK_WIDGET(stack));

    GtkBox *touch = page(stack, "touch", "Touch");
    label(touch, "Place several fingers on the grid and drag them to the edges.");
    app->touch_count = label(touch, "");
    TouchCanvas *canvas = g_object_new(touch_canvas_get_type(), NULL);
    canvas->touches = app->touches;
    app->canvas = GTK_WIDGET(canvas);
    gtk_widget_set_vexpand(app->canvas, TRUE);
    gtk_box_append(touch, app->canvas);
    GtkEventController *legacy = gtk_event_controller_legacy_new();
    g_signal_connect(legacy, "event", G_CALLBACK(touch_event), app);
    gtk_widget_add_controller(app->canvas, legacy);
    GdkSeat *seat = gdk_display_get_default_seat(gtk_widget_get_display(app->canvas));
    g_signal_connect(seat, "device-added", G_CALLBACK(touchscreen_changed), app);
    g_signal_connect(seat, "device-removed", G_CALLBACK(touchscreen_changed), app);
    touchscreen_changed(seat, NULL, app);
    button(touch, "Start touch test", G_CALLBACK(start_touch), app);

    GtkBox *audio = page(stack, "audio", "Audio");
    label(audio, "Check each audio channel. Record and play back your voice to check the microphone.");
    GtkLabel *volume_label = label(audio, "Playback volume");
    GtkWidget *volume = gtk_scale_new_with_range(GTK_ORIENTATION_HORIZONTAL, 0, 100, 1);
    app->volume = GTK_RANGE(volume);
    gtk_range_set_value(app->volume, 100);
    gtk_scale_set_draw_value(GTK_SCALE(volume), TRUE);
    gtk_scale_set_value_pos(GTK_SCALE(volume), GTK_POS_RIGHT);
    gtk_scale_set_format_value_func(GTK_SCALE(volume), format_volume, NULL, NULL);
    gtk_widget_set_size_request(volume, -1, 48);
    gtk_accessible_update_relation(GTK_ACCESSIBLE(volume), GTK_ACCESSIBLE_RELATION_LABELLED_BY,
                                   volume_label, NULL, -1);
    gtk_box_append(audio, volume);
    app->audio_status = label(audio, "Ready.");
    app->audio_buttons[0] = GTK_WIDGET(button(audio, "Play left tone", G_CALLBACK(audio_action), app));
    app->audio_buttons[1] = GTK_WIDGET(button(audio, "Play right tone", G_CALLBACK(audio_action), app));
    app->audio_buttons[2] = GTK_WIDGET(button(audio, "Record microphone", G_CALLBACK(audio_action), app));
    app->audio_buttons[3] = GTK_WIDGET(button(audio, "Play recording", G_CALLBACK(audio_action), app));
    g_object_set_data(G_OBJECT(app->audio_buttons[0]), "file", TONE_DIR "/left.wav");
    g_object_set_data(G_OBJECT(app->audio_buttons[1]), "file", TONE_DIR "/right.wav");
    audio_controls(app);

    GtkBox *display = page(stack, "display", "Display");
    app->color_name = label(display, colors[0].name);
    app->swatch = gtk_drawing_area_new();
    gtk_widget_set_vexpand(app->swatch, TRUE);
    gtk_drawing_area_set_draw_func(GTK_DRAWING_AREA(app->swatch), draw_color, app, NULL);
    gtk_box_append(display, app->swatch);
    GtkBox *display_controls = GTK_BOX(gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 8));
    gtk_box_set_homogeneous(display_controls, TRUE);
    gtk_box_append(display, GTK_WIDGET(display_controls));
    button(display_controls, "Next color", G_CALLBACK(next_color), app);
    const char *brightness_labels[] = { "10%", "50%", "100%" };
    const guint brightness_levels[] = { 205, 1024, 2047 };
    for (guint i = 0; i < G_N_ELEMENTS(brightness_labels); i++) {
        GtkButton *control = button(display_controls, brightness_labels[i], G_CALLBACK(set_brightness), app);
        g_object_set_data(G_OBJECT(control), "level", GUINT_TO_POINTER(brightness_levels[i]));
        g_autofree char *name = g_strdup_printf("%s brightness", brightness_labels[i]);
        gtk_accessible_update_property(GTK_ACCESSIBLE(control), GTK_ACCESSIBLE_PROPERTY_LABEL, name, -1);
    }
    app->brightness = label(display, "");

    GtkBox *device = page(stack, "device", "Device");
    label(device, "Press a volume or power button, or connect a keyboard. This shows the key events that reach the app.");
    app->keys = label(device, "Key test ready.");
    button(device, "Start key test", G_CALLBACK(start_keys), app);
    gtk_box_append(device, gtk_separator_new(GTK_ORIENTATION_HORIZONTAL));
    app->status = label(device, "");
    app->battery = watch_status("org.freedesktop.UPower", "/org/freedesktop/UPower/devices/DisplayDevice",
                                "org.freedesktop.UPower.Device", app);
    app->bluetooth = watch_status("org.bluez", "/org/bluez/hci0", "org.bluez.Adapter1", app);
    g_signal_connect(g_network_monitor_get_default(), "notify::connectivity", G_CALLBACK(network_changed), app);
    update_status(app);
    button(device, "Refresh status", G_CALLBACK(refresh_status), app);

    GtkEventController *keyboard = gtk_event_controller_key_new();
    gtk_event_controller_set_propagation_phase(keyboard, GTK_PHASE_CAPTURE);
    g_signal_connect(keyboard, "key-pressed", G_CALLBACK(key_pressed), app);
    gtk_widget_add_controller(GTK_WIDGET(window), keyboard);

    GtkWidget *navigation = gtk_stack_switcher_new();
    gtk_stack_switcher_set_stack(GTK_STACK_SWITCHER(navigation), stack);
    gtk_widget_set_size_request(navigation, -1, 60);
    gtk_box_append(root, navigation);

    gtk_window_fullscreen(window);
    gtk_window_present(window);
}

int main(int argc, char **argv)
{
    App app = { 0 };
    app.touches = g_hash_table_new_full(g_direct_hash, g_direct_equal, NULL, g_free);
    app.scratch = g_dir_make_tmp("xun-peripherals-XXXXXX", NULL);
    if (app.scratch)
        app.recording = g_build_filename(app.scratch, "recording.wav", NULL);

    g_autoptr(GtkApplication) application = gtk_application_new(
        "ke.oa.xun.Peripherals", G_APPLICATION_NON_UNIQUE);
    g_signal_connect(application, "activate", G_CALLBACK(activate), &app);
    int status = g_application_run(G_APPLICATION(application), argc, argv);

    if (app.record_timer)
        g_source_remove(app.record_timer);
    if (app.audio) {
        g_subprocess_force_exit(app.audio);
        g_subprocess_wait(app.audio, NULL, NULL);
        g_object_unref(app.audio);
    }
    if (app.recording)
        g_unlink(app.recording);
    if (app.scratch)
        g_rmdir(app.scratch);
    g_free(app.recording);
    g_free(app.scratch);
    g_hash_table_unref(app.touches);
    g_clear_object(&app.battery);
    g_clear_object(&app.bluetooth);
    return status;
}
