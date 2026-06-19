const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const nasm = b.addSystemCommand(&.{ "nasm", "-f", "elf64", "-o" });
    const asm_loop_bin_path = nasm.addOutputFileArg("repetition_test_misc.o");
    nasm.addFileArg(b.path("src/testing/repetition/misc.asm"));

    const main_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    main_mod.addObjectFile(asm_loop_bin_path);

    const timer_mod = b.createModule(.{ .root_source_file = b.path("src/testing/timer.zig"), .target = target, .optimize = optimize });

    main_mod.addImport("timer", timer_mod);

    const main_exe = b.addExecutable(.{
        .name = "haversine",
        .root_module = main_mod,
    });
    b.installArtifact(main_exe);

    const run_cmd = b.addRunArtifact(main_exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const test_mod = b.createModule(.{ .root_source_file = b.path("src/testingtest_all.zig"), .target = target, .optimize = optimize });
    const test_exe = b.addTest(.{
        .name = "tests",
        .root_module = test_mod,
    });
    const run_tests = b.addRunArtifact(test_exe);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_tests.step);
}
