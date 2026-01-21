// PCB Tray for 35mm x 7mm PCB
// Standard PCB thickness: 1.6mm
// Visualize via: https://ochafik.com/openscad2

// Design mode
is_wall_mounted = false;  // true for wall mount, false for pedestal
has_bottom_hole = false;  // true to include hole in bottom center
has_pedestal = false;  // true to include pedestal base
has_corner_mount = true;
show_lid = true;
show_pcb = false;


// Parameters
pcb_width = 22.3;
pcb_length = 16.9;
pcb_thickness = 1.6;

// Tray parameters
wall_thickness = 2;
base_thickness = 3;
wall_height = 4.75;  // Height of walls above PCB
floor_offset = 1;  // Distance floor is below base_thickness
clearance = 0.1;  // Clearance around PCB for easy fit
corner_radius = 5;  // Radius for rounded corners
inner_corner_radius = 2.5;  // Radius for inner rounded corners
cable_diameter = 5;  // Diameter for 20 gauge cable with insulation
pcb_height_from_bottom = 2.5;  // Height to hold PCB above bottom
corner_support_height = 3.75;  // Height of corner supports
corner_support_size = 2;  // Size of corner supports
ridge_height = 0.5;  // Height of front ridge
ridge_depth = 0.5;  // How far ridge extends into cavity
bottom_fillet_radius = 1;  // Radius for bottom edge fillet
thin_wall_thickness = 1;  // Thickness of top portion of walls
thin_wall_height = 2.5;  // Height of thin wall section at top
gap_behind_pin_headers = 1.5;

foot_width = 4;  // Left-right width after rotation
foot_depth = 8;  // How far back from front face after rotation
foot_height = wall_height + pcb_thickness + base_thickness - thin_wall_height;  // Height of feet
foot_spacing = 4.5;  // Distance from edge


// Calculated dimensions
inner_width = pcb_width + clearance * 2;
inner_length = pcb_length + gap_behind_pin_headers + clearance * 2;
outer_width = inner_width + wall_thickness * 2;
outer_length = inner_length + wall_thickness * 2;
total_height = base_thickness + pcb_thickness + wall_height;

// Module for rounded rectangle
module rounded_rect(width, length, height, radius) {
    hull() {
        translate([radius, radius, 0])
            cylinder(r=radius, h=height, $fn=150);
        translate([width-radius, radius, 0])
            cylinder(r=radius, h=height, $fn=150);
        translate([radius, length-radius, 0])
            cylinder(r=radius, h=height, $fn=150);
        translate([width-radius, length-radius, 0])
            cylinder(r=radius, h=height, $fn=150);
    }
}

// Rotate tray to stand upright
rotate([90, 0, 0]) {

if (show_pcb) {
    // Render a placeholder for the pcb
    translate([wall_thickness + clearance, 
            wall_thickness + clearance, 
            base_thickness - floor_offset + corner_support_height])
        rounded_rect(pcb_width, pcb_length, pcb_thickness, 2.5);
}

// Main tray
difference() {
    // Outer shell with rounded corners
    rounded_rect(outer_width, outer_length, total_height, corner_radius);
    
    // Inner cavity for PCB with rounded corners
    translate([wall_thickness, wall_thickness, base_thickness - floor_offset])
        rounded_rect(inner_width, inner_length, pcb_thickness + wall_height + 1 + floor_offset, inner_corner_radius);
    
    // Cable hole in front wall (centered, aligned with bottom surface)
    if (has_bottom_hole) {
        translate([outer_width/2, -0.5, base_thickness - floor_offset + cable_diameter/2 - 1])
            rotate([-90, 0, 0])
            cylinder(d=cable_diameter, h=wall_thickness + 1, $fn=64);
    }
    
    // Thin the top portion of walls by removing material from outside
    thin_start_z = total_height - thin_wall_height;
    wall_reduction = wall_thickness - thin_wall_thickness;
    // Remove outer ring of material at top
    difference() {
        translate([-1, -1, thin_start_z])
            cube([outer_width + 2, outer_length + 2, thin_wall_height + 1]);
        translate([wall_reduction, wall_reduction, thin_start_z - 1])
            rounded_rect(outer_width - 2*wall_reduction, outer_length - 2*wall_reduction, thin_wall_height + 2, corner_radius - wall_reduction);
    }
    
    // Floor cutout for cable from front to notch in rear wall
    if (has_bottom_hole) {
        translate([outer_width/2,
                   wall_thickness + inner_length - notch_depth,
                   base_thickness - floor_offset - 1 + cable_diameter/2])
            rotate([90, 0, 0])
            cylinder(d=cable_diameter, h=inner_length - notch_depth, $fn=64);
    }
    
    // Hole in center of bottom of tray
    translate([outer_width/2,
                outer_length/2,
                -0.5])
        cylinder(d=cable_diameter, h=base_thickness + 1, $fn=64);
}

// Notch extending inward from rear wall (3mm wide from center extending left, 1mm deep)
notch_width = 3;
notch_depth = gap_behind_pin_headers - clearance;
translate([outer_width/2 - notch_width,
           wall_thickness + inner_length - notch_depth,
           base_thickness - floor_offset])
    cube([notch_width, notch_depth, total_height - base_thickness + floor_offset]);

// PCB corner supports in front corners (inside)
// Left front corner
translate([wall_thickness, wall_thickness, base_thickness - floor_offset])
    cube([corner_support_size, corner_support_size, corner_support_height]);

// Right front corner
translate([wall_thickness + inner_width - corner_support_size, wall_thickness, base_thickness - floor_offset])
    cube([corner_support_size, corner_support_size, corner_support_height]);

// Left back corner
translate([wall_thickness, wall_thickness + pcb_length - corner_support_size, base_thickness - floor_offset])
    cube([corner_support_size, corner_support_size, corner_support_height]);

// Right back corner
translate([wall_thickness + inner_width - corner_support_size, wall_thickness + pcb_length - corner_support_size, base_thickness - floor_offset])
    cube([corner_support_size, corner_support_size, corner_support_height]);

// Side ridges to hold PCB in place
// Positioned above corner supports with space for PCB thickness + clearance
ridge_bottom_z = base_thickness - floor_offset + corner_support_height + pcb_thickness + clearance + 1;
ridge_length = 3;  // 3mm long ridges

// Position ridges starting at midpoint and extending toward back
ridge_position = (inner_length - 1) / 2;

// Left side ridge (from midpoint to back)
translate([wall_thickness, wall_thickness + ridge_position, ridge_bottom_z])
    cube([ridge_depth, ridge_length, ridge_height]);

// Right side ridge (from midpoint to back)
translate([wall_thickness + inner_width - ridge_depth, wall_thickness + ridge_position, ridge_bottom_z])
    cube([ridge_depth, ridge_length, ridge_height]);

// Front ridge (centered, 3mm wide)
front_ridge_width = 3;
translate([wall_thickness + (inner_width - front_ridge_width) / 2, wall_thickness, ridge_bottom_z])
    cube([front_ridge_width, ridge_depth, ridge_height]);

// Pedestal feet (only for non-wall-mounted version)
if (!is_wall_mounted) {
    
    // Left foot (attached to front face which becomes bottom after rotation)
    translate([foot_spacing, -foot_depth, 0])
        cube([foot_width, foot_depth, foot_height]);
    
    // Right foot (attached to front face which becomes bottom after rotation)
    translate([outer_width - foot_spacing - foot_width, -foot_depth, 0])
        cube([foot_width, foot_depth, foot_height]);
}

// Lid
if (show_lid) {
    lid_thickness = thin_wall_thickness;  // Thickness of lid walls
    lid_top_thickness = 1.5;  // Thickness of lid top
    lid_height = thin_wall_height + lid_top_thickness;  // How tall the lid walls are
    
    // Calculate thin wall outer dimensions
    wall_reduction = wall_thickness - thin_wall_thickness;
    thin_wall_outer_width = outer_width - 2 * wall_reduction;
    thin_wall_outer_length = outer_length - 2 * wall_reduction;
    thin_wall_corner_radius = corner_radius - wall_reduction;
    
    // Clearance for lid to fit over thin walls
    lid_clearance = 0.0;
    
    // Position lid above tray
    translate([0, 0, total_height + 10]) {
        difference() {
            // Outer shell
            rounded_rect(outer_width, outer_length, lid_height, corner_radius);
            
            // Inner cavity to fit over thin walls
            translate([thin_wall_thickness, 
                       thin_wall_thickness, 
                       -0.1])
                rounded_rect(outer_width - 2 * thin_wall_thickness + lid_clearance, 
                            outer_length - 2 * thin_wall_thickness + lid_clearance, 
                           lid_height - lid_top_thickness + clearance, 
                           thin_wall_corner_radius);
        }
    }
}

} // End rotate


if (has_pedestal) {
    // Pyramid pedestal base (20mm below the tray)
    base_size = 25;
    base_height = 4.5;
    base_thickness = 2;  // Thickness of base plate
    base_offset = 20;  // Distance below tray
    
    translate([outer_width/2 - base_size/2, -base_offset + 0.5*foot_height, -base_offset]) {
        difference() {
            union() {
                // Base plate
                translate([0, 0, 0])
                    cube([base_size, base_size, base_thickness]);
                
                // Pyramid on top of base
                translate([0, 0, base_thickness]) {
                    // Calculate flat top dimensions based on inside edges of foot slots
                    flat_top_width = outer_width - 2*foot_spacing - 2*foot_width - foot_clearance;
                    flat_top_depth = foot_depth + foot_clearance;
                    flat_top_x_offset = foot_spacing - (outer_width/2 - base_size/2) + foot_width + foot_clearance;
                    flat_top_y_offset = base_size/2 - flat_top_depth/2;
                    
                    hull() {
                        // Bottom square
                        translate([0, 0, 0])
                            cube([base_size, base_size, 0.1]);
                        // Flat top (rectangle instead of point)
                        translate([flat_top_x_offset, flat_top_y_offset, base_height])
                            cube([flat_top_width, flat_top_depth, 0.1]);
                    }
                }
            }
            
            // Cutouts for feet (not through base)
            foot_clearance = 0.0;  // Extra clearance for easy fit
            
            // Left foot cutout (centered in pyramid Y direction)
            translate([foot_spacing - (outer_width/2 - base_size/2), 
                       base_size/2 - (foot_height + foot_clearance)/2, 
                       base_thickness - 0.1])
                cube([foot_width + foot_clearance, 
                      foot_height + foot_clearance, 
                      base_height + 1]);
            
            // Right foot cutout (centered in pyramid Y direction)
            translate([outer_width - foot_spacing - foot_width - (outer_width/2 - base_size/2), 
                       base_size/2 - (foot_height + foot_clearance)/2, 
                       base_thickness - 0.1])
                cube([foot_width + foot_clearance, 
                      foot_height + foot_clearance, 
                      base_height + 1]);
        }
    }
}

if (has_corner_mount) {
    // Rectangular corner mount base
    base_width = 25;
    base_depth = 15;
    base_thickness = 4;
    floor_thickness = 2;
    base_offset = 20;  // Distance below tray
    wedge_height = base_width/2;  // Height for 90-degree tip angle
    corner_radius_mount = 2;  // Radius for front corners
    
    translate([outer_width/2 - base_width/2, -base_offset + 0.5*foot_height + 5, -50]) {
        difference() {
            union() {
                // Base plate with rounded front corners
                hull() {
                    // Front left corner
                    translate([corner_radius_mount, corner_radius_mount, -floor_thickness])
                        cylinder(r=corner_radius_mount, h=base_thickness + floor_thickness, $fn=32);
                    // Front right corner
                    translate([base_width - corner_radius_mount, corner_radius_mount, -floor_thickness])
                        cylinder(r=corner_radius_mount, h=base_thickness + floor_thickness, $fn=32);
                    // Rear section (full width)
                    translate([0, base_depth, -floor_thickness])
                        cube([base_width, 0.1, base_thickness + floor_thickness]);
                }
                
                // Triangular wedge extending from rear face
                translate([0, base_depth, -floor_thickness])
                    linear_extrude(height=base_thickness + floor_thickness)
                        polygon(points=[
                            [0, 0],
                            [base_width, 0],
                            [base_width/2, wedge_height]
                        ]);
                
                // Walls along triangle edges (20mm high, 2mm thick)
                wall_height = 15;
                wall_thickness = 2;
                reinforcement_height = 2;  // First 2mm of walls are thicker
                reinforcement_thickness = 2;  // Extra thickness for reinforcement
                wall_taper = 4;  // Top is 4mm shorter than bottom
                translate([0, base_depth, base_thickness]) {
                    // Left angled wall (offset inward so outer face is flush)
                    translate([wall_thickness / sqrt(2) + 4 / sqrt(2), -wall_thickness / sqrt(2) + 4 / sqrt(2), 0])
                        rotate([0, 0, 45]) {
                            hull() {
                                // Bottom
                                cube([sqrt(2) * wedge_height - 4, wall_thickness, 0.1]);
                                // Top (4mm shorter, starting 4mm further back)
                                translate([wall_taper, 0, wall_height])
                                    cube([sqrt(2) * wedge_height - 4 - wall_taper, wall_thickness, 0.1]);
                            }
                            // Inner reinforcement for first 2mm (also tapered)
                            translate([0, -reinforcement_thickness, 0])
                                hull() {
                                    // Bottom
                                    cube([sqrt(2) * wedge_height - 4, reinforcement_thickness, 0.1]);
                                    // Top at reinforcement_height (proportionally tapered)
                                    translate([wall_taper * reinforcement_height / wall_height, 0, reinforcement_height])
                                        cube([sqrt(2) * wedge_height - 4 - wall_taper * reinforcement_height / wall_height, reinforcement_thickness, 0.1]);
                                }
                        }
                    
                    // Right angled wall
                    translate([base_width - 4 / sqrt(2), 4 / sqrt(2), 0])
                        rotate([0, 0, 135]) {
                            hull() {
                                // Bottom
                                cube([sqrt(2) * wedge_height - 4, wall_thickness, 0.1]);
                                // Top (4mm shorter, starting 4mm further back)
                                translate([wall_taper, 0, wall_height])
                                    cube([sqrt(2) * wedge_height - 4 - wall_taper, wall_thickness, 0.1]);
                            }
                            // Inner reinforcement for first 2mm (also tapered)
                            translate([0, wall_thickness, 0])
                                hull() {
                                    // Bottom
                                    cube([sqrt(2) * wedge_height - 4, reinforcement_thickness, 0.1]);
                                    // Top at reinforcement_height (proportionally tapered)
                                    translate([wall_taper * reinforcement_height / wall_height, 0, reinforcement_height])
                                        cube([sqrt(2) * wedge_height - 4 - wall_taper * reinforcement_height / wall_height, reinforcement_thickness, 0.1]);
                                }
                        }
                    
                    // Corner reinforcement (2mm x 2mm vertical piece inside the angle)
                    translate([base_width/2, wedge_height - 4, 0])
                        rotate([0, 0, 45])
                        translate([-1, -1, 0])
                        cube([2, 2, wall_height + 0.1]);
                }
            }
            
            // Cutouts for feet
            foot_clearance = 0.1;
            
            // Left foot cutout
            translate([foot_spacing - (outer_width/2 - base_width/2), 
                       base_depth/2 - (foot_height + foot_clearance)/2, 
                       -0.1])
                cube([foot_width + foot_clearance, 
                      foot_height + foot_clearance, 
                      base_thickness + 1]);
            
            // Right foot cutout
            translate([outer_width - foot_spacing - foot_width - (outer_width/2 - base_width/2), 
                       base_depth/2 - (foot_height + foot_clearance)/2, 
                       -0.1])
                cube([foot_width + foot_clearance, 
                      foot_height + foot_clearance, 
                      base_thickness + 1]);
        }
    }
}