// Number of non-thumb rows (some might be short because of reduced_inner_cols and reduced_outer_cols)
nrows = 3;
// Number of non-thumb columns
ncols = 6;
alpha = 0.26179916666666664;
beta = 0.08726638888888888;
// Column which is considered the middle for curvature purposes
centercol = 3;
// Row, counting from the bottom, considered the middle for curvature purposes
centerrow_offset = 1;
// Additonal left-to-right angle of keys
tenting_angle = 0.42;
// if nrows > 5, this should warn that we want standard
column_style = "orthographic"; // orthographic, fixed, standard
reduced_inner_cols = 0;
reduced_outer_cols = 0;
//thumb_offsets = [6, -3, 7];
keyboard_z_offset = 20;
extra_width = 2.5;
extra_height = 1.0;
web_thickness = 5.1;
post_size = 0.1;
post_adj = 0;
//thumb_style = "TRACKBALL_CJ";

plate_thickness = 5.1;
plate_rim = 2.0;

plate_style = "NOTCH";

sa_profile_key_height = 12.7;
sa_length = 18.5;

hole_keyswitch_height = 14.0;
hole_keyswitch_width = 14.0;
nub_keyswitch_height = 14.4;
nub_keyswitch_width = 14.4;
undercut_keyswitch_height = 14.0;
undercut_keyswitch_width = 14.0;

screws_offset = "INSIDE";

column_offsets = [
    [ 0, 0, 0 ],
    [ 0, 0, 0 ],
    [ 0, 2.82, -4.5 ],
    [ 0, 0, 0 ],
    [ 0, -6, 5 ],
    [ 0, -6, 5 ],
    [ 0, -6, 5 ]
];

wall_z_offset = 15;
wall_x_offset = 5;
wall_y_offset = 6;

wall_thickness = 4.5;
wall_base_y_thickness = 4.5;
wall_base_x_thickness = 4.5;
wall_base_back_thickness = 4.5;

screw_insert_height = 3.8;
screw_insert_outer_radius = 4.25;

controller_mount_type = "EXTERNAL";
external_holder_height = 12.5;
external_holder_width = 28.75;
external_holder_xoffset = -5.0;
external_holder_yoffset = -4.5;

function deg2rad(d) = d*PI/180;
function rad2deg(r) = r*180/PI;

plate_styles = [
  ["HOLE",        hole_keyswitch_height,     hole_keyswitch_width],
  ["NUB",         nub_keyswitch_height,      nub_keyswitch_width],
  ["HS_NUB",      nub_keyswitch_height,      nub_keyswitch_width],
  ["UNDERCUT",    undercut_keyswitch_height, undercut_keyswitch_width],
  ["HS_UNDERCUT", undercut_keyswitch_height, undercut_keyswitch_width],
  ["NOTCH",       undercut_keyswitch_height, undercut_keyswitch_width],
  ["HS_NOTCH",    undercut_keyswitch_height, undercut_keyswitch_width]
];

function lookup(table, key, column=false) =
  let (
    matching_rows = [for (i = [0 : len(table)]) if (table[i][0] == key) table[i]],
    a1 = assert(len(matching_rows) > 0, str("Invalid key ", key, " for table.")),
    a2 = assert(len(matching_rows) < 2, "Table has multiple matching keys.")
  )
  (column == false) ? matching_rows[0] : matching_rows[0][column];

keyswitch_height = lookup(plate_styles, plate_style, 1);
keyswitch_width = lookup(plate_styles, plate_style, 2);

mount_width = keyswitch_width + 2 * plate_rim;
mount_height = keyswitch_height + 2 * plate_rim;
mount_thickness = plate_thickness;

centerrow = nrows - centerrow_offset;
lastrow = nrows - 1;
cornerrow = (reduced_outer_cols>0 || reduced_inner_cols>0) ? lastrow - 1 : lastrow;
lastcol = ncols - 1;

cap_top_height = plate_thickness + sa_profile_key_height;
row_radius = ((mount_height + extra_height) / 2) / (sin(rad2deg(alpha / 2))) + cap_top_height;

column_radius = ((mount_width + extra_width) / 2) / sin(rad2deg(beta / 2)) + cap_top_height;
column_x_delta = -1 - column_radius * sin(rad2deg(beta));
column_base_angle = beta * (centercol - 2);

function translate_matrix(pos) =
    [[1, 0, 0, pos.x],
     [0, 1, 0, pos.y],
     [0, 0, 1, pos.z],
     [0, 0, 0, 1    ]];
function rotate_x_matrix(rad) =
    let(deg = rad2deg(-rad))
    [[1,         0,        0, 0],
     [0,  cos(deg), sin(deg), 0],
     [0, -sin(deg), cos(deg), 0],
     [0,         0,        0, 1]];
function rotate_y_matrix(rad) =
    let(deg = rad2deg(-rad))
    [[cos(deg), 0, -sin(deg), 0],
     [       0, 1,         0, 0],
     [sin(deg), 0,  cos(deg), 0],
     [       0, 0,         0, 1]];

column_styles = [
  ["orthographic",
   function(column, row)
     let(
         column_angle = beta * (centercol - column),
         column_z_delta = column_radius * (1 - cos(rad2deg(column_angle)))
     )
     translate_matrix([0, 0, keyboard_z_offset]) *
     rotate_y_matrix(tenting_angle) *
     translate_matrix(column_offsets[column]) *
     translate_matrix([-(column - centercol) * column_x_delta, 0, column_z_delta]) *
     rotate_y_matrix(column_angle) *
     translate_matrix([0, 0, row_radius]) *
     rotate_x_matrix(alpha * (centerrow - row)) *
     translate_matrix([0, 0, -row_radius])
   ]
];

function key_placement_matrix(column, row, column_style=column_style) =
    let (placement_fn = lookup(column_styles, column_style, 1))
    placement_fn(column, row);

function left_key_placement_matrix(row, direction) =
    let (
      pos = key_placement_matrix(0, row) * [-mount_width * 0.5, direction * mount_height * 0.5, 0, 1]
    )
    translate_matrix([ pos.x, pos.y, pos.z ]);

module key_place(column, row) {
    multmatrix(key_placement_matrix(column, row, column_style)) children();
}

module web_post() {
    translate([0, 0, plate_thickness - (web_thickness / 2)])
        cube([post_size, post_size, web_thickness], center=true);
}

module web_post_tr() {
    translate([(mount_width / 2) - post_adj, (mount_height / 2) - post_adj, 0])
        web_post();
}

module web_post_tl() {
    translate([-(mount_width / 2) - post_adj, (mount_height / 2) - post_adj, 0])
        web_post();
}

module web_post_bl() {
    translate([-(mount_width / 2) - post_adj, -(mount_height / 2) - post_adj, 0])
        web_post();
}

module web_post_br() {
    translate([(mount_width / 2) - post_adj, -(mount_height / 2) - post_adj, 0])
        web_post();
}

module bottom_hull(height = 0.001) {
    hull() {
      translate([0, 0, height/2 - 10])
        linear_extrude(height=height, twist=0, convexity=0, center=true)
        projection(cut = false)
        children();
      children();
    }
}

function wall_locate1(dx, dy) = [dx * wall_thickness, dy * wall_thickness, -1];
function wall_locate2(dx, dy) = [dx * wall_x_offset, dy * wall_y_offset, -wall_z_offset];
function wall_locate3(dx, dy, back) = back ?
    [
        dx * (wall_x_offset + wall_base_x_thickness),
        dy * (wall_y_offset + wall_base_back_thickness),
        -wall_z_offset
    ] : [
        dx * (wall_x_offset + wall_base_x_thickness),
        dy * (wall_y_offset + wall_base_y_thickness),
        -wall_z_offset
    ];

module wall_brace(place1, dx1, dy1, place2, dx2, dy2, back=false) {
    hull() {
        multmatrix(place1) children(0);
        multmatrix(place1) translate(wall_locate1(dx1, dy1)) children(0);
        multmatrix(place1) translate(wall_locate2(dx1, dy1)) children(0);
        multmatrix(place1) translate(wall_locate3(dx1, dy1, back)) children(0);
        multmatrix(place2) children(1);
        multmatrix(place2) translate(wall_locate1(dx2, dy2)) children(1);
        multmatrix(place2) translate(wall_locate2(dx2, dy2)) children(1);
        multmatrix(place2) translate(wall_locate3(dx2, dy2, back)) children(1);
    }
    bottom_hull() {
        multmatrix(place1) translate(wall_locate2(dx1, dy1)) children(0);
        multmatrix(place1) translate(wall_locate3(dx1, dy1, back)) children(0);
        multmatrix(place2) translate(wall_locate2(dx2, dy2)) children(1);
        multmatrix(place2) translate(wall_locate3(dx2, dy2, back)) children(1);
    }
}

module key_wall_brace(x1, y1, dx1, dy1, x2, y2, dx2, dy2, back=false) {
  place1 = key_placement_matrix(x1, y1);
  place2 = key_placement_matrix(x2, y2);
  wall_brace(place1, dx1, dy1, place2, dx2, dy2, back=back) {
    children(0);
    children(1);
  }
}

module back_wall() {
  x = 0;
  key_wall_brace(x, 0, 0, 1, x, 0, 0, 1, back=true) { web_post_tl(); web_post_tr(); }
  for (x = [1 : ncols - 1]) {
    key_wall_brace(x, 0, 0, 1, x, 0, 0, 1, back=true) { web_post_tl(); web_post_tr(); }
    key_wall_brace(x, 0, 0, 1, x - 1, 0, 0, 1, back=true) { web_post_tl(); web_post_tr(); }
  }
  key_wall_brace(lastcol, 0, 0, 1, lastcol, 0, 1, 0, back=true) { web_post_tr(); web_post_tr(); }
  key_wall_brace(lastcol, 0, 0, 1, lastcol, 0, 1, 0) { web_post_tr(); web_post_tr(); }
}

module outer_wall() { // was right_wall
  y = 0;
  corner = reduced_outer_cols > 0 ? cornerrow : lastrow;
  key_wall_brace(lastcol, y, 1, 0, lastcol, y, 1, 0) { web_post_tr(); web_post_br(); }
  for (y = [1 : corner]) {
    key_wall_brace(lastcol, y - 1, 1, 0, lastcol, y, 1, 0) { web_post_br(); web_post_tr(); }
    key_wall_brace(lastcol, y, 1, 0, lastcol, y, 1, 0) { web_post_tr(); web_post_br(); }
  }
  key_wall_brace(lastcol, corner, 0, -1, lastcol, corner, 1, 0) { web_post_br(); web_post_br(); }
}

module inner_wall() { // was left_wall
  wall_brace(
    key_placement_matrix(0, 0), 0, 1,
    left_key_placement_matrix(0, 1), 0, 1
  ) {
    web_post_tl();
    web_post();
  }
  wall_brace(
    left_key_placement_matrix(0, 1), 0, 1,
    left_key_placement_matrix(0, 1), -1, 0
  ) {
    web_post();
    web_post();
  }
  corner = reduced_inner_cols > 0 ? cornerrow : lastrow;
  for (y = [0 : corner]) {
    wall_brace(
      left_key_placement_matrix(y, 1), -1, 0,
      left_key_placement_matrix(y, -1), -1, 0
    ) {
      web_post();
      web_post();
    }
    hull() {
      key_place(0, y) web_post_tl();
      key_place(0, y) web_post_bl();
      multmatrix(left_key_placement_matrix(y, 1)) web_post();
      multmatrix(left_key_placement_matrix(y, -1)) web_post();
    }
  }
  for (y = [1 : corner]) {
    wall_brace(
      left_key_placement_matrix(y - 1, -1), -1, 0,
      left_key_placement_matrix(y, 1), -1, 0
    ) {
      web_post();
      web_post();
    }
    hull() {
      key_place(0, y) web_post_tl();
      key_place(0, y-1) web_post_bl();
      multmatrix(left_key_placement_matrix(y, 1)) web_post();
      multmatrix(left_key_placement_matrix(y-1, -1)) web_post();
    }
  }
}

module front_wall() {
  corner = cornerrow;
  offset_col = reduced_outer_cols > 0 ? ncols - reduced_outer_cols : 99;

  for (x = [3 : ncols - 1]) {
    if (x < (offset_col - 1)) {
      if (x > 3) {
        key_wall_brace(x-1, lastrow, 0, -1, x, lastrow, 0, -1) { web_post_br(); web_post_bl(); }
      }
      key_wall_brace(x, lastrow, 0, -1, x, lastrow, 0, -1) { web_post_bl(); web_post_br(); }
    } else if (x < offset_col) {
      if (x > 3) {
        key_wall_brace(x-1, lastrow, 0, -1, x, lastrow, 0, -1) { web_post_br(); web_post_bl(); }
      }
      key_wall_brace(x, lastrow, 0, -1, x, lastrow, 0.5, -1) { web_post_bl(); web_post_br(); }
    } else if (x == offset_col) {
      wall_bace(x - 1, lastrow, 0.5, -1, x, cornerrow, .5, -1) { web_post_br(); web_post_bl(); }
      key_wall_brace(x, cornerrow, .5, -1, x, cornerrow, 0, -1) { web_post_bl(); web_post_br(); }
    } else if (x == (offset_col + 1)) {
      key_wall_brace(x, cornerrow, 0, -1, x - 1, cornerrow, 0, -1) { web_post_bl(); web_post_br(); }
      key_wall_brace(x, cornerrow, 0, -1, x, cornerrow, 0, -1) { web_post_bl();  web_post_br(); }
    } else {
      key_wall_brace(x, cornerrow, 0, -1, x - 1, corner, 0, -1) { web_post_bl(); web_post_br(); }
      key_wall_brace(x, cornerrow, 0, -1, x, corner, 0, -1) { web_post_bl(); web_post_br(); }
    }
  }
}

module case_walls() {
  back_wall();
  inner_wall();
  outer_wall();
  front_wall();
}

// == screw inserts ==

all_screw_insert_positions =
  let (
    screws_offsets = lookup([
      [
        "INSIDE",
        wall_locate3(-1, 0) + [wall_base_x_thickness, 0, 0],
        wall_locate2(1, 0) + [mount_height/2 + -wall_base_x_thickness/2, 0, 0],
        wall_locate2(0, -1) - [0, (mount_height / 2) + -wall_base_y_thickness/2, 0],
        wall_locate2(0, 1) + [0, (mount_height / 2) + -wall_base_y_thickness/3, 0]
      ],
      [
        "OUTSIDE",
        wall_locate3(-1, 0),
        wall_locate2(1, 0) + [mount_height/2 + wall_base_x_thickness/2, 0, 0],
        wall_locate2(0, -1) - [0, (mount_height / 2) + wall_base_y_thickness*2/3, 0],
        wall_locate2(0, 1) + [0, (mount_height / 2) + wall_base_y_thickness*2/3, 0]
      ],
      [
        "ORIGINAL",
        wall_locate3(-1, 0),
        wall_locate2(1, 0) + [mount_height/2, 0, 0],
        wall_locate2(0, -1) - [0, mount_height / 2, 0],
        wall_locate2(0, 1) + [0, (mount_height / 2), 0]
      ]
    ], screws_offset),

    //FIXME: What's the actual height of the top of the plate, to set Z?
    screw_insert_z = 0,
    set_z = function(pos) [pos.x, pos.y, screw_insert_z],

    inner_wall_position = function(row)         set_z(left_key_placement_matrix(row, 0) * concat(screws_offsets[1], [1])),
    outer_wall_position = function(column, row) set_z(key_placement_matrix(column, row) * concat(screws_offsets[2], [1])),
    front_wall_position = function(column, row) set_z(key_placement_matrix(column, row) * concat(screws_offsets[3], [1])),
    back_wall_position  = function(column, row) set_z(key_placement_matrix(column, row) * concat(screws_offsets[4], [1]))
  ) [
    inner_wall_position(0),
    inner_wall_position(cornerrow),
    front_wall_position(3, lastrow),
    back_wall_position(3, 0),
    outer_wall_position(lastcol, 0),
    outer_wall_position(lastcol, cornerrow)
  ];

module screw_insert_outer() {
  cylinder(r = screw_insert_outer_radius, h = screw_insert_height + 1.5, center = true);
  translate([0, 0, screw_insert_height / 2]) sphere(r = screw_insert_outer_radius);
}

module screw_insert_outers() {
  for (i = [0 : len(all_screw_insert_positions)-1]) {
    translate(all_screw_insert_positions[i]) screw_insert_outer();
  }
}

module screw_insert_hole() {
  translate([0, 0, -1]) cylinder(r = 1.7, h = screw_insert_height + 1, center = true);
}

module screw_insert_holes() {
  for (i = [0 : len(all_screw_insert_positions)-1]) {
    translate(all_screw_insert_positions[i]) screw_insert_hole();
  }
}

module add_screw_inserts() {
  difference() {
    union() {
      children();
      screw_insert_outers();
    }
    screw_insert_holes();
  }
}

// == controller ==

module external_mount_hole() {
  external_start =
    [external_holder_width/2, 0, 0, 0] +
    (key_placement_matrix(0, 0) * concat((wall_locate3(0, 1) + [0, mount_height/2, 0]), [1]));

  translate([
    external_start.x + external_holder_xoffset,
    external_start.y + external_holder_yoffset,
    external_holder_height / 2 - .05
  ]) {
    cube([external_holder_width, 20.0, external_holder_height+0.1], center=true);
    translate([0, -5, 0])
      cube([external_holder_width+8, 10.0, external_holder_height+8+0.1], center=true);
  }
}

module add_controller() {
  if (controller_mount_type == "EXTERNAL") {
    difference() {
      children();
      external_mount_hole();
    }
  } else {
    assert(false, str("Unknown controller mount type ", controller_mount_type));
  }
}

module model_side() {
  add_controller()
    add_screw_inserts()
    case_walls();
}

model_side();
