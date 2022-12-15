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

function deg2rad(d) = d*PI/180;
function rad2deg(r) = r*180/PI;

keyswitch_height = (plate_style == "NUB" || plate_style == "HS_NUB") ? nub_keyswitch_height :
                   (plate_style == "UNDERCUT" || plate_style == "HS_UNDERCUT" || plate_style == "NOTCH" || plate_style == "HS_NOTCH") ? undercut_keyswitch_height :
                   hole_keyswitch_height;
keyswitch_width = (plate_style == "NUB" || plate_style == "HS_NUB") ? nub_keyswitch_width :
                   (plate_style == "UNDERCUT" || plate_style == "HS_UNDERCUT" || plate_style == "NOTCH" || plate_style == "HS_NOTCH") ? undercut_keyswitch_width :
                   hole_keyswitch_width;

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

function orthographic_key_placement_matrix(column, row) =
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
    translate_matrix([0, 0, -row_radius]);

function key_placement_matrix(column, row, column_style=column_style) =
    let (_ = assert(column_style == "orthographic", "Only orthographic is implemented."))
    orthographic_key_placement_matrix(column, row);

module key_place(column, row) {
    multmatrix(key_placement_matrix(column, row, column_style)) children();
}

module web_post() {
    translate([0, 0, plate_thickness - (web_thickness / 2)])
        cube([post_size, post_size, web_thickness]);
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
    translate([0, 0, height/2 - 10])
    linear_extrude(height=height, twist=0, convexity=0, center=true)
    projection(cut = false)
    hull()
    children();
}

module wall_brace(place1, x1, y1, dx1, dy1, place2, x2, y2, dx2, dy2, back=false) {
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

    hull() {
        multmatrix(place1(x1, y1)) children(0);
        multmatrix(place1(x1, y1)) translate(wall_locate1(dx1, dy1)) children(0);
        multmatrix(place1(x1, y1)) translate(wall_locate2(dx1, dy1)) children(0);
        multmatrix(place1(x1, y1)) translate(wall_locate3(dx1, dy1, back)) children(0);
        multmatrix(place2(x2, y2)) children(1);
        multmatrix(place2(x2, y2)) translate(wall_locate1(dx2, dy2)) children(1);
        multmatrix(place2(x2, y2)) translate(wall_locate2(dx2, dy2)) children(1);
        multmatrix(place2(x2, y2)) translate(wall_locate3(dx2, dy2, back)) children(1);
    }
    bottom_hull() {
        multmatrix(place1(x1, y1)) translate(wall_locate2(dx1, dy1)) children(0);
        multmatrix(place1(x1, y1)) translate(wall_locate3(dx1, dy1, back)) children(0);
        multmatrix(place2(x2, y2)) translate(wall_locate2(dx2, dy2)) children(1);
        multmatrix(place2(x2, y2)) translate(wall_locate3(dx2, dy2, back)) children(1);
    }
}

module key_wall_brace(x1, y1, dx1, dy1, x2, y2, dx2, dy2, back=false) {
  place1 = function(column, row) key_placement_matrix(column, row);
  place2 = function(column, row) key_placement_matrix(column, row);
  wall_brace(place1, x1, y1, dx1, dy1, place2, x2, y2, dx2, dy2, back=back) {
    children(0);
    children(1);
  }
}

module back_wall() {
  x = 0;
  key_wall_brace(x, 0, 0, 1, x, 0, 0, 1, back=true) { web_post_tl(); web_post_tr(); }
  for (x = [1 : ncols - 2]) {
    key_wall_brace(x, 0, 0, 1, x, 0, 0, 1, back=true) { web_post_tl(); web_post_tr(); }
    key_wall_brace(x, 0, 0, 1, x - 1, 0, 0, 1, back=true) { web_post_tl(); web_post_tr(); }
  }
  key_wall_brace(lastcol, 0, 0, 1, lastcol, 0, 1, 0, back=true) { web_post_tr(); web_post_tr(); }
  key_wall_brace(lastcol, 0, 0, 1, lastcol, 0, 1, 0) { web_post_tr(); web_post_tr(); }
}

module right_wall() {
  y = 0;
  corner = reduced_outer_cols > 0 ? cornerrow : lastrow;
  key_wall_brace(lastcol, y, 1, 0, lastcol, y, 1, 0) { web_post_tr(); web_post_br(); }
  for (y = [1 : corner - 1]) {
    key_wall_brace(lastcol, y - 1, 1, 0, lastcol, y, 1, 0) { web_post_br(); web_post_tr(); }
    key_wall_brace(lastcol, y, 1, 0, lastcol, y, 1, 0) { web_post_tr(); web_post_br(); }
  }
  key_wall_brace(lastcol, corner, 0, -1, lastcol, corner, 1, 0) { web_post_br(); web_post_br(); }
}

module left_wall() {
  //FIXME:
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
    left_wall();
    right_wall();
    front_wall();
}

case_walls();