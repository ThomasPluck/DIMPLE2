#!/bin/bash

# Clean up previous log files and journals
rm -f *.log *.jou *.str
rm -rf vivado_project

# Set Vivado path - adjust this based on your installation
VIVADO_PATH="/tools/Xilinx/Vivado/2024.2/bin"
export PATH="$PATH:$VIVADO_PATH"

PROJECT_NAME="coupling_cell_impl"
PROJECT_DIR="./vivado_project"
PART="xc7a35tcpg236-1"

# Create TCL script
cat > run_implementation.tcl << EOL
create_project $PROJECT_NAME $PROJECT_DIR -part $PART -force

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
set_property STEPS.SYNTH_DESIGN.ARGS.NO_LC true [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.KEEP_EQUIVALENT_REGISTERS true [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.FSM_EXTRACTION off [get_runs synth_1]

# Set specific properties for the ring oscillator
set_property ALLOW_COMBINATORIAL_LOOPS TRUE [get_nets {async_count/inv_chain*}]
set_property SEVERITY Warning [get_drc_checks LUTLP-1]
set_property SEVERITY Warning [get_drc_checks NSTD-1]

# Run synthesis
launch_runs synth_1 -jobs 4
wait_on_run synth_1

# Run implementation
launch_runs impl_1 -jobs 4
wait_on_run impl_1

# Generate bitstream
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

# Generate reports
open_run impl_1
report_timing_summary -file timing_summary.rpt
report_utilization -file utilization.rpt
report_clock_networks -file clock_networks.rpt
report_high_fanout_nets -file fanout.rpt

# Generate detailed reports for the async circuit
report_timing -from [get_pins async_count/counter_reg[*]/C] -to [get_pins async_count/counter_reg[*]/D] -file async_timing.rpt
report_timing -through [get_nets async_count/inv_chain*] -file ring_osc_timing.rpt

close_project
EOL

# Make the script executable
chmod +x run_implementation.tcl

# Run Vivado in batch mode
vivado -mode batch -source run_implementation.tcl

# Optional: Organize reports into a directory
mkdir -p reports
mv *.rpt reports/

# Print completion message with basic status
if [ -f "vivado_project/${PROJECT_NAME}.runs/impl_1/${PROJECT_NAME}.bit" ]; then
    echo "Build completed successfully. Bitstream generated."
    echo "Reports can be found in the 'reports' directory."
else
    echo "Build failed. Check vivado.log for details."
fi