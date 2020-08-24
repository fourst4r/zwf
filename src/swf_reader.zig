const std = @import("std");
const io = std.io;
const builtin = std.builtin;
const SwfFile = @import("swf_file.zig").SwfFile;
const print = std.debug.print;
const assert = std.debug.assert;
const mem = std.mem;
const ArrayList = std.ArrayList;

pub fn SwfReader(comptime ReaderType: type) type {
    return struct {
        const Self = @This();
        const byte_endianness = .Little;
        const bit_endianness = .Big;

        allocator: *mem.Allocator,
        reader: io.BitReader(bit_endianness, ReaderType),
        bytes_read: u64, // TODO: figure out CountingReader

        pub fn init(allocator: *mem.Allocator, forward_reader: ReaderType) Self {
            return Self{
                .allocator = allocator,
                .reader = io.bitReader(bit_endianness, forward_reader),
                .bytes_read = 0,
            };
        }

        pub fn readHeader(self: *Self) !SwfFile.Header {
            assert(self.bytes_read == 0);
            var header: SwfFile.Header = undefined;
            header.signature = [3]u8{
                try self.readInt(u8),
                try self.readInt(u8),
                try self.readInt(u8),
            };
            // print("bytes_read={} bits_read={}\n", .{self.bytes_read, self.bits_read});
            assert(self.bytes_read == 3);
            header.version = try self.readInt(u8);
            assert(self.bytes_read == 4);
            header.file_len = try self.readInt(u32);
            assert(self.bytes_read == 8);
            header.frame_size = try self.readRect();
            assert(self.bytes_read == 17);
            header.frame_rate = try self.readFixed8();
            assert(self.bytes_read == 19);
            header.frame_count = try self.readInt(u16);
            assert(self.bytes_read == 21);
            return header;
        }

        pub fn readTags(self: *Self) !ArrayList(SwfFile.Tag) {
            var tags = ArrayList(SwfFile.Tag).init(self.allocator);
            while (true) {
                var tag = try self.readTag();
                try tags.append(tag);
                if (tag == .end) break;
            }
            return tags;
        }

        pub fn readTag(self: *Self) !SwfFile.Tag {
            const d = try self.readInt(u16);
            const code = @intCast(u10, d >> 6);
            var len: u32 = d & 63;
            print("code={}", .{code});
            const tag_type = @intToEnum(SwfFile.TagType, code);
            print(":{} len={}\n", .{tag_type, len});

            if (len >= 63) {
                len = try self.readInt(u32);
            }

            const begin = self.bytes_read;
            var tag: SwfFile.Tag = undefined;
            switch (tag_type) {
                .file_attributes => {
                    _ = try self.readBits(u1, 1); // reserved
                    const use_direct_blit = try self.readBits(u1, 1);
                    const use_gpu = try self.readBits(u1, 1);
                    const has_metadata = try self.readBits(u1, 1);
                    const as3 = try self.readBits(u1, 1);
                    _ = try self.readBits(u2, 2); // reserved
                    const use_network = try self.readBits(u1, 1);
                    print("bytred={}\n", .{self.bytes_read});
                    tag = SwfFile.Tag{ 
                        .file_attributes = .{
                            .use_direct_blit = @bitCast(bool, use_direct_blit),
                            .use_gpu = @bitCast(bool, use_gpu),
                            .has_metadata = @bitCast(bool, has_metadata),
                            .as3 = @bitCast(bool, as3),
                            .use_network = @bitCast(bool, use_network),
                        },
                    };
                },
                else => tag = .end,
            }

            const unread = len-(self.bytes_read-begin);
            print("unread tag bytes: {}\n", .{unread});
            var trash_can: [0xff]u8 = undefined;
            _ = try self.readBytes(trash_can[0..unread]);

            return tag;
        }

        fn readInt(self: *Self, comptime Int: type) !Int {
            var b: [@sizeOf(Int)]u8 = undefined;
            const n = try self.readBytes(b[0..]);
            // self.bytes_read += n;
            // if (n < b.len) return error.EndOfStream;
            // reverse byte order for big-endian?
            return @bitCast(Int, b);
        }

        fn readBytes(self: *Self, buf: []u8) !usize {
            self.alignToByte();
            const n = try self.reader.read(buf);
            self.bytes_read += n;
            if (n < buf.len) return error.EndOfStream;
            return n;
        }

        fn readBits(self: *Self, comptime U: type, bits: usize) !U {
          
            var b = (self.reader.bit_count + bits) / 8;
            if (self.reader.bit_count == 0) b += 1;
            self.bytes_read += b;

            var n: usize = undefined;
            const result = try self.reader.readBits(U, bits, &n);
            if (n < bits) return error.EndOfStream;

            return result;
        }

        test "bytes_read" {

        }

        fn alignToByte(self: *Self) void {
            self.reader.alignToByte();
        }

        fn readFixed(self: *Self) !SwfFile.Fixed {
            return @intToFloat(SwfFile.Fixed, try self.readInt(u32)) / 65536.0;
        }

        fn readFixed8(self: *Self) !SwfFile.Fixed8 {
            return @intToFloat(SwfFile.Fixed8, try self.readInt(u16)) / 256.0;
        }

        fn readRect(self: *Self) !SwfFile.Rect {
            self.alignToByte();
            defer self.alignToByte();

            const n_bits = try self.readBits(u5, 5); // +1
            assert(self.bytes_read == 9);
            defer assert(self.bytes_read == 8+ (((5 + 4*@as(u64,n_bits)) + 7) / 8));
            // print("n_bits={}\n",.{n_bits});
            defer print("bytes_read={}\n", .{self.bytes_read});

            return SwfFile.Rect{
                .xMin = @bitCast(i16, try self.readBits(u16, n_bits)),
                .xMax = @bitCast(i16, try self.readBits(u16, n_bits)),
                .yMin = @bitCast(i16, try self.readBits(u16, n_bits)),
                .yMax = @bitCast(i16, try self.readBits(u16, n_bits)),
            };
        }
    };
}

/// A Reader that counts how many bytes has been written to it.
pub fn CountingReader(comptime ReaderType: type) type {
    return struct {
        bytes_read: u64,
        child_stream: ReaderType,

        pub const Error = ReaderType.Error;
        pub const Reader = io.Reader(*Self, Error, read);
        /// Deprecated: use `Reader`
        pub const InStream = Reader;

        const Self = @This();

        pub fn read(self: *Self, buffer: []u8) Error!usize {
            const amt = try self.child_stream.read(buffer);
            self.bytes_read += amt;
            return amt;
        }

        pub fn reader(self: *Self) Reader {
            return .{ .context = self };
        }

        /// Deprecated: use `reader`
        pub fn inStream(self: *Self) InStream {
            return .{ .context = self };
        }
    };
}

pub fn countingReader(child_stream: anytype) CountingReader(@TypeOf(child_stream)) {
    return .{ .bytes_read = 0, .child_stream = child_stream };
}

// test "io.CountingReader" {
//     var counting_stream = countingReader(std.io.null_writer);
//     const stream = counting_stream.reader();

//     const bytes = "yay" ** 100;
//     stream.writeAll(bytes) catch unreachable;
//     testing.expect(counting_stream.bytes_written == bytes.len);
// }
