# vivado -mode batch -source scripts/build.tcl
source [file join [file dirname [info script]] create_project.tcl]
reset_run synth_1
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
if {![string match "*write_bitstream Complete*" [get_property STATUS [get_runs impl_1]]]} {
    error "Vivado did not produce a bitstream. See the implementation log."
}

open_run impl_1
set report_dir [file join $chron_build reports]
file mkdir $report_dir
report_timing_summary -file [file join $report_dir timing_summary.rpt]
report_utilization -file [file join $report_dir utilization.rpt]
foreach delay_type {max min} {
    set worst_path [get_timing_paths -delay_type $delay_type -max_paths 1]
    if {[llength $worst_path] == 0 || [get_property SLACK [lindex $worst_path 0]] < 0} {
        error "Timing checks did not pass. See build/reports/timing_summary.rpt."
    }
}
puts "Bitstream: [file join $chron_build chronomatron.runs impl_1 chronomatron_top.bit]"
