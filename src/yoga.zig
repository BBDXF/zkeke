const std = @import("std");
const yoga_lib = @cImport({
    @cInclude("yoga/Yoga.h");
});
const comm = @import("comm.zig");

pub const Node = struct {
    node: yoga_lib.YGNodeRef = null,

    const Self = @This();
    pub fn init() Self {
        var inst = Self{};
        inst.node = yoga_lib.YGNodeNew();
        const context: *anyopaque = @constCast(&inst);
        yoga_lib.YGNodeSetContext(inst.node, context);
        return inst;
    }
    pub fn deinit(self: *Self) void {
        if (self.node != null) {
            yoga_lib.YGNodeFree(self.node);
        }
    }

    pub fn freeAll(self: *Self) void {
        if (self.node != null) {
            yoga_lib.YGNodeFreeRecursive(self.node);
        }
    }

    pub fn getParentNode(self: *Self) *Self {
        const parent = yoga_lib.YGNodeGetParent(self.node);
        if (parent == null) return null;
        const context = yoga_lib.YGNodeGetContext(parent);
        if (context != null) {
            return @as(*Self, @ptrCast(context));
        }
        return null;
    }

    pub fn calculateLayout(self: *Self, width: f32, height: f32, direction: comm.KKLayoutDirection) void {
        const direction_yoga = @intFromEnum(direction);
        var w = yoga_lib.YGUndefined;
        if (width > 0) {
            w = width;
        }
        var h = yoga_lib.YGUndefined;
        if (height > 0) {
            h = height;
        }
        yoga_lib.YGNodeCalculateLayout(self.node, w, h, direction_yoga);
    }

    pub fn getComputedLayout(self: *Self) comm.KKLayoutComputedStyle {
        var style: comm.KKLayoutComputedStyle = .{};
        style.left = yoga_lib.YGNodeLayoutGetLeft(self.node);
        style.top = yoga_lib.YGNodeLayoutGetTop(self.node);
        style.bottom = yoga_lib.YGNodeLayoutGetBottom(self.node);
        style.right = yoga_lib.YGNodeLayoutGetRight(self.node);
        style.width = yoga_lib.YGNodeLayoutGetWidth(self.node);
        style.height = yoga_lib.YGNodeLayoutGetHeight(self.node);

        style.direction = @enumFromInt(yoga_lib.YGNodeLayoutGetDirection(self.node));
        style.rawWidth = yoga_lib.YGNodeLayoutGetRawWidth(self.node);
        style.rawHeight = yoga_lib.YGNodeLayoutGetRawHeight(self.node);
        style.hadOverflow = yoga_lib.YGNodeLayoutGetHadOverflow(self.node);

        // margin
        style.margin = .{
            .left = yoga_lib.YGNodeLayoutGetMargin(self.node, yoga_lib.YGEdgeLeft),
            .top = yoga_lib.YGNodeLayoutGetMargin(self.node, yoga_lib.YGEdgeTop),
            .right = yoga_lib.YGNodeLayoutGetMargin(self.node, yoga_lib.YGEdgeRight),
            .bottom = yoga_lib.YGNodeLayoutGetMargin(self.node, yoga_lib.YGEdgeBottom),
        };

        // padding
        style.padding = .{
            .left = yoga_lib.YGNodeLayoutGetPadding(self.node, yoga_lib.YGEdgeLeft),
            .top = yoga_lib.YGNodeLayoutGetPadding(self.node, yoga_lib.YGEdgeTop),
            .right = yoga_lib.YGNodeLayoutGetPadding(self.node, yoga_lib.YGEdgeRight),
            .bottom = yoga_lib.YGNodeLayoutGetPadding(self.node, yoga_lib.YGEdgeBottom),
        };

        // border
        style.border = .{
            .left = yoga_lib.YGNodeLayoutGetBorder(self.node, yoga_lib.YGEdgeLeft),
            .top = yoga_lib.YGNodeLayoutGetBorder(self.node, yoga_lib.YGEdgeTop),
            .right = yoga_lib.YGNodeLayoutGetBorder(self.node, yoga_lib.YGEdgeRight),
            .bottom = yoga_lib.YGNodeLayoutGetBorder(self.node, yoga_lib.YGEdgeBottom),
        };

        return style;
    }

    pub fn getChildCount(self: *Self) usize {
        return @intCast(yoga_lib.YGNodeGetChildCount(self.node));
    }
    pub fn addChild(self: *Self, child: *Self) void {
        yoga_lib.YGNodeInsertChild(self.node, child.node, self.getChildCount());
    }
    pub fn insertChild(self: *Self, child: *Self, index: usize) void {
        yoga_lib.YGNodeInsertChild(self.node, child.node, index);
    }
    pub fn deleteChild(self: *Self, child: *Self) void {
        yoga_lib.YGNodeRemoveChild(self.node, child.node);
    }
    pub fn deleteAllChildren(self: *Self) void {
        if (self.node == null) return;
        yoga_lib.YGNodeRemoveAllChildren(self.node);
    }
    pub fn getParent(self: *Self) ?*Self {
        if (self.node != null) {
            if (yoga_lib.YGNodeGetParent(self.node)) |parent| {
                return @as(*Self, @ptrCast(parent));
            }
        }
        return null;
    }

    pub fn setHasNewLayout(self: *Self, has_new_layout: bool) void {
        if (self.node == null) return;
        yoga_lib.YGNodeSetHasNewLayout(self.node, has_new_layout);
    }
    pub fn getHasNewLayout(self: *Self) bool {
        if (self.node == null) return false;
        return yoga_lib.YGNodeGetHasNewLayout(self.node);
    }

    pub fn setNodeType(self: *Self, node_type: comm.KKLayoutNodeType) void {
        if (self.node == null) return;
        const node_type_int = @intFromEnum(node_type);
        yoga_lib.YGNodeSetNodeType(self.node, node_type_int);
    }
    pub fn getNodeType(self: *Self) comm.KKLayoutNodeType {
        if (self.node == null) return .unknown;
        const node_type_int = yoga_lib.YGNodeGetNodeType(self.node);
        return @enumFromInt(node_type_int);
    }

    // parse css style to yoga node
    pub fn setProperty(self: *Self, property: []const u8, value: []const u8) void {
        if (std.mem.eql(u8, property, "width")) {
            const val = comm.parseUnit(value);
            self.setWidth(val);
        } else if (std.mem.eql(u8, property, "height")) {
            const val = comm.parseUnit(value);
            self.setHeight(val);
        } else if (std.mem.eql(u8, property, "min-width")) {
            const val = comm.parseUnit(value);
            self.setMinWidth(val);
        } else if (std.mem.eql(u8, property, "min-height")) {
            const val = comm.parseUnit(value);
            self.setMinHeight(val);
        } else if (std.mem.eql(u8, property, "max-width")) {
            const val = comm.parseUnit(value);
            self.setMaxWidth(val);
        } else if (std.mem.eql(u8, property, "max-height")) {
            const val = comm.parseUnit(value);
            self.setMaxHeight(val);
        } else if (std.mem.eql(u8, property, "margin")) {
            const vals = comm.parseUnitList(value);
            self.setMarginList(vals);
        } else if (std.mem.eql(u8, property, "padding")) {
            const vals = comm.parseUnitList(value);
            self.setPaddingList(vals);
        } else if (std.mem.eql(u8, property, "border")) {
            const vals = comm.parseUnitList(value);
            self.setBorderList(vals);
        } else if (std.mem.eql(u8, property, "direction")) {
            const val = comm.parseDirection(value);
            self.setDirection(val);
        } else if (std.mem.eql(u8, property, "flex-direction")) {
            const val = comm.parseFlexDirection(value);
            self.setFlexDirection(val);
        }
    }

    // mapping yoga method to zig method
    pub fn setWidth(self: *Self, value: comm.KKLayoutUnitValue) void {
        switch (value.unit) {
            .Point => {
                yoga_lib.YGNodeStyleSetWidth(self.node, value.value);
            },
            .Percent => {
                yoga_lib.YGNodeStyleSetWidthPercent(self.node, value.value);
            },
            .Auto => {
                yoga_lib.YGNodeStyleSetWidthAuto(self.node);
            },
            .MaxContent => {
                yoga_lib.YGNodeStyleSetWidthMaxContent(self.node);
            },
            .FitContent => {
                yoga_lib.YGNodeStyleSetWidthFitContent(self.node);
            },
            .Stretch => {
                yoga_lib.YGNodeStyleSetWidthStretch(self.node);
            },
            else => {},
        }
    }

    pub fn setHeight(self: *Self, value: comm.KKLayoutUnitValue) void {
        switch (value.unit) {
            .Point => {
                yoga_lib.YGNodeStyleSetHeight(self.node, value.value);
            },
            .Percent => {
                yoga_lib.YGNodeStyleSetHeightPercent(self.node, value.value);
            },
            .Auto => {
                yoga_lib.YGNodeStyleSetHeightAuto(self.node);
            },
            .MaxContent => {
                yoga_lib.YGNodeStyleSetHeightMaxContent(self.node);
            },
            .FitContent => {
                yoga_lib.YGNodeStyleSetHeightFitContent(self.node);
            },
            .Stretch => {
                yoga_lib.YGNodeStyleSetHeightStretch(self.node);
            },
            else => {},
        }
    }

    pub fn setMinWidth(self: *Self, value: comm.KKLayoutUnitValue) void {
        switch (value.unit) {
            .Point => {
                yoga_lib.YGNodeStyleSetMinWidth(self.node, value.value);
            },
            .Percent => {
                yoga_lib.YGNodeStyleSetMinWidthPercent(self.node, value.value);
            },
            .MaxContent => {
                yoga_lib.YGNodeStyleSetMinWidthMaxContent(self.node);
            },
            .FitContent => {
                yoga_lib.YGNodeStyleSetMinWidthFitContent(self.node);
            },
            .Stretch => {
                yoga_lib.YGNodeStyleSetMinWidthStretch(self.node);
            },
            else => {},
        }
    }

    pub fn setMinHeight(self: *Self, value: comm.KKLayoutUnitValue) void {
        switch (value.unit) {
            .Point => {
                yoga_lib.YGNodeStyleSetMinHeight(self.node, value.value);
            },
            .Percent => {
                yoga_lib.YGNodeStyleSetMinHeightPercent(self.node, value.value);
            },
            .MaxContent => {
                yoga_lib.YGNodeStyleSetMinHeightMaxContent(self.node);
            },
            .FitContent => {
                yoga_lib.YGNodeStyleSetMinHeightFitContent(self.node);
            },
            .Stretch => {
                yoga_lib.YGNodeStyleSetMinHeightStretch(self.node);
            },
            else => {},
        }
    }

    pub fn setMaxWidth(self: *Self, value: comm.KKLayoutUnitValue) void {
        switch (value.unit) {
            .Point => {
                yoga_lib.YGNodeStyleSetMaxWidth(self.node, value.value);
            },
            .Percent => {
                yoga_lib.YGNodeStyleSetMaxWidthPercent(self.node, value.value);
            },
            .MaxContent => {
                yoga_lib.YGNodeStyleSetMaxWidthMaxContent(self.node);
            },
            .FitContent => {
                yoga_lib.YGNodeStyleSetMaxWidthFitContent(self.node);
            },
            .Stretch => {
                yoga_lib.YGNodeStyleSetMaxWidthStretch(self.node);
            },
            else => {},
        }
    }

    pub fn setMaxHeight(self: *Self, value: comm.KKLayoutUnitValue) void {
        switch (value.unit) {
            .Point => {
                yoga_lib.YGNodeStyleSetMaxHeight(self.node, value.value);
            },
            .Percent => {
                yoga_lib.YGNodeStyleSetMaxHeightPercent(self.node, value.value);
            },
            .MaxContent => {
                yoga_lib.YGNodeStyleSetMaxHeightMaxContent(self.node);
            },
            .FitContent => {
                yoga_lib.YGNodeStyleSetMaxHeightFitContent(self.node);
            },
            .Stretch => {
                yoga_lib.YGNodeStyleSetMaxHeightStretch(self.node);
            },
            else => {},
        }
    }

    pub fn setMargin(self: *Self, edge: comm.KKLayoutEdge, value: comm.KKLayoutUnitValue) void {
        const edgeValue = @intFromEnum(edge);
        switch (value.unit) {
            .Point => {
                yoga_lib.YGNodeStyleSetMargin(self.node, edgeValue, value.value);
            },
            .Percent => {
                yoga_lib.YGNodeStyleSetMarginPercent(self.node, edgeValue, value.value);
            },
            .Auto => {
                yoga_lib.YGNodeStyleSetMarginAuto(self.node, edgeValue);
            },
            else => {},
        }
    }
    pub fn setMarginList(self: *Self, value: []comm.KKLayoutUnitValue) void {
        switch (value.len) {
            1 => {
                self.setMargin(comm.KKLayoutEdge.All, value[0]);
            },
            2 => {
                self.setMargin(comm.KKLayoutEdge.Vertical, value[0]);
                self.setMargin(comm.KKLayoutEdge.Horizontal, value[1]);
            },
            3 => {
                self.setMargin(comm.KKLayoutEdge.Top, value[0]);
                self.setMargin(comm.KKLayoutEdge.Horizontal, value[1]);
                self.setMargin(comm.KKLayoutEdge.Bottom, value[2]);
            },
            4...6 => {
                self.setMargin(comm.KKLayoutEdge.Top, value[0]);
                self.setMargin(comm.KKLayoutEdge.Right, value[1]);
                self.setMargin(comm.KKLayoutEdge.Bottom, value[2]);
                self.setMargin(comm.KKLayoutEdge.Left, value[3]);
            },
            else => {},
        }
    }

    pub fn setPadding(self: *Self, edge: comm.KKLayoutEdge, value: comm.KKLayoutUnitValue) void {
        const edgeValue = @intFromEnum(edge);
        switch (value.unit) {
            .Point => {
                yoga_lib.YGNodeStyleSetPadding(self.node, edgeValue, value.value);
            },
            .Percent => {
                yoga_lib.YGNodeStyleSetPaddingPercent(self.node, edgeValue, value.value);
            },
            else => {},
        }
    }

    pub fn setPaddingList(self: *Self, value: []comm.KKLayoutUnitValue) void {
        switch (value.len) {
            1 => {
                self.setPadding(comm.KKLayoutEdge.All, value[0]);
            },
            2 => {
                self.setPadding(comm.KKLayoutEdge.Vertical, value[0]);
                self.setPadding(comm.KKLayoutEdge.Horizontal, value[1]);
            },
            3 => {
                self.setPadding(comm.KKLayoutEdge.Top, value[0]);
                self.setPadding(comm.KKLayoutEdge.Horizontal, value[1]);
                self.setPadding(comm.KKLayoutEdge.Bottom, value[2]);
            },
            4...6 => {
                self.setPadding(comm.KKLayoutEdge.Top, value[0]);
                self.setPadding(comm.KKLayoutEdge.Right, value[1]);
                self.setPadding(comm.KKLayoutEdge.Bottom, value[2]);
                self.setPadding(comm.KKLayoutEdge.Left, value[3]);
            },
            else => {},
        }
    }

    pub fn setBorder(self: *Self, edge: comm.KKLayoutEdge, value: comm.KKLayoutUnitValue) void {
        const edgeValue = @intFromEnum(edge);
        switch (value.unit) {
            .Point => {
                yoga_lib.YGNodeStyleSetBorder(self.node, edgeValue, value.value);
            },
            else => {},
        }
    }

    pub fn setBorderList(self: *Self, value: []comm.KKLayoutUnitValue) void {
        switch (value.len) {
            1 => {
                self.setBorder(comm.KKLayoutEdge.All, value[0]);
            },
            2 => {
                self.setBorder(comm.KKLayoutEdge.Vertical, value[0]);
                self.setBorder(comm.KKLayoutEdge.Horizontal, value[1]);
            },
            3 => {
                self.setBorder(comm.KKLayoutEdge.Top, value[0]);
                self.setBorder(comm.KKLayoutEdge.Horizontal, value[1]);
                self.setBorder(comm.KKLayoutEdge.Bottom, value[2]);
            },
            4...6 => {
                self.setBorder(comm.KKLayoutEdge.Top, value[0]);
                self.setBorder(comm.KKLayoutEdge.Right, value[1]);
                self.setBorder(comm.KKLayoutEdge.Bottom, value[2]);
                self.setBorder(comm.KKLayoutEdge.Left, value[3]);
            },
            else => {},
        }
    }

    pub fn setDirection(self: *Self, value: comm.KKLayoutDirection) void {
        const directionValue = switch (value) {
            comm.KKLayoutDirection.Inherit => yoga_lib.YGDirectionInherit,
            comm.KKLayoutDirection.LTR => yoga_lib.YGDirectionLTR,
            comm.KKLayoutDirection.RTL => yoga_lib.YGDirectionRTL,
        };
        yoga_lib.YGNodeStyleSetDirection(self.node, directionValue);
    }

    pub fn setFlexDirection(self: *Self, value: comm.KKLayoutFlexDirection) void {
        const directionValue = @intFromEnum(value);
        yoga_lib.YGNodeStyleSetFlexDirection(self.node, directionValue);
    }

    pub fn setJustifyContent(self: *Self, justify: comm.KKLayoutJustify) void {
        const justifyContentValue = @intFromEnum(justify);
        yoga_lib.YGNodeStyleSetJustifyContent(self.node, justifyContentValue);
    }
    pub fn setAlignItems(self: *Self, alignVal: comm.KKLayoutAlign) void {
        const alignItemsValue = @intFromEnum(alignVal);
        yoga_lib.YGNodeStyleSetAlignItems(self.node, alignItemsValue);
    }
    pub fn setAlignSelf(self: *Self, alignVal: comm.KKLayoutAlign) void {
        const alignSelfValue = @intFromEnum(alignVal);
        yoga_lib.YGNodeStyleSetAlignSelf(self.node, alignSelfValue);
    }
    pub fn setPositionType(self: *Self, positionType: comm.KKLayoutPositionType) void {
        const positionTypeValue = @intFromEnum(positionType);
        yoga_lib.YGNodeStyleSetPositionType(self.node, positionTypeValue);
    }
    pub fn setFlexWrap(self: *Self, flexWrap: comm.KKLayoutFlexWrap) void {
        const flexWrapValue = @intFromEnum(flexWrap);
        yoga_lib.YGNodeStyleSetFlexWrap(self.node, flexWrapValue);
    }
    pub fn setOverflow(self: *Self, overflow: comm.KKLayoutOverflow) void {
        const overflowValue = @intFromEnum(overflow);
        yoga_lib.YGNodeStyleSetOverflow(self.node, overflowValue);
    }
    pub fn setDisplay(self: *Self, display: comm.KKLayoutDisplay) void {
        const displayValue = @intFromEnum(display);
        yoga_lib.YGNodeStyleSetDisplay(self.node, displayValue);
    }
    pub fn setFlex(self: *Self, flex: f32) void {
        yoga_lib.YGNodeStyleSetFlex(self.node, flex);
    }
    pub fn setFlexGrow(self: *Self, flexGrow: f32) void {
        yoga_lib.YGNodeStyleSetFlexGrow(self.node, flexGrow);
    }
    pub fn setFlexShrink(self: *Self, flexShrink: f32) void {
        yoga_lib.YGNodeStyleSetFlexShrink(self.node, flexShrink);
    }
    pub fn setFlexBasis(self: *Self, flexBasis: comm.KKLayoutUnitValue) void {
        switch (flexBasis.unit) {
            .Auto => {
                yoga_lib.YGNodeStyleSetFlexBasisAuto(self.node);
            },
            .Point => {
                yoga_lib.YGNodeStyleSetFlexBasis(self.node, flexBasis.value);
            },
            .Percent => {
                yoga_lib.YGNodeStyleSetFlexBasisPercent(self.node, flexBasis.value);
            },
            .MaxContent => {
                yoga_lib.YGNodeStyleSetFlexBasis(self.node, yoga_lib.YGUndefined);
            },
            .FitContent => {
                yoga_lib.YGNodeStyleSetFlexBasis(self.node, yoga_lib.YGUndefined);
            },
            .Stretch => {
                yoga_lib.YGNodeStyleSetFlexBasis(self.node, yoga_lib.YGUndefined);
            },
            else => {},
        }
    }

    // left, top, right, bottom
    pub fn setPosition(self: *Self, edge: comm.KKLayoutEdge, value: comm.KKLayoutUnitValue) void {
        const edgeValue = @intFromEnum(edge);
        switch (value.unit) {
            .Point => {
                yoga_lib.YGNodeStyleSetPosition(self.node, edgeValue, value.value);
            },
            .Percent => {
                yoga_lib.YGNodeStyleSetPositionPercent(self.node, edgeValue, value.value);
            },
            .Auto => {
                yoga_lib.YGNodeStyleSetPositionAuto(self.node, edgeValue);
            },
            else => {},
        }
    }

    pub fn setGap(self: *Self, edge: comm.KKLayoutGutter, value: comm.KKLayoutUnitValue) void {
        const edgeValue = @intFromEnum(edge);
        switch (value.kind) {
            .Point => {
                yoga_lib.YGNodeStyleSetGap(self.node, edgeValue, value.value);
            },
            .Percent => {
                yoga_lib.YGNodeStyleSetGapPercent(self.node, edgeValue, value.value);
            },
            else => {},
        }
    }

    pub fn setBoxSizing(self: *Self, value: comm.KKLayoutBoxSizing) void {
        yoga_lib.YGNodeStyleSetPositionType(self.node, @intFromEnum(value));
    }

    pub fn setAspectRatio(self: *Self, value: f32) void {
        yoga_lib.YGNodeStyleSetAspectRatio(self.node, value);
    }
};
