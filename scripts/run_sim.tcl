# vivado -mode batch -source scripts/run_sim.tcl
source [file join [file dirname [info script]] create_project.tcl]
foreach testbench {tb_chronomatron tb_video} {
    set_property top $testbench [get_filesets sim_1]
    update_compile_order -fileset sim_1
    launch_simulation
    run all
    close_sim
}
set_property top tb_chronomatron [get_filesets sim_1]
