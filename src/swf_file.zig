const std = @import("std");
const testing = std.testing;
const mem = std.mem;
const fs = std.fs;
const debug = std.debug;
const SwfReader = @import("swf_reader.zig").SwfReader;

pub const SwfFile = struct {
    /// 32-bit 16.16 fixed-point number.
    pub const Fixed = u32;
    /// 16-bit 8.8 fixed-point number.
    pub const Fixed8 = f16;

    pub const Rect = struct {
        xMin: i16,
        xMax: i16,
        yMin: i16,
        yMax: i16,
    };

    pub const Header = struct {
        signature: [3]u8,
        /// Single byte SWF version.
        version: u8,
        /// Length of entire file in bytes.
        file_len: u32,
        /// Frame size in twips.
        frame_size: Rect,
        /// Frame delay in 8.8 fixed number of frames per second.
        frame_rate: Fixed8,
        /// Total number of frames in file.
        frame_count: u16,
    };

    header: Header,

    pub fn init(stream: anytype) !SwfFile {
        var reader = SwfReader(@TypeOf(stream)).init(stream);
        return SwfFile{
            .header = try reader.readHeader(),
            
        };
    }

};