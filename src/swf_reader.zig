const std = @import("std");
const io = std.io;
const builtin = std.builtin;
const SwfFile = @import("swf_file.zig").SwfFile;

pub fn SwfReader(comptime ReaderType: type) type {
    return struct {
        const Self = @This();

        reader: io.BitReader(.Big, ReaderType),

        pub fn init(forward_reader: ReaderType) Self {
            return Self{
                .reader = io.bitReader(.Big, forward_reader),
            };
        }

        pub fn readHeader(self: *Self) !SwfFile.Header {
            var header: SwfFile.Header = undefined;
            header.signature = [3]u8{
                try self.readInt(u8),
                try self.readInt(u8),
                try self.readInt(u8),
            };
            header.version = try self.readInt(u8);
            header.file_len = try self.readInt(u32);
            header.frame_size = try self.readRect();
            header.frame_rate = try self.readFixed8();
            header.frame_count = try self.readInt(u16);
            return header;
        }

        pub fn readTag(self: *Self) void {
            const tag = try self.reader.readBitsNoEof(u10, 10);
            var len = try self.reader.readBitsNoEof(u6, 6);
            if (len >= 63) {
                len = try self.readInt(u32);
            }
            
        }

        fn readInt(self: *Self, comptime Int: type) !Int {
            var b: [@sizeOf(Int)]u8 = undefined;
            const n_read = try self.reader.read(b[0..]);
            if (n_read < b.len) return error.EndOfStream;
            return @bitCast(Int, b);
        }

        fn readFixed(self: *Self) !SwfFile.Fixed {
            return @intToFloat(SwfFile.Fixed, try self.readInt(u32)) / 65536.0;
        }

        fn readFixed8(self: *Self) !SwfFile.Fixed8 {
            return @intToFloat(SwfFile.Fixed8, try self.readInt(u16)) / 256.0;
        }

        fn readRect(self: *Self) !SwfFile.Rect {
            self.reader.alignToByte();
            defer self.reader.alignToByte();

            const n_bits = try self.reader.readBitsNoEof(u5, 5);
            return SwfFile.Rect{
                .xMin = @bitCast(i16, try self.reader.readBitsNoEof(u16, n_bits)),
                .xMax = @bitCast(i16, try self.reader.readBitsNoEof(u16, n_bits)),
                .yMin = @bitCast(i16, try self.reader.readBitsNoEof(u16, n_bits)),
                .yMax = @bitCast(i16, try self.reader.readBitsNoEof(u16, n_bits)),
            };
        }
    };
}