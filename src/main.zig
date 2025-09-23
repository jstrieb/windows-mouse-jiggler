const std = @import("std");
const win32 = @cImport({
    @cInclude("windows.h");
    @cInclude("winuser.h");
});

var stdout: @TypeOf(std.io.getStdOut().writer()) = undefined;

const Args = struct {
    threshold: u64 = 30 * 1000,
    delta: c_int = -5,
    verbose: bool = false,

    const Self = @This();

    pub fn parse(allocator: std.mem.Allocator) !Self {
        const args = try std.process.argsAlloc(allocator);
        defer std.process.argsFree(allocator, args);
        var result: Self = .{};
        var i: usize = 1;
        args: while (i < args.len) : (i += 1) {
            const arg = args[i];
            if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
                try stdout.print("Usage: {s} [OPTIONS]\n\n", .{args[0]});
                try stdout.print("Options:\n", .{});
                inline for (@typeInfo(Self).Struct.fields) |field| {
                    var name: [field.name.len]u8 = undefined;
                    @memcpy(&name, field.name);
                    std.mem.replaceScalar(u8, &name, '_', '-');
                    if (@typeInfo(field.type) == .Bool) {
                        try stdout.print(
                            "--{s}\n",
                            .{&name},
                        );
                    } else {
                        const default = @as(*field.type, @constCast(
                            @alignCast(@ptrCast(field.default_value.?)),
                        )).*;
                        try stdout.print(
                            "--{s:<10}\t\t(default: {any})\n",
                            .{ &name, default },
                        );
                    }
                }
                return error.Help;
            }
            if (!std.mem.startsWith(u8, arg, "--")) return error.InvalidArg;
            _ = std.mem.replaceScalar(u8, arg, '-', '_');
            inline for (@typeInfo(Self).Struct.fields) |field| {
                const default = @as(*bool, @constCast(@ptrCast(
                    field.default_value.?,
                ))).*;
                if (std.mem.eql(u8, arg[2..], field.name)) {
                    switch (@typeInfo(field.type)) {
                        .Int => |t| {
                            @field(result, field.name) = switch (t.signedness) {
                                .signed => try std.fmt.parseInt(
                                    field.type,
                                    args[i + 1],
                                    0,
                                ),
                                .unsigned => try std.fmt.parseUnsigned(
                                    field.type,
                                    args[i + 1],
                                    0,
                                ),
                            };
                            i += 1;
                            continue :args;
                        },
                        .Bool => {
                            @field(result, field.name) = !default;
                            continue :args;
                        },
                        else => unreachable,
                    }
                }
            }
            return error.InvalidArg;
        }
        return result;
    }
};

pub fn main() !void {
    stdout = std.io.getStdOut().writer();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() != .leak);
    const allocator = gpa.allocator();
    var args = Args.parse(allocator) catch |err| switch (err) {
        error.Help => return,
        else => return err,
    };
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
