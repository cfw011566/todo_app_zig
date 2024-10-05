//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.
const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui");

pub fn main() !void {
    const screen_width = 800;
    const screen_height = 600;
    const font_size = 18;
    const max_size = 255;

    rl.initWindow(screen_width, screen_height, "Todo App");
    defer rl.closeWindow();
    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second

    // rl.setExitKey(rl.KeyboardKey.key_q);

    rg.guiSetStyle(rg.GuiControl.default, @intFromEnum(rg.GuiDefaultProperty.text_size), font_size);

    var input_buffer = [_:0]u8{0} ** max_size;
    const allocator = std.heap.page_allocator;
    var todo_list = std.ArrayList([]u8).init(allocator);
    defer todo_list.deinit();

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.white);

        // input box at left part of screen
        // input box for entry todo items
        var secret_view = true;
        const result = rg.guiTextInputBox(rl.Rectangle{ .x = 20, .y = 20, .width = 300, .height = 200 }, "Todo Input", "Enter a Task", "Add", &input_buffer, max_size, &secret_view);
        if (result == 1) {
            const buffer = try allocator.alloc(u8, max_size);
            std.mem.copyForwards(u8, buffer, &input_buffer);
            // try todo_list.append(buffer);
            try todo_list.insert(0, buffer);
            for (todo_list.items, 0..) |item, i| {
                std.log.info("{d} {s}", .{ i, item });
            }
        }

        // show todo items at right part of screen
        // show title "Todo List"
        const label_width: f32 = @floatFromInt(rl.measureText("Todo List", font_size) + 8);
        _ = rg.guiLabel(rl.Rectangle{ .x = screen_width / 2 + 10, .y = 10, .width = label_width, .height = 50 }, "Todo List");

        // show items of todo list
        var y_offset: f32 = 10 + font_size + 4;
        const button_x = screen_width / 2 + 10;
        const remove_button_len: f32 = @floatFromInt(rl.measureText("Remove", font_size) + 8);
        const item_x = screen_width / 2 + 10 + remove_button_len + 10;
        var remove_index: ?usize = null;
        for (todo_list.items, 0..) |item, i| {
            y_offset += font_size + 4;
            const item_width: f32 = @floatFromInt(rl.measureText(@ptrCast(item), font_size) + 8);
            _ = rg.guiLabel(rl.Rectangle{ .x = item_x, .y = y_offset, .width = item_width, .height = 20 }, @ptrCast(item));
            const button_rect = rl.Rectangle{ .x = button_x, .y = y_offset, .width = remove_button_len, .height = 20 };
            if (rg.guiButton(button_rect, "Remove") == 1) {
                std.log.info("remove {s}", .{item});
                remove_index = i;
            }
        }

        // handle remove item
        if (remove_index) |*index| {
            std.log.info("free item {d}", .{index.*});
            const text = todo_list.orderedRemove(index.*);
            allocator.free(text);
        }
    }

    // free ArrayList items
    for (todo_list.items) |item| {
        allocator.free(item);
    }
}
