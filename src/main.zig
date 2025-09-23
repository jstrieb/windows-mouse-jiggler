const std = @import("std");
const win32 = @cImport({
    @cInclude("windows.h");
    @cInclude("winuser.h");
});

const Args = struct {
    threshold: c_uint = 3 * 1000,
    delta: c_int = -100,

    const Self = @This();

    pub fn parse(allocator: std.mem.Allocator) !Self {
        const args = try std.process.argsAlloc(allocator);
        defer std.process.argsFree(allocator, args);
        const result: Self = .{};
        var i: usize = 1;
        while (i < args.len) : (i += 1) {
            inline for (@typeInfo(Self).Struct.fields) |field| {
                // TODO
                if (true) continue;
                switch (@typeInfo(field.type)) {
                    .Int => |t| switch (t.signedness) {
                        // TODO
                        .signed => {},
                        // TODO
                        .unsigned => {},
                    },
                }
            }
        }
        return result;
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() != .leak);
    const allocator = gpa.allocator();
    var args = try Args.parse(allocator);
    defer args.deinit();

    var info: win32.LASTINPUTINFO = undefined;
    info.cbSize = @intCast(std.zig.c_translation.sizeof(win32.LASTINPUTINFO));
    var currentPosition: win32.POINT = undefined;
    while (true) {
        const currentTick = win32.GetTickCount();
        _ = win32.GetLastInputInfo(&info);
        if (currentTick - info.dwTime > args.threshold) {
            _ = win32.GetCursorPos(&currentPosition);
            _ = win32.SetCursorPos(
                currentPosition.x + args.delta,
                currentPosition.y + args.delta,
            );
            args.delta *= -1;
        }
        std.time.sleep(args.threshold * 1000 * 1000);
    }
}
