const std = @import("std");
const builtin = @import("builtin");
const c = @cImport({
    @cInclude("cairo/cairo.h");
    if (builtin.target.os.tag == .windows) {
        @cInclude("cairo/cairo-win32.h");
    } else {
        @cInclude("cairo/cairo-xlib.h");
    }
});

pub const Surface = struct {
    surface: ?*c.cairo_surface_t,

    const Self = @This();
    pub fn init(swidth: i32, height: i32) Self {
        return Self{
            .surface = c.cairo_image_surface_create(c.CAIRO_FORMAT_ARGB32, swidth, height),
        };
    }
    pub fn initFromPng(path: []const u8) Self {
        const path_c: [*c]const u8 = @ptrCast(path.ptr);
        return Self{
            .surface = c.cairo_image_surface_create_from_png(path_c),
        };
    }
    pub fn deinit(self: Self) void {
        c.cairo_surface_destroy(self.surface);
    }

    pub fn getWidth(self: Self) i32 {
        return c.cairo_image_surface_get_width(self.surface);
    }
    pub fn getHeight(self: Self) i32 {
        return c.cairo_image_surface_get_height(self.surface);
    }

    pub fn writeToPng(self: Self, path: []const u8) u32 {
        const path_c: [*c]const u8 = @ptrCast(path.ptr);
        return c.cairo_surface_write_to_png(self.surface, path_c);
    }
};

pub const Context = struct {
    cr: ?*c.cairo_t, // context
    sf: *const Surface, // surface
    fontSize: f64 = 12.0,

    const Self = @This();
    pub fn init(surface: *const Surface) Self {
        return Self{
            .sf = surface,
            .cr = c.cairo_create(surface.surface),
        };
    }
    pub fn deinit(self: *Self) void {
        c.cairo_destroy(self.cr);
    }
    pub fn scale(self: *Self, x: f64, y: f64) void {
        c.cairo_scale(self.cr, x, y);
    }
    pub fn translate(self: *Self, x: f64, y: f64) void {
        c.cairo_translate(self.cr, x, y);
    }
    pub fn rotate(self: *Self, angle: f64) void {
        c.cairo_rotate(self.cr, angle);
    }
    pub fn setOperation(self: *Self, op: c.cairo_operator_t) void {
        c.cairo_set_operator(self.cr, op);
    }
    pub fn moveTo(self: *Self, x: f64, y: f64) void {
        c.cairo_move_to(self.cr, x, y);
    }
    pub fn lineTo(self: *Self, x: f64, y: f64) void {
        c.cairo_line_to(self.cr, x, y);
    }
    pub fn curveTo(self: *Self, c1x: f64, c1y: f64, c2x: f64, c2y: f64, x: f64, y: f64) void {
        c.cairo_curve_to(self.cr, c1x, c1y, c2x, c2y, x, y);
    }
    pub fn beginPath(self: *Self) void {
        c.cairo_new_path(self.cr);
    }
    pub fn closePath(self: *Self) void {
        c.cairo_close_path(self.cr);
    }
    pub fn setSourceRGB(self: *Self, r: f64, g: f64, b: f64) void {
        c.cairo_set_source_rgb(self.cr, r, g, b);
    }
    pub fn setSourceRGBA(self: *Self, r: f64, g: f64, b: f64, a: f64) void {
        c.cairo_set_source_rgba(self.cr, r, g, b, a);
    }
    pub fn rectangle(self: *Self, x: f64, y: f64, width: f64, height: f64) void {
        c.cairo_rectangle(self.cr, x, y, width, height);
    }
    pub fn circle(self: *Self, x: f64, y: f64, radius: f64) void {
        c.cairo_arc(self.cr, x, y, radius, 0, 2 * std.math.pi);
    }
    pub fn arc(self: *Self, x: f64, y: f64, radius: f64, angle1: f64, angle2: f64) void {
        c.cairo_arc(self.cr, x, y, radius, angle1, angle2);
    }
    pub fn fill(self: *Self) void {
        c.cairo_fill(self.cr);
    }
    pub fn fillPreserve(self: *Self) void {
        c.cairo_fill_preserve(self.cr);
    }
    pub fn stroke(self: *Self) void {
        c.cairo_stroke(self.cr);
    }
    pub fn strokePreserve(self: *Self) void {
        c.cairo_stroke_preserve(self.cr);
    }
    pub fn paint(self: *Self) void {
        c.cairo_paint(self.cr);
    }
    pub fn save(self: *Self) void {
        c.cairo_save(self.cr);
    }
    pub fn restore(self: *Self) void {
        c.cairo_restore(self.cr);
    }

    // line style
    pub fn setLineWidth(self: *Self, width: f64) void {
        c.cairo_set_line_width(self.cr, width);
    }
    pub fn setLineCap(self: *Self, cap: u32) void {
        c.cairo_set_line_cap(self.cr, cap);
    }
    pub fn setLineJoin(self: *Self, join: u32) void {
        c.cairo_set_line_join(self.cr, join);
    }
    pub fn setDash(self: *Self, dashes: []f64, offset: f64) void {
        const dashes_c: [*c]f64 = @ptrCast(dashes.ptr);
        c.cairo_set_dash(self.cr, dashes_c, dashes.len, offset);
    }

    // quality
    pub fn setAntialias(self: *Self, antialias: u32) void {
        c.cairo_set_antialias(self.cr, antialias);
    }
    pub fn setFillRule(self: *Self, fill_rule: u32) void {
        c.cairo_set_fill_rule(self.cr, fill_rule);
    }

    // text
    pub fn selectFontFace(self: *Self, family: []const u8, slant: u32, weight: u32) void {
        const family_c: [*c]const u8 = @ptrCast(family.ptr);
        c.cairo_select_font_face(self.cr, family_c, slant, weight);
    }
    pub fn setFontSize(self: *Self, size: f64) void {
        self.fontSize = size;
        c.cairo_set_font_size(self.cr, size);
    }
    pub fn getFontSize(self: *Self) f64 {
        return self.fontSize;
    }
    pub fn textExtents(self: *Self, utf8: []const u8, extents: *TextExtents) void {
        const utf8_c: [*c]const u8 = @ptrCast(utf8.ptr);
        c.cairo_text_extents(self.cr, utf8_c, extents);
    }
    pub fn textPath(self: *Self, utf8: []const u8) void {
        const utf8_c: [*c]const u8 = @ptrCast(utf8);
        c.cairo_text_path(self.cr, utf8_c.ptr);
    }
    pub fn showText(self: *Self, utf8: []const u8) void {
        const utf8_c: [*c]const u8 = @ptrCast(utf8.ptr);
        c.cairo_show_text(self.cr, utf8_c);
    }

    // pattern or Gradient
    pub fn setSource(self: *Self, pattern: *Gradient) void {
        c.cairo_set_source(self.cr, pattern.pat);
    }
};

pub const TextExtents = c.cairo_text_extents_t;

pub const Gradient = struct {
    pat: ?*c.cairo_pattern_t,
    const Self = @This();
    pub fn initLinear(x0: f64, y0: f64, x1: f64, y1: f64) Self {
        return Self{
            .pat = c.cairo_pattern_create_linear(x0, y0, x1, y1),
        };
    }
    pub fn initRadial(cx0: f64, cy0: f64, r0: f64, cx1: f64, cy1: f64, r1: f64) Self {
        return Self{
            .pat = c.cairo_pattern_create_radial(cx0, cy0, r0, cx1, cy1, r1),
        };
    }
    pub fn initColor(r: f64, g: f64, b: f64, a: f64) Self {
        return Self{
            .pat = c.cairo_pattern_create_rgba(r, g, b, a),
        };
    }
    pub fn deinit(self: *Self) void {
        c.cairo_pattern_destroy(self.pat);
    }

    pub fn addColorStop(self: *Self, offset: f64, r: f64, g: f64, b: f64, a: f64) void {
        c.cairo_pattern_add_color_stop_rgba(self.pat, offset, r, g, b, a);
    }
    // CAIRO_EXTEND_NONE = 0,
    // CAIRO_EXTEND_REPEAT,
    // CAIRO_EXTEND_REFLECT,
    // CAIRO_EXTEND_PAD
    pub fn setExtend(self: *Self, extend: u32) void {
        c.cairo_pattern_set_extend(self.pat, extend);
    }
    // rotate
    pub fn rotate(self: *Self, angle: f64) void {
        var matrix: c.cairo_matrix_t = undefined;
        c.cairo_matrix_init_rotate(&matrix, angle);
        c.cairo_pattern_set_matrix(self.pat, &matrix);
    }
};
