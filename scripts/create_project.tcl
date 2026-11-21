# Run from the Vivado Tcl Console or from Vivado in batch mode.
set chron_root [file normalize [file join [file dirname [info script]] ..]]
set chron_rtl [file join $chron_root rtl]
set chron_build [file join $chron_root build]
set chron_xpr [file join $chron_build chronomatron.xpr]

if {[llength [get_projects -quiet]] != 0} {
    error "Close the current Vivado project before loading Chronomatron."
}
if {[file exists $chron_xpr]} {
    open_project $chron_xpr
} else {
    create_project chronomatron $chron_build -part xc7a100tcsg324-1
    set_property target_language Verilog [current_project]
    set_property simulator_language Mixed [current_project]

    add_files -norecurse [lsort [glob [file join $chron_rtl *.v]]]
    set chron_header [file join $chron_rtl game_states.vh]
    add_files -norecurse $chron_header
    set_property file_type {Verilog Header} [get_files $chron_header]
    set_property include_dirs [list $chron_rtl] [get_filesets sources_1]
    set_property top chronomatron_top [get_filesets sources_1]
    add_files -fileset constrs_1 -norecurse [file join $chron_root constraints nexys_a7_100t.xdc]

    add_files -fileset sim_1 -norecurse [lsort [glob [file join $chron_root sim *.sv]]]
    set_property include_dirs [list $chron_rtl] [get_filesets sim_1]
    set_property top tb_chronomatron [get_filesets sim_1]
    set_property xsim.simulate.runtime 0ns [get_filesets sim_1]

    update_compile_order -fileset sources_1
    update_compile_order -fileset sim_1
}
