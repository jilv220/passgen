const std = @import("std");

const debug = std.debug;
const io = std.io;
const stdout = io.getStdOut().writer();
const ArrayList = std.ArrayList;

const Allocator = std.mem.Allocator;
const RndGen = std.rand.DefaultPrng;

const clap = @import("clap");

const DEFAULT_LENGTH: usize = 16;
const DEFAULT_NUM: usize = 1;

fn getRandu8(maxNum: u8) !u8 {
    var seed: u64 = undefined;
    try std.os.getrandom(std.mem.asBytes(&seed));
    var rnd = RndGen.init(seed);
    var some_random_num = @mod(rnd.random().int(u8), maxNum - 1);
    return some_random_num;
}

pub fn main() !void {
    var passwordLen = DEFAULT_LENGTH;
    var numOfPasswords = DEFAULT_NUM;

    const params = comptime clap.parseParamsComptime(
        \\-h, --help             Display this help and exit.
        \\-l, --line             Print the generated passwords one per line. 
        \\-n, --number <usize>   An option parameter, which takes a value.
        \\<usize>...             [password length] [number of passwords]
    );

    var diag = clap.Diagnostic{};
    var res = clap.parse(
        clap.Help,
        &params,
        clap.parsers.default,
        .{
            .diagnostic = &diag,
        },
    ) catch |err| {
        // Report useful error and exit
        diag.report(io.getStdErr().writer(), err) catch {};
        return err;
    };
    defer res.deinit();

    if (res.args.help != 0)
        return clap.help(
            std.io.getStdErr().writer(),
            clap.Help,
            &params,
            .{},
        );
    if (res.args.number) |n|
        debug.print("--number = {}\n", .{n});
    for (res.positionals) |_| {
        passwordLen = res.positionals[0];
        numOfPasswords = res.positionals[1];
    }

    // ascii 33 to 126
    var charStart: u8 = 33;
    var buf: [94]u8 = undefined;

    const randIdx = try getRandu8(buf.len);
    std.log.debug("{d}", .{randIdx});

    var counter: u8 = 0;
    while (charStart <= 126) {
        buf[counter] = charStart;
        counter += 1;
        charStart += 1;
    }
    std.log.debug("{s}", .{buf});

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var pass = ArrayList(u8).init(allocator);

    for (0..numOfPasswords) |i| {
        for (0..passwordLen) |_| {
            var charIdx = try getRandu8(buf.len);
            try pass.append(buf[charIdx]);
        }

        if (i != numOfPasswords - 1) {
            if (res.args.line == 1) {
                try pass.append(10);
            } else {
                try pass.append(32);
                if (@mod(i + 1, 3) == 0) {
                    try pass.append(10);
                }
            }
        }
    }

    try stdout.print("{s}\n", .{pass.items});
}
