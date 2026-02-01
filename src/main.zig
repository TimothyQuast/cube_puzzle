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

fn get_points(piece: u12) [4] u8 {
  const branches: u8 = @truncate(@mod(piece, 12));
  _ = branches;
  const root :u8 = @truncate(piece / 12);

  return &.{root, 0, 0, 0};

} 

const Point = packed struct {
    x: u3,
    y: u3,
    z: u3
};

pub fn step(
  allocator: std.mem.Allocator,
  i: usize,
) void {

    const env = std.process.Environ.empty;
    var threaded = std.Io.Threaded.init(
      allocator,
      .{.environ = env},
    );
    const io = threaded.io();
    defer threaded.deinit();

    var path_buf: [64]u8 = undefined;
    const path = try std.fmt.bufPrint(
        &path_buf, "steps/{}", .{i}
    );

    const is_f_exist = 
        if (std.Io.Dir.cwd().access(io, path, .{})) true
        else |_| false;




  // check if prev step file already exists.
  // if exist => check if done.
  // if done => check if this step exists and done.
  // decide whether to go back or forward .or do.
  //
  //
}


pub fn main(init: std.process.Init) !void {
    const arena: std.mem.Allocator =
        init.arena.allocator();

    if (
    ) {
      std.debug.print("File exists\n", .{});
    }
    else |_| {}

    for (1..54) |i| {
        step(arena, i);
    }

}


test "get coords" {
  const p0 = 0;
  const coords = get_coords(p0);

  try std.testing.expectEqual(coords.x, 0);
}
