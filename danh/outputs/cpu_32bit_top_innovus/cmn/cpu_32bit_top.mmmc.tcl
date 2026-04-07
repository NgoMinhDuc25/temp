#################################################################################
#
# Created by Genus(TM) Synthesis Solution 22.12-s082_1 on Tue Apr 07 17:14:22 +07 2026
#
#################################################################################

## library_sets
create_library_set -name ls_of_ld_slow \
    -timing { /home/DANHPD2/pd_fresher_course/libraries/lib/max/slow.lib \
              /home/DANHPD2/pd_fresher_course/libraries/lib/max/pdkIO.lib }
create_library_set -name ls_of_ld_fast \
    -timing { /home/DANHPD2/pd_fresher_course/libraries/lib/min/fast.lib \
              /home/DANHPD2/pd_fresher_course/libraries/lib/min/pdkIO.lib }

## rc_corner
create_rc_corner -name default_emulate_rc_corner \
    -T 125.0 \
    -qx_tech_file /home/DANHPD2/pd_fresher_course/libraries/tech/qrc/qx/gpdk045.tch \
    -preRoute_res 1.0 \
    -preRoute_cap 1.0 \
    -preRoute_clkres 0.0 \
    -preRoute_clkcap 0.0 \
    -postRoute_res {1.0 1.0 1.0} \
    -postRoute_cap {1.0 1.0 1.0} \
    -postRoute_xcap {1.0 1.0 1.0} \
    -postRoute_clkres {1.0 1.0 1.0} \
    -postRoute_clkcap {1.0 1.0 1.0} \
    -postRoute_clkxcap {1.0 1.0 1.0}

## delay_corner
create_delay_corner -name default_emulate_delay_corner \
    -early_library_set { ls_of_ld_slow } \
    -late_library_set { ls_of_ld_slow } \
    -early_rc_corner default_emulate_rc_corner \
    -late_rc_corner default_emulate_rc_corner
create_delay_corner -name default_emulate_power_delay_corner \
    -early_library_set { ls_of_ld_fast } \
    -late_library_set { ls_of_ld_fast } \
    -early_rc_corner default_emulate_rc_corner \
    -late_rc_corner default_emulate_rc_corner

## constraint_mode
create_constraint_mode -name default_emulate_constraint_mode \
    -sdc_files { outputs/cpu_32bit_top_innovus/cmn/cpu_32bit_top.mmmc/modes/default_emulate_constraint_mode/default_emulate_constraint_mode.sdc.gz }

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
