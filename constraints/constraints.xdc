## Clock signal (100 MHz)
set_property -dict { PACKAGE_PIN W5   IOSTANDARD LVCMOS33 } [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

## Center Button
set_property -dict { PACKAGE_PIN U18  IOSTANDARD LVCMOS33 } [get_ports btnC]

## Switches
set_property -dict { PACKAGE_PIN V17  IOSTANDARD LVCMOS33 } [get_ports {sw[0]}]
set_property -dict { PACKAGE_PIN V16  IOSTANDARD LVCMOS33 } [get_ports {sw[1]}]
set_property -dict { PACKAGE_PIN W16  IOSTANDARD LVCMOS33 } [get_ports {sw[2]}]
set_property -dict { PACKAGE_PIN W17  IOSTANDARD LVCMOS33 } [get_ports {sw[3]}]

## LEDs
set_property -dict { PACKAGE_PIN U16  IOSTANDARD LVCMOS33 } [get_ports {led[0]}]
set_property -dict { PACKAGE_PIN E19  IOSTANDARD LVCMOS33 } [get_ports {led[1]}]
set_property -dict { PACKAGE_PIN U19  IOSTANDARD LVCMOS33 } [get_ports {led[2]}]
set_property -dict { PACKAGE_PIN V19  IOSTANDARD LVCMOS33 } [get_ports {led[3]}]

## Configuration for ring oscillator
set_property ALLOW_COMBINATORIAL_LOOPS true [get_nets async_count/inv_chain*]
set_property SEVERITY Warning [get_drc_checks LUTLP-1]
set_property SEVERITY Warning [get_drc_checks NSTD-1]

## Timing constraints for ring oscillator
create_clock -name ring_osc -period 2.000 [get_nets async_count/ring_osc]
set_clock_groups -asynchronous -group [get_clocks sys_clk_pin] -group [get_clocks ring_osc]

## False paths for asynchronous inputs/outputs
set_false_path -from [get_ports {sw[*]}]
set_false_path -to [get_ports {led[*]}]

## Configuration Display
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]