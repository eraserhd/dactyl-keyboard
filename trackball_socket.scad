module add_trackball_socket(position) {
  trackball_diameter = 34;
  bearing_diameter = 6;
  bearing_width = 2.5;
  trackball_clearance = 1;
  wall_thickness = 3;
  flange_height = 5;
  shaft_diameter = 3;
  shaft_length = 7.5;

  bearing_clearing_width = bearing_width + 1;
  bearing_housing_width = bearing_clearing_width + 2;
  bearing_housing_diameter = bearing_diameter + 4;
  shaft_housing_width = shaft_length + 2;
  shaft_housing_diameter = shaft_diameter + 4;

  bearing_z_offset = -6.5;

  socket_outside_diameter = 2*wall_thickness + 2*trackball_clearance + trackball_diameter;
  socket_inside_diameter = 2*trackball_clearance + trackball_diameter;

  module housing_part(diameter, width) {
    cylinder(d=diameter, h=width, center=true, $fn=25);
    translate([0, diameter/2, 0])
      cube([diameter, diameter, width], center=true);
    rotate([0, 0, 45])
      translate([0, diameter/2, 0])
        cube([diameter, diameter, width], center=true);
  }

  module bearing_housing() {
    rotate([0, 90, 0]) {
      housing_part(diameter=bearing_housing_diameter, width=bearing_housing_width);
      housing_part(diameter=shaft_housing_diameter, width=shaft_housing_width);
      }
  }

  module bearing_cutout() {
    rotate([0, 90, 0]) {
      cylinder(d=shaft_diameter, h=shaft_length, center=true, $fn=25);
      rotate([0, 0, 45])
        translate([0, socket_inside_diameter/8, 0])
          cube([shaft_diameter, socket_inside_diameter/4, shaft_length], center=true);
      housing_part(diameter=8.5, width=bearing_clearing_width);
    }
  }

  module trackball_cutout() {
    sphere(d=socket_inside_diameter);
    translate([0, 0, flange_height/2])
      cylinder(d=socket_inside_diameter, h=flange_height+0.01, center=true);
  }

  module trackball_housing() {
    difference() {
      sphere(d=socket_outside_diameter);
      translate([0,0,50]) cube([100,100,100],center=true);
    }
    translate([0, 0, flange_height/2])
      cylinder(d=socket_outside_diameter, h=flange_height, center=true);
  }
  
  module place_bearings() {
    bearing_distance_from_ball_center = bearing_diameter/2 + trackball_diameter/2;
    bearing_y_offset = -sqrt(pow(bearing_distance_from_ball_center, 2)+pow(bearing_z_offset, 2));
    bearing_offset = [0, bearing_y_offset, bearing_z_offset];
    
    translate(bearing_offset) children();
    rotate([0, 0, 120]) translate(bearing_offset) children();
    rotate([0, 0, 240]) translate(bearing_offset) children();
  }

  difference() {
    union() {
      children();
      translate(position) {
        trackball_housing();
        place_bearings() bearing_housing();
      }
    }
    translate(position) {
      trackball_cutout();
      place_bearings() bearing_cutout();
    }
  }
}

//FIXME: Sensor screws
//FIXME: Sensor cutout

add_trackball_socket([0,0,0])
    translate([0,0,1.5])
    color("teal")
    cube([50,50,3],center=true);
