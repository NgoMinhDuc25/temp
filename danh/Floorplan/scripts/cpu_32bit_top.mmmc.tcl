#################################################################################
#
# Created by Genus(TM) Synthesis Solution 22.12-s082_1 on Mon Apr 06 10:16:47 +07 2026
#
#################################################################################

## library_sets
create_library_set -name ls_of_ld_slow \
    -timing { /home/DANHPD2/pd_fresher_course/libraries/lib/max/slow.lib \
              /home/DANHPD2/pd_fresher_course/libraries/lib/max/pdkIO.lib }
create_library_set -name ls_of_ld_fast \
    -timing { /home/DANHPD2/pd_fresher_course/libraries/lib/min/fast.lib \
              /home/DANHPD2/pd_fresher_course/libraries/lib/min/pdkIO.lib }

create_timing_condition -name cond_timing -library_sets { ls_of_ld_slow }
## rc_corner
create_rc_corner -name default_emulate_rc_corner \
    -T 125.0 \
    -qrc_tech /home/DANHPD2/pd_fresher_course/libraries/tech/qrc/qx/gpdk045.tch \
    -pre_route_res 1.0 \
    -pre_route_cap 1.0 \
    -pre_route_clock_res 0.0 \
    -pre_route_clock_cap 0.0 \
    -post_route_res {1.0 1.0 1.0} \
    -post_route_cap {1.0 1.0 1.0} \
    -post_route_cross_cap {1.0 1.0 1.0} \
    -post_route_clock_res {1.0 1.0 1.0} \
    -post_route_clock_cap {1.0 1.0 1.0}

## delay_corner
create_delay_corner -name default_emulate_delay_corner \
    -early_timing_condition { cond_timing } \
    -late_timing_condition { cond_timing } \
    -early_rc_corner default_emulate_rc_corner \
    -late_rc_corner default_emulate_rc_corner
create_delay_corner -name default_emulate_power_delay_corner \
    -early_timing_condition { cond_timing } \
    -late_timing_condition { cond_timing } \
    -early_rc_corner default_emulate_rc_corner \
    -late_rc_corner default_emulate_rc_corner

## constraint_mode
create_constraint_mode -name default_emulate_constraint_mode \
    -sdc_files { ../outputs/cpu_32bit_top_innovus/cmn/cpu_32bit_top.mmmc/modes/default_emulate_constraint_mode/default_emulate_constraint_mode.sdc.gz }

## analysis_view
create_analysis_view -name default_emulate_view \
    -constraint_mode default_emulate_constraint_mode \
    -delay_corner default_emulate_delay_corner
create_analysis_view -name default_emulate_power_view \
    -constraint_mode default_emulate_constraint_mode \
    -delay_corner default_emulate_power_delay_corner

## set_analysis_view
set_analysis_view -setup { default_emulate_view } \
                  -hold { default_emulate_view } \
                  -leakage default_emulate_power_view \
                  -dynamic default_emulate_power_view

## latency
