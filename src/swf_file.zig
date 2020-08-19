const std = @import("std");
const testing = std.testing;
const mem = std.mem;
const fs = std.fs;
const debug = std.debug;

pub const SwfFile = struct {
    pub const Rect = struct {
        bytes: []u8,

        pub fn nBits(self: Rect) u5 {
            return self.bytes[0];
        }

        pub fn xMin(self: Rect) i32 {
            return 0;
        }
    };

    pub const Header = struct {
        signature: [3]u8,
        version: u8,
        file_len: u32,
        frame_size: Rect
    };

    header: *Header,

    pub fn read(data: []u8) SwfFile {
        return SwfReader.init(data).swf;
    }
};

test "size" {
    testing.expect(8 == @sizeOf(SwfFile.Header));
}

pub const SwfReader = struct {
    const Self = @This();

    buf: []u8,
    pos: u64,
    swf: SwfFile,

    pub fn init(data: []u8) SwfReader {
        var r: SwfReader = undefined;
        r.buf = data;
        r.pos = 0;

        // r.swf.header = r.readRaw(SwfFile.Header);

        r.swf.header.frame_size = r.readRect();
        return r;
    }

    // fn readRaw(self: *Self, comptime T: type) *T {
    //     defer self.pos += @sizeOf(T);
    //     return @ptrCast(*T, self.buf[self.pos..@sizeOf(T)]);
    // }

    fn readRect(self: *Self) SwfFile.Rect {
        const n_bits = @intCast(usize, self.buf[self.pos]>>3);
        const n_bytes = ((5 + 4*n_bits) + 7) / 8;

        debug.print("n_bits={} and n_bytes={}\n",.{n_bits, n_bytes});
        defer self.pos += n_bytes;
        return SwfFile.Rect{.bytes = self.buf[self.pos..self.pos+n_bytes]};
    }

    fn readU8(self: *Self) u8 {
        defer self.pos += 1;
        return self.buf[self.pos..self.pos+1];
    }

    fn read(self: *Self, comptime T: type) T {
        defer self.pos += @sizeOf(T);
        return self.buf[self.pos..self.pos+@sizeOf(T)];
    }
};

test "load file" {
    // debug.print("TEST INFO BLAHBLAH", .{});
    // debug.print("{}", .{fs.cwd()});
    // const allocator = std.testing.allocator;
    // const data = try fs.cwd().readFileAlloc(allocator, "../../assets/platform-racing-2-v159.swf", 0xffffff);
    // const swf = SwfFile.read(data);
    // debug.print("{}", .{swf.header});
}
