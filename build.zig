const std = @import("std");

fn addAssemblyFile(b: *std.Build, comptime path: []const u8, main_mod: *std.Build.Module) void {
    const nasm = b.addSystemCommand(&.{ "nasm", "-f", "elf64", "-o" });
    const object_file_path = b.fmt(
        "{s}.o",
        .{std.fs.path.stem(path)},
    );

    const asm_bin_path = nasm.addOutputFileArg(object_file_path);
    nasm.addFileArg(b.path(path));
    main_mod.addObjectFile(asm_bin_path);
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const main_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const timer_mod = b.createModule(.{ .root_source_file = b.path("src/testing/timer.zig"), .target = target, .optimize = optimize });

    main_mod.addImport("timer", timer_mod);

    addAssemblyFile(b, "src/testing/repetition/write_bytes.asm", main_mod);
    addAssemblyFile(b, "src/testing/repetition/conditional_nop.asm", main_mod);
    addAssemblyFile(b, "src/testing/repetition/mov_read_port.asm", main_mod);
    addAssemblyFile(b, "src/testing/repetition/read_widths.asm", main_mod);
    addAssemblyFile(b, "src/testing/repetition/cache_size.asm", main_mod);
    addAssemblyFile(b, "src/testing/repetition/cache_indexing.asm", main_mod);
    addAssemblyFile(b, "src/testing/repetition/cache_non_temporal.asm", main_mod);
    addAssemblyFile(b, "src/testing/repetition/cache_prefetching.asm", main_mod);

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

    const test_mod = b.createModule(.{ .root_source_file = b.path("src/test_all.zig"), .target = target, .optimize = optimize });
    const test_exe = b.addTest(.{
        .name = "tests",
        .root_module = test_mod,
    });
    const run_tests = b.addRunArtifact(test_exe);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_tests.step);
}
