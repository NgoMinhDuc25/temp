#======================================================================
# floor_plan.tcl
#======================================================================

#-------------------------
# 1) Multi-CPU
#-------------------------
set NCPU 4

set_multi_cpu_usage -local_cpu $NCPU

#-------------------------
# 2) Output directory
#-------------------------
set DBS "./floorplan_outputs"
if {![file exists $DBS]} {
    file mkdir $DBS
        puts "INFO: Creating directory $DBS"
}
#-------------------------
# 3) LEF setup (tech + stdcell + memory + IO)
#-------------------------
set LEFS [list \
        ../../libraries/tech/lef/gsclib045_tech.lef \
        ../../libraries/lef/gsclib045.fixed.lef \
        ../../libraries/lef/pdkIO.lef \
]

read_physical -lef $LEFS
#-------------------------
# 4) Netlist / top-cell setup
#-------------------------

set NETLIST ../outputs/cpu_32bit_top.vg
set TOPCELL cpu_32bit_top

#-------------------------
# 5) MMMC setup
#-------------------------

create_rc_corner -name my_rc_corner \
    -qrc_tech ../../libraries/tech/qrc/qx/qrcTechFile \
    -temperature 25

    read_mmmc scripts/cpu_32bit_top.mmmc.tcl
    read_netlist $NETLIST -top $TOPCELL

#-------------------------
# 6) Initialize design
#-------------------------
init_design

#======================================================================
# 7) FLOORPLAN (Part A): IO-driven fixed-dimension die/core sizing
#
# Design: cpu_32bit_top
# - 78 signal IO ports (3 ctrl + 16 din + 16 dout + 2 status)
# - Pad rule: per side insert 2 power pads (VDD and VSS)
#   Sequence example: p1 p2 p3 VDD  p4 p5 p6 VSS  p7 p8 p9 ...
#
# IO LEF dimensions (pdkIO.lef):
# - IO pad cell SIZE 40 x 250  -> pitch along edge = 40, IO ring thickness = 250
# - Corner cell   SIZE 250 x 250
#
# Pad distribution used for sizing (signals only):
#   Top=20, Bottom=20, Left=19, Right=19  (total 78)
# Add per-side PG pads (VDD+VSS):
#   Npads_top   = 10 + 2 = 12
#   Npads_bot   =  9 + 2 = 11
#   Npads_left  =  9 + 2 = 11
#   Npads_right =  9 + 2 = 11
#
# Die sizing (min):
#   dieW = corner(250) + max(Npads_top,Npads_bot)*pitch(40) + corner(250)
#        = 250 + max(20,20)*40 + 250 = 1300
#   dieH = corner(250) + max(Npads_left,Npads_right)*pitch(40) + corner(250)
#        = 250 + max(19,19)*40 + 250 = 1260
#
# Margin intent:
#   IO ring thickness 250 + clearance 50 => die->core margin = 300
#   => L=B=R=T = 300 measured from DIE edge to CORE edge
#
# IMPORTANT (Innovus behavior):
# - Use "die" interpretation so 300 means DIE->CORE margin.
#
# Commands:
#   Stylus : create_floorplan -site CoreSite -core_margins_by die -die_size 980 940 300 300 300 300
#======================================================================
set DIE_W 1300
set DIE_H 1260
set MARG 468.5

set_db floorplan_snap_constraint_grid manufacturing
set_db floorplan_snap_place_blockage_grid manufacturing
set_db floorplan_snap_die_grid manufacturing
set_db floorplan_snap_core_grid manufacturing

create_floorplan -site CoreSite -core_margins_by die -die_size $DIE_W $DIE_H $MARG $MARG $MARG $MARG -no_snap_to_grid
gui_set_draw_view fplan 
gui_fit 
get_db current_design .core_bbox

#-------------------------
# Move all IO cells to it's original location 0,0
#-------------------------
set my_ios [get_db [get_db hinsts cpu_16bit_top/U_IO] .local_insts]
set_db $my_ios .location {0 0}
gui_redraw

#-------------------------
# 8) Create Pg Net, Pin
#-------------------------

create_net -power -name VDD
create_net -ground -name VSS
create_pg_pin -name VDD -net VDD -dir inout
create_pg_pin -name VSS -net VSS -dir inout

# ------------------------------------------------------------
# 9) Define power/ground nets
# ------------------------------------------------------------
set_db init_power_nets VDD
set_db init_ground_nets VSS


#------------------------------------------------------------
# 10) Global net connection rules (VDD/VSS)
# ------------------------------------------------------------
# 10.1) Bind pg pins (all instances) to VDD/VSS
connect_global_net VDD \
  -type pg_pin \
  -pin_base_name VDD \
  -inst * \
  -netlist_override -override

connect_global_net VSS \
  -type pg_pin \
  -pin_base_name VSS \
  -inst * \
  -netlist_override -override
               
# 10.2) Verbose connect 

connect_global_net VDD -type pg_pin -pin_base_name VDD -inst_base_name * -override -verbose
connect_global_net VSS -type pg_pin -pin_base_name VSS -inst_base_name * -override -verbose

# 10.3) Commit rules
commit_global_net_rules

#------------------------------------------------------------
# 11) Ring setup (set_db add_rings_*)
# ------------------------------------------------------------
##Ring
set_db add_rings_target default
set_db add_rings_extend_over_row 0
set_db add_rings_ignore_rows 0
set_db add_rings_avoid_short 0
set_db add_rings_skip_shared_inner_ring none
set_db add_rings_stacked_via_top_layer Metal11
set_db add_rings_stacked_via_bottom_layer Metal1
set_db add_rings_via_using_exact_crossover_size 1
set_db add_rings_orthogonal_only true
set_db add_rings_skip_via_on_pin {  standardcell }
set_db add_rings_skip_via_on_wire_shape {  noshape }

# ------------------------------------------------------------
# 12) Create core ring (Metal11 horizontal / Metal10 vertical)
# ------------------------------------------------------------
#### W:10 Spacing:4 Offset:8
add_rings \
    	-nets {VDD VSS} \
    	-type core_rings \
    	-follow core \
    	-layer {top Metal11 bottom Metal11 left Metal10 right Metal10} \
    	-width {top 10 bottom 10 left 10 right 10} \
    	-spacing {top 4 bottom 4 left 4 right 4} \
	-offset {top 8 bottom 8 left 8 right 8} \
    	-center 0 \
        -threshold 0 \
        -jog_distance 0 \
        -snap_wire_center_to_grid none

# ------------------------------------------------------------
# 13) Stripe defaults (set_db add_stripes_*)
# ------------------------------------------------------------
###Power
set_db add_stripes_ignore_block_check false
set_db add_stripes_break_at none
set_db add_stripes_route_over_rows_only false
set_db add_stripes_rows_without_stripes_only false
set_db add_stripes_extend_to_closest_target none
set_db add_stripes_stop_at_last_wire_for_area false
set_db add_stripes_partial_set_through_domain false
set_db add_stripes_ignore_non_default_domains false
set_db add_stripes_trim_antenna_back_to_shape none
set_db add_stripes_spacing_type edge_to_edge
set_db add_stripes_spacing_from_block 0
set_db add_stripes_stripe_min_length stripe_width
set_db add_stripes_stacked_via_top_layer Metal11
set_db add_stripes_stacked_via_bottom_layer Metal1
set_db add_stripes_via_using_exact_crossover_size false
set_db add_stripes_split_vias false
set_db add_stripes_orthogonal_only true
set_db add_stripes_allow_jog { padcore_ring  block_ring }
set_db add_stripes_skip_via_on_pin {  standardcell }
set_db add_stripes_skip_via_on_wire_shape {  noshape   }

#------------------------------------------------------------
# 14) Add stripes (Vertical M10, Horizontal M11)
# ------------------------------------------------------------
# 14.1) Vertical stripes (Metal10)
###Vertical M10 W:5_Spacing:2_Distance:40
add_stripes \
     -nets {VDD VSS} \
     -layer Metal10 \
     -direction vertical \
     -width 5 \
     -spacing 2 \
     -set_to_set_distance 40 \
     -start_from left \
     -start_offset 0 \
     -stop_offset 0 \
     -switch_layer_over_obs false \
     -max_same_layer_jog_length 2 \
     -pad_core_ring_top_layer_limit Metal11 \
     -pad_core_ring_bottom_layer_limit Metal1 \
     -block_ring_top_layer_limit Metal11 \
     -block_ring_bottom_layer_limit Metal1 \
     -use_wire_group 0 \
     -snap_wire_center_to_grid none

# 14.2) Horizontal stripes (Metal11)
###Horizontal M11 W:5_Spacing:2_Distance:40
add_stripes \
     -nets {VDD VSS} \
     -layer Metal11 \
     -direction horizontal \
     -width 5 \
     -spacing 3 \
     -set_to_set_distance 40 \
     -start_from bottom \
     -start_offset 0 \
     -stop_offset 0 \
     -switch_layer_over_obs false \
     -max_same_layer_jog_length 2 \
     -pad_core_ring_top_layer_limit Metal11 \
     -pad_core_ring_bottom_layer_limit Metal1 \
     -block_ring_top_layer_limit Metal11 \
     -block_ring_bottom_layer_limit Metal1 \
     -use_wire_group 0 \
     -snap_wire_center_to_grid none

# ------------------------------------------------------------
# 15) Special route settings and routing
# ------------------------------------------------------------
# 15.1) Special-route viaiggsi siv connect shape (noshape)

set_db route_special_via_connect_to_shape { noshape }

# 15.2) Connect pad pins
route_special \
     -connect {pad_pin} \
     -layer_change_range { Metal1(1) Metal11(11) } \
     -block_pin_target {nearest_target} \
     -pad_pin_port_connect {all_port one_geom} \
     -pad_pin_target {ring stripe} \
     -allow_jogging 1 \
     -crossover_via_layer_range { Metal1(1) Metal11(11) } \
     -nets { VSS VDD } \
     -allow_layer_change 1 \
     -target_via_layer_range { Metal1(1) Metal11(11) }

# 15.3) Connect floating stripes
route_special \
        -connect {floating_stripe} \
        -layer_change_range { Metal1(1) Metal11(11) } \
        -block_pin_target {nearest_target} \
        -floating_stripe_target {block_ring pad_ring ring stripe ring_pin block_pin followpin} \
        -allow_jogging 1 \
        -crossover_via_layer_range { Metal1(1) Metal11(11) } \
        -nets { VDD VSS } \
        -allow_layer_change 1 \
        -target_via_layer_range { Metal1(1) Metal11(11) }

# 15.4) Special-route via connect shape (ring/stripe)
set_db route_special_via_connect_to_shape { ring stripe }

# 15.5) Connect block/core pins
route_special \
  -connect {block_pin core_pin} \
  -layer_change_range { Metal1(1) Metal11(11) } \
  -block_pin_target {nearest_target} \
  -core_pin_target {first_after_row_end} \
  -floating_stripe_target {block_ring pad_ring ring stripe ring_pin block_pin followpin} \
  -allow_jogging 1 \
  -crossover_via_layer_range { Metal1(1) Metal11(11) } \
  -nets { VDD VSS } \
  -allow_layer_change 1 \
  -block_pin use_lef \
  -target_via_layer_range { Metal1(1) Metal11(11) }

# ------------------------------------------------------------
# 16) Verify connectivity
# ------------------------------------------------------------
check_connectivity -type special -nets {VDD VSS}

#-------------------------
# 17) Save floorplan checkpoint (portable: Stylus + Legacy)
#-------------------------
set SESSION_BASE "$DBS/cpu16_floorplan_init"
set SESSION_DB "${SESSION_BASE}.cui"
write_db $SESSION_DB

