const std = @import("std");
const fs = std.fs;
const print = std.debug.print;
const SwfFile = @import("zwf").SwfFile;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = &arena.allocator;

    var file = try fs.cwd().openFile("./assets/platform-racing-2-v159.swf", .{});
    defer file.close();

    const swf = try SwfFile.init(allocator, file.reader());
    print("{}\n", .{swf.header});
}
