const std = @import("std");
const win32 = @cImport({
    @cInclude("windows.h");
    @cInclude("winuser.h");
});

const THRESHOLD = 30 * 1000;
var delta: c_int = -1;

pub fn main() !void {
    var info: win32.LASTINPUTINFO = undefined;
    info.cbSize = @intCast(std.zig.c_translation.sizeof(win32.LASTINPUTINFO));
    while (true) {
        const currentTick = win32.GetTickCount();
        _ = win32.GetLastInputInfo(&info);
        if (currentTick - info.dwTime > THRESHOLD) {
            var currentPosition: win32.POINT = undefined;
            _ = win32.GetCursorPos(&currentPosition);
            _ = win32.SetCursorPos(
                currentPosition.x + delta,
                currentPosition.y + delta,
            );
            delta *= -1;
        }
        std.time.sleep(THRESHOLD * 1000 * 1000);
    }
}
