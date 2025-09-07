const std = @import("std");

inline fn rdtsc() u64 {
    var hi: u32 = 0;
    var low: u32 = 0;

    asm (
        \\rdtsc
        : [low] "={eax}" (low),
          [hi] "={edx}" (hi),
    );
    return (@as(u64, hi) << 32) | @as(u64, low);
}

pub inline fn readCpuTimer() u64 {
    return rdtsc();
}

inline fn getOsTimerFreq() u64 {
    return 1000000;
}

inline fn readOsTimer() u64 {
    return @intCast(std.time.microTimestamp());
}

pub fn estimateCpuTimerFreq() u64 {
    const miliseconds_to_wait: u64 = 100;
    const os_freq: u64 = getOsTimerFreq();

    const cpu_start: u64 = readCpuTimer();
    const os_start: u64 = readOsTimer();
    var os_end: u64 = 0;
    var os_elapsed: u64 = 0;

    const os_wait_time: u64 = os_freq * miliseconds_to_wait / 1000;
    while (os_elapsed < os_wait_time) {
        os_end = readOsTimer();
        os_elapsed = os_end - os_start;
    }

    const cpu_end: u64 = readCpuTimer();
    const cpu_elapsed: u64 = cpu_end - cpu_start;

    var cpu_freq: u64 = 0;
    if (os_elapsed != 0) {
        cpu_freq = os_freq * cpu_elapsed / os_elapsed;
    }

    return cpu_freq;
}

pub fn print(label: []const u8, start: u64, end: u64, total_time: u64) void {
    const elapsed: u64 = end - start;
    const percent: f64 = 100.0 * (@as(f64, @floatFromInt(elapsed)) / @as(f64, @floatFromInt(total_time)));
    std.debug.print("  {s: <16}: {d: <12} ({d:.2}%)\n", .{ label, elapsed, percent });
}
