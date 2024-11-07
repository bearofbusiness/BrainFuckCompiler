const std = @import("std");

const stdout_file = std.io.getStdOut().writer();
var bw = std.io.bufferedWriter(stdout_file);
const stdout = bw.writer();

var allocator = std.heap.page_allocator;

pub fn main() !void {
    var in: std.fs.File = undefined;
    var out: std.fs.File = undefined;
    var deleteDir = true;
    const cwd = std.fs.cwd();

    in = try cwd.openFile("test.bf", .{ .mode = std.fs.File.OpenMode.read_only });

    cwd.makeDir(".zigbf") catch {
        _ = try std.io.getStdErr().write("./.zigbf exist will not remove after\n");
        deleteDir = false;
    };

    out = try cwd.createFile(".zigbf/zigged.zig", .{ .read = true });

    try convertToZig(in, out);
    in.close();
    out.close();

    //input file
    const targetSource = ".zigbf/zigged.zig";
    //output dir
    const output = "./output";
    var cmd = std.process.Child.init(&[_][]const u8{ "zig", "build-exe", targetSource, "--name", "out", "-femit-bin=" ++ output, "-OReleaseFast" }, allocator);
    try cmd.spawn();
    _ = cmd.wait() catch {
        if (cmd.stderr) |stderrCmd| {
            //var buff: [4096]u8 = undefined;
            const reader = stderrCmd.reader();
            while (reader.readByte()) |byte| {
                try std.io.getStdErr().writer().print("{c}", .{byte});
            } else |_| {}
        }
    };

    const result: u8 = 0;
    if (result == 0) {
        //try cwd.deleteFile(".zigbf/zigged.zig");
        if (deleteDir) {
            try cwd.deleteDir(".zigbf");
        }
    }
}

fn convertToZig(in: std.fs.File, out: std.fs.File) !void {
    _ = try out.write("const std = @import(\"std\");\n");
    _ = try out.write("var allocator = std.heap.page_allocator;\n");
    _ = try out.write("const stdin = std.io.getStdIn();\n");
    _ = try out.write("const stdout_file = std.io.getStdOut().writer();\nvar bw = std.io.bufferedWriter(stdout_file);\nconst stdout = bw.writer();\n");
    _ = try out.write("const posix = std.posix;\n");

    _ = try out.write("var tape: [30000]u8 = undefined;\n");
    _ = try out.write("var ptr: usize = 0;\n");

    _ = try out.write("pub fn main() !void {\n");
    _ = try out.write("var termios = try posix.tcgetattr(stdin.handle);\n");
    _ = try out.write("termios.lflag.ICANON = false;\n");
    _ = try out.write("try posix.tcsetattr(stdin.handle, .FLUSH, termios);\n");
    _ = try out.write("for (tape, 0..) |_, i| {\ntape[i] = 0;\n}\n");

    const reader = in.reader();
    while (reader.readByte()) |char| {
        switch (char) {
            '>' => {
                _ = try out.write("ptr += 1;\n");
            },
            '<' => {
                _ = try out.write("ptr -= 1;\n");
            },
            '+' => {
                _ = try out.write("tape[ptr] = @addWithOverflow(tape[ptr], @as(u8, 1))[0];\n");
            },
            '-' => {
                _ = try out.write("tape[ptr] = @subWithOverflow(tape[ptr], @as(u8, 1))[0];\n");
            },
            '.' => {
                _ = try out.write("try stdout.print(\"{c}\", .{tape[ptr]});\ntry bw.flush();\n");
            },
            ',' => {
                _ = try out.write("tape[ptr] = try stdin.reader().readByte();\n");
            },
            '[' => {
                _ = try out.write("while (tape[ptr] != 0) {\n");
            },
            ']' => {
                _ = try out.write("}\n");
            },
            '#' => {
                _ = try out.write("for (tape, 0..) |v, i| {\nif (i == ptr) {\ntry stdout.print(\"<{}>\", .{v});\n} else {\ntry stdout.print(\" {} \", .{v});\n}\n}\n");
            },
            else => {},
        }
    } else |_| {}
    _ = try out.write("}");
}
