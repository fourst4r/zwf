const std = @import("std");
const fs = std.fs;
const print = std.debug.print;
const SwfFile = @import("zwf").SwfFile;

pub fn main() !void {
    const allocator = std.testing.allocator;
    const data = try fs.cwd().readFileAlloc(allocator, "./assets/platform-racing-2-v159.swf", 0xffffff);
    const swf = SwfFile.read(data);
    print("{}\n", .{swf.header});
    
}
