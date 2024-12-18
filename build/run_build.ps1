# Clean up previous log files and journals
Remove-Item -Path "*.log" -ErrorAction SilentlyContinue
Remove-Item -Path "*.jou" -ErrorAction SilentlyContinue
Remove-Item -Path "*.str" -ErrorAction SilentlyContinue
Remove-Item -Path "vivado_project" -Recurse -ErrorAction SilentlyContinue

$VivadoPath = "C:\Xilinx\Vivado\2024.2\bin"
$env:Path += ";$VivadoPath"

$ProjectName = "coupling_cell_impl"
$ProjectDir = "./vivado_project"
$Part = "xc7a35tcpg236-1" # Basys3 part number

$TclCommands = @"
create_project $ProjectName $ProjectDir -part $Part -force

# Create the ILA IP core
create_ip -name ila -vendor xilinx.com -library ip -version 6.2 -module_name ila_0
set_property -dict [list \
    CONFIG.ALL_PROBE_SAME_MU_CNT {2} \
    CONFIG.ALL_PROBE_SAME_MU {true} \
    CONFIG.C_ADV_TRIGGER {true} \
    CONFIG.C_DATA_DEPTH {1024} \
    CONFIG.C_ENABLE_ILA_AXI_MON {false} \
    CONFIG.C_EN_STRG_QUAL {1} \
    CONFIG.C_INPUT_PIPE_STAGES {0} \
    CONFIG.C_MONITOR_TYPE {Native} \
    CONFIG.C_NUM_OF_PROBES {6} \
    CONFIG.C_PROBE0_WIDTH {1} \
    CONFIG.C_PROBE1_WIDTH {1} \
    CONFIG.C_PROBE2_WIDTH {12} \
    CONFIG.C_PROBE3_WIDTH {1} \
    CONFIG.C_PROBE4_WIDTH {1} \
    CONFIG.C_PROBE5_WIDTH {1} \
    CONFIG.C_TRIGIN_EN {false} \
    CONFIG.C_TRIGOUT_EN {false}] [get_ips ila_0]
generate_target all [get_ips ila_0]

# Add design files
add_files {
    ../rtl/coupling_cell.v
    ../rtl/top.v
}

# Add constraints file
add_files -fileset constrs_1 {
    ../constraints/constraints.xdc
}

# Set top module for synthesis
set_property top top [current_fileset]

# Set synthesis settings for async design
set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY none [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.RETIMING false [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.NO_LC true [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.KEEP_EQUIVALENT_REGISTERS true [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.FSM_EXTRACTION off [get_runs synth_1]

# Run synthesis
launch_runs synth_1 -jobs 4
wait_on_run synth_1

if { [get_property PROGRESS [get_runs synth_1]] != "100%" } {
    error "Synthesis failed"
}

# Run implementation
launch_runs impl_1 -jobs 4
wait_on_run impl_1

if { [get_property PROGRESS [get_runs impl_1]] != "100%" } {
    error "Implementation failed"
}

# Generate bitstream
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

# Generate reports
open_run impl_1
report_timing_summary -file timing_summary.rpt
report_utilization -file utilization.rpt
report_clock_networks -file clock_networks.rpt

close_design
close_project
"@

$TclCommands | Out-File -FilePath "run_implementation.tcl" -Encoding ASCII
vivado -mode batch -source run_implementation.tcl