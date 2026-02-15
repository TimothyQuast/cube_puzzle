const std = @import("std");

const cube_puzzle = @import("cube_puzzle");

// format for files:
// u1 -- true/false is completee
//
// [] u12 -- placements.
//
//

// 216 points (6**3).
// point is a u8 from 0 to 215.
// x = @mod(point, 6);
// y = @mod(@divTrunc(point,6), 6);
//
// 8 corner points -- 0 rlacements.
// 12 x 4 = 48 edge points -- 2 placements.
// 6 x 4 x 4 = 96 face points --  6 placements.
// 4 x 4 x 4 = 64 interior points --  12 placements
// Total: 48x2 + 96x6 + 64x12 = 96 + 576 + 768.
// Total: 1440.
// placement: u10.
//
// Actually lets just use a bigger onee.
// 6 x 6 x 6 x 12 = 2592.
// so use u12. from 0 2591.
// branchdir = @mod(pos, 12); 
// rootx = @mod( pos /_ 12, 6); 
// rooty = @mod( pos /_ 72, 6); 
// rootz = @mod( pos /_ 432, 6); 
//
// point: u8
// piece: u12
//

fn get_coords(point: u8) Point {
  return .{
    .x = @truncate(@mod(point, 6)),
    .y = @truncate(@mod(point / 6, 6)),
    .z = @truncate(@mod(point / 36, 6)),
  }; 
}

const Branches = packed struct {
    leaf_axis_next: u1,
    branch_up: u1, // 0 -- +, 1 -- -
    branch_axis: u2, // 0 -- x, 1 -- y, 2 -- x, 3 -- impossible
};

fn get_points(piece: u12) ?[4]u8 {
  const root :u8 = @truncate(piece / 12);
  // now piece mod 12 is 0 to 11.
  // 0 -- branch x-, leaves z
  // 1 -- x+, z
  // 2 -- x-, y
  // 3 -- x+, y
  
  const root_p = get_coords(root);

  const br: u4 = @truncate(@mod(piece,12));

  const branches: Branches = @bitCast(br);

  
  const stem:u8 = switch(branches.branch_axis) {  
    0 => ( // x-axis
        switch (branches.branch_up) {
            0 => (if(root_p.x == 0){return null;} else root - 1),
            1 => (if(root_p.x == 5){return null;} else root + 1),
        }
    ),
    1 => ( // y-axis
        switch (branches.branch_up) {
            0 => (if(root_p.y == 0){return null;} else root - 6),
            1 => (if(root_p.y == 5){return null;} else root + 6),
        }
    ),
    2 => ( // z-axis
        switch (branches.branch_up) {
            0 => (if(root_p.z == 0){return null;} else root - 36),
            1 => (if(root_p.z == 5){return null;} else root + 36),
        }
    ),
    else => {
        std.debug.print("branches too big", .{});
        return null;
    },
  };

  const stem_p = get_coords(stem);

  const leaves: struct {
    d: u8, u: u8
  } = switch (
        (
          branches.branch_axis 
          +% (2 - @as(u2, branches.leaf_axis_next))
        ) % 3
    ){
      0 => ( // x leaf axis
        if (stem_p.x == 0 or stem_p.x == 5)
        {return null;}
        else .{.d = stem - 1, .u = stem + 1}
      ),
      1 => ( // y leaf axis
        if (stem_p.y == 0 or stem_p.y == 5)
        {return null;}
        else .{.d = stem - 6, .u = stem + 6}
      ),
      2 => ( // z leaf axis
        if (stem_p.z == 0 or stem_p.z == 5)
        {return null;}
        else .{.d = stem - 36, .u = stem + 36}
      ),
      else => {
        std.debug.print("leaves bad", .{});
        return null;
      }
  };

  

  return .{root, stem, leaves.d, leaves.u};

} 

const Point = packed struct {
    x: u3,
    y: u3,
    z: u3
};

pub fn step(
  allocator: std.mem.Allocator,
  io: std.Io,
  i: usize,
) !void {

    _ = allocator;

    var path_buf: [64]u8 = undefined;
    var piece_buf: [1024] u8 = undefined;
    var arrangement: [54]u8 = undefined;
    if (i == 1) {
        // make step 1 file
        const step1_path = try std.fmt.bufPrint(
                &path_buf, "steps/1", .{}
            );
        const step1_file = try std.Io.Dir
            .cwd()
            .createFile(io, step1_path, .{});
        var writer = std.Io.File.Writer.init(
            step1_file, io, &piece_buf
        );

        arrangement[0] = 17;
        arrangement[1] = 37;
        try writer.interface.writeAll(
            arrangement[0..2]
        );
        try writer.interface.flush();
        return;
    }
    const prev_path = try std.fmt.bufPrint(
        &path_buf, "steps/{}", .{i-1}
    );

    const is_prev_f_exist = 
        if (std.Io.Dir.cwd().access(io, prev_path, .{})) true
        else |_| false;

    if (!is_prev_f_exist) {
        return;
    }

    // var buf: [64]u12 = undefined;

   // const file = std.Io.Dir.cwd().openFile();

}


pub fn main(init: std.process.Init) !void {
    const arena: std.mem.Allocator =
        init.arena.allocator();


    const env = std.process.Environ.empty;
    var threaded = std.Io.Threaded.init(
      arena,
      .{.environ = env},
    );
    const io = threaded.io();
    defer threaded.deinit();


    for (1..54) |i| {
        try step(arena, io, i);
    }

}


test "get coords" {
  const p0 = 0;
  const coords = get_coords(p0);

  try std.testing.expectEqual(coords.x, 0);
}


test "get points" {
  const coords = get_points(2134);
  std.debug.print("{}", .{coords.?[0]});
  std.debug.print("{}", .{coords.?[1]});
  std.debug.print("{}", .{coords.?[2]});
  std.debug.print("{}", .{coords.?[3]});

}
