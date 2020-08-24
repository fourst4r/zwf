const std = @import("std");
const testing = std.testing;
const mem = std.mem;
const fs = std.fs;
const debug = std.debug;
const SwfReader = @import("swf_reader.zig").SwfReader;
const ArrayList = std.ArrayList;

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

    pub const TagType = enum(u10) {
        end = 0,
        show_frame = 1,
        define_shape,
        place_object,
        remove_object,
        define_bits,
        define_button,
        jpeg_tables,
        set_background_color,
        define_font,
        define_text,
        do_action,
        define_font_info,
        define_sound,
        start_sound,
        define_button_sound = 17,
        sound_stream_head,
        sound_stream_block,
        define_bits_lossless,
        define_bits_jpeg2,
        define_shape2,
        define_button_cxform,
        protect,
        place_object2,
        remove_object2,
        define_shape3,
        define_text2,
        define_button2,
        define_bits_jpeg3,
        define_bits_lossless2,
        define_edit_text,
        define_sprite,
        frame_label,
        sound_stream_head2,
        define_morph_shape,
        define_font2,
        export_assets,
        import_assets,
        enable_debugger,
        do_init_action,
        define_video_stream,
        video_frame,
        define_font_info2,
        enable_debugger2,
        script_limits,
        set_tab_index,
        file_attributes = 69,
    };

    pub const Tag = union(TagType) {
        end: void,
        show_frame: void,
        define_shape: void,
        place_object: void,
        remove_object: void,
        define_bits: void,
        define_button: void,
        jpeg_tables: void,
        set_background_color: void,
        define_font: void,
        define_text: void,
        do_action: void,
        define_font_info: void,
        define_sound: void,
        start_sound: void,
        define_button_sound: void,
        sound_stream_head: void,
        sound_stream_block: void,
        define_bits_lossless: void,
        define_bits_jpeg2: void,
        define_shape2: void,
        define_button_cxform: void,
        protect: void,
        place_object2: void,
        remove_object2: void,
        define_shape3: void,
        define_text2: void,
        define_button2: void,
        define_bits_jpeg3: void,
        define_bits_lossless2: void,
        define_edit_text: void,
        define_sprite: void,
        frame_label: void,
        sound_stream_head2: void,
        define_morph_shape: void,
        define_font2: void,
        export_assets: void,
        import_assets: void,
        enable_debugger: void,
        do_init_action: void,
        define_video_stream: void,
        video_frame: void,
        define_font_info2: void,
        enable_debugger2: void,
        script_limits: void,
        set_tab_index: void,
        file_attributes: packed struct {
            // _: u1,
            use_direct_blit: bool,
            use_gpu: bool,
            has_metadata: bool,
            as3: bool,
            // __: u2,
            use_network: bool,
        },
    };

    header: Header,
    tags: ArrayList(Tag),

    pub fn init(allocator: *mem.Allocator, stream: anytype) !SwfFile {
        var reader = SwfReader(@TypeOf(stream)).init(allocator, stream);
        return SwfFile{
            .header = try reader.readHeader(),
            .tags = try reader.readTags(),
        };
    }

    pub fn deinit(self: *SwfFile) void {
        self.tags.deinit();
    }
};