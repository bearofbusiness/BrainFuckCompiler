const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zigcli = b.dependency("zigcli", .{});

    const exe = b.addExecutable(.{
        .name = "bfcz",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Currently zigcli provide two modules.
    exe.root_module.addImport("simargs", zigcli.module("simargs"));
    exe.root_module.addImport("pretty-table", zigcli.module("pretty-table"));

    b.installArtifact(exe);
}
