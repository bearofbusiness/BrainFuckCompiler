const std = @import("std");

const bufPrint = std.fmt.bufPrint;

const stdout_file = std.io.getStdOut().writer();
var bw = std.io.bufferedWriter(stdout_file);
const stdout = bw.writer();

var allocator = std.heap.page_allocator;

pub fn main() !void {
    const stack_size: usize = 1000;
    const array_size: usize = 1000;
    //const mode = (1 << 0) | (1 << 1) | (1 << 2) ;
    //var output_file: []u8 = undefined;
    //var input_file: []u8 = undefined;
    var in: std.fs.File = undefined;
    var out: std.fs.File = undefined;
    //const ret =
    in = try std.fs.cwd().openFile("test.bf", .{ .mode = std.fs.File.OpenMode.read_only });
    out = try std.fs.cwd().createFile("out", .{ .read = true });
    _ = try compile(in, out, stack_size, array_size);
}

fn compile(in: std.fs.File, out: std.fs.File, stack_size: usize, array_size: usize) !i32 {
    //var c: u8 = 0;
    var stack_size_var = stack_size;
    var label_num: u64 = 0;
    var stack_ptr: usize = 0;

    var stack: []u64 = undefined;
    if (allocator.alloc(u64, stack_size_var)) |val| {
        stack = val;
    } else |_| {
        try std.io.getStdErr().writer().print("error: could not allocate stack {d}\n", .{stack_size});
        allocator.free(stack);
        return -1;
    }

    const buff: []u8 = try allocator.alloc(u8, 256);

    _ = try bufPrint(buff, "t.lcomm buffer {d}\n", .{array_size});

    _ = try out.write("\t.section .bss\n");

    for (buff) |val| {
        _ = try out.writer().writeByte(val);
    }

    _ = try out.write("\n");

    _ = try out.write("\t.section .text\n");

    _ = try out.write("\t.globl _start\n");

    _ = try out.write("_start:\n");

    _ = try out.write("\tmovl $buffer, %edi\n");

    _ = try out.write("\n");
    const reader = in.reader();
    while (reader.readByte()) |char| {
        switch (char) {
            '>' => {
                _ = try out.write("\tdec%edi\n");
                _ = try out.write("\n");
            },
            '<' => {
                _ = try out.write("\tdec %edi\n");
                _ = try out.write("\n");
            },
            '+' => {
                _ = try out.write("\tincb (%edi)\n");
                _ = try out.write("\n");
            },
            '-' => {
                _ = try out.write("\tdecb (%edi)\n");
                _ = try out.write("\n");
            },
            '.' => {
                _ = try out.write("\tmovl $4, %eax\n");
                _ = try out.write("\tmovl $1, %ebx\n");
                _ = try out.write("\tmovl %edi, %ecx\n");
                _ = try out.write("\tmovl $1, %edx\n");
                _ = try out.write("\tint $0x80\n");
                _ = try out.write("\n");
            },
            ',' => {
                _ = try out.write("\tmovl $3, %eax\n");
                _ = try out.write("\tmovl $0, %ebx\n");
                _ = try out.write("\tmovl %edi, %ecx\n");
                _ = try out.write("\tmovl $1, %edx\n");
                _ = try out.write("\tint $0x80\n");
                _ = try out.write("\n");
            },
            '[' => {
                if (stack_ptr == stack_size_var) {
                    stack_size_var *= 2;
                    // if () |_| {} else |_| {
                    //     try std.io.getStdErr().writer().print("error: couldn't reallocate stack {}\n", stack_size_var * 8);
                    //     allocator.free(stack);
                    //     return -1;
                    // }
                    const temp: []u64 = try allocator.realloc(stack, stack_size_var * 8);
                    stack = temp;
                }

                label_num += 1;
                stack[stack_ptr] = label_num;
                stack_ptr += 1;

                _ = try out.write("\tcmpb $0, (%edi)\n");
                _ = try bufPrint(buff, "\tjz .LE{d}\n", .{label_num});

                for (buff) |val| {
                    try out.writer().writeByte(val);
                }

                _ = try bufPrint(buff, ".LB{d}:\n", .{label_num});

                for (buff) |val| {
                    _ = try out.writer().writeByte(val);
                }
                //_ = try out.write("\n");
            },
            ']' => {
                _ = try out.write("\tcmpb $0, (%edi)\n");

                stack_ptr -= 1;
                _ = try bufPrint(buff, "\tjnz .LB{d}\n", .{stack[stack_ptr]});
                for (buff) |val| {
                    _ = try out.writer().writeByte(val);
                }
                _ = try bufPrint(buff, ".LE{d}:\n", .{stack[stack_ptr]});
                for (buff) |val| {
                    _ = try out.writer().writeByte(val);
                }
                //_ = try out.write("\n");
            },
            else => {},
        }
    } else |_| {}

    _ = try out.write("\n");
    _ = try out.write("\tmovl $1, %eax\n");
    _ = try out.write("\tmovl $0, %ebx\n");
    _ = try out.write("\tint $0x80\n");
    _ = try out.write("\n");

    allocator.free(stack);
    return 0;
}
