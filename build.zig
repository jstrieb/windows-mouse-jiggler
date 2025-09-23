const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{
        .preferred_optimize_mode = .ReleaseSafe,
    });

    const exe = b.addExecutable(.{
        .name = "mouse-jiggler",
        .root_source_file = b.path("src/main.zig"),
        .target = b.resolveTargetQuery(std.Build.parseTargetQuery(.{
            .arch_os_abi = "x86_64-windows",
        }) catch unreachable),
        .optimize = optimize,
    });
    exe.linkLibC();
    b.installArtifact(exe);
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
