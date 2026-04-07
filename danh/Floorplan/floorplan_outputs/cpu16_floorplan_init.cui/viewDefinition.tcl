if {![namespace exists ::IMEX]} { namespace eval ::IMEX {} }
set ::IMEX::dataVar [file dirname [file normalize [info script]]]
set ::IMEX::libVar ${::IMEX::dataVar}/libs

create_library_set -name ls_of_ld_fast\
   -timing\
    [list ${::IMEX::libVar}/mmmc/fast.lib\
    ${::IMEX::libVar}/mmmc/pdkIO.lib]
create_library_set -name ls_of_ld_slow\
   -timing\
    [list ${::IMEX::libVar}/mmmc/slow.lib\
    ${::IMEX::libVar}/mmmc/pdkIO.lib]
create_timing_condition -name cond_timing\
   -library_sets [list ls_of_ld_slow]
create_rc_corner -name my_rc_corner\
   -pre_route_res 1\
   -post_route_res 1\
   -pre_route_cap 1\
   -post_route_cap 1\
   -post_route_cross_cap 1\
   -pre_route_clock_res 0\
   -pre_route_clock_cap 0\
   -temperature 25\
   -qrc_tech ${::IMEX::libVar}/mmmc/my_rc_corner/qrcTechFile
create_rc_corner -name default_emulate_rc_corner\
   -pre_route_res 1\
   -post_route_res {1 1 1}\
   -pre_route_cap 1\
   -post_route_cap {1 1 1}\
   -post_route_cross_cap {1 1 1}\
   -pre_route_clock_res 0\
   -pre_route_clock_cap 0\
   -post_route_clock_cap {1 1 1}\
   -post_route_clock_res {1 1 1}\
   -temperature 125\
   -qrc_tech ${::IMEX::libVar}/mmmc/default_emulate_rc_corner/gpdk045.tch
create_delay_corner -name default_emulate_delay_corner\
   -early_timing_condition {cond_timing}\
   -late_timing_condition {cond_timing}\
   -rc_corner default_emulate_rc_corner
create_delay_corner -name default_emulate_power_delay_corner\
   -early_timing_condition {cond_timing}\
   -late_timing_condition {cond_timing}\
   -rc_corner default_emulate_rc_corner
create_constraint_mode -name default_emulate_constraint_mode\
   -sdc_files\
    [list ${::IMEX::libVar}/mmmc/default_emulate_constraint_mode.sdc.gz]
create_analysis_view -name default_emulate_power_view -constraint_mode default_emulate_constraint_mode -delay_corner default_emulate_power_delay_corner
create_analysis_view -name default_emulate_view -constraint_mode default_emulate_constraint_mode -delay_corner default_emulate_delay_corner
set_analysis_view -setup [list default_emulate_view] -hold [list default_emulate_view] -leakage default_emulate_power_view -dynamic default_emulate_power_view
