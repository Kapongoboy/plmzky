const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "plmzky",
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(lib);

    const exe = b.addExecutable(.{
        .name = "plmzky",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(exe);

    const plmzky = b.addModule(
        "plmzky",
        .{
            .root_source_file = .{
                .src_path = .{
                    .owner = b,
                    .sub_path = "src/root.zig",
                },
            },
        },
    );

    exe.root_module.addImport("plmzky", plmzky);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const test_paths = [_][]const u8{
        "src/lexer.zig",
        "src/token.zig",
    };

    const test_step = b.step("test", "Run unit tests");

    for (test_paths) |path| {
        const lib_unit_tests = b.addTest(.{
            .root_source_file = b.path(path),
            .target = target,
            .optimize = optimize,
        });

        const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

        test_step.dependOn(&run_lib_unit_tests.step);
    }
}
