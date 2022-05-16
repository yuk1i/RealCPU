set_property -dict {PACKAGE_PIN Y18 IOSTANDARD LVCMOS33} [get_ports sys_clk]
#set_property -dict {PACKAGE_PIN P4 IOSTANDARD LVCMOS33} [get_ports sw_clk]
set_property -dict {PACKAGE_PIN P20 IOSTANDARD LVCMOS33} [get_ports rst_n]
set_property -dict {PACKAGE_PIN C19 IOSTANDARD LVCMOS33} [get_ports {test}]


#set_property -dict {PACKAGE_PIN Y9 IOSTANDARD LVCMOS33} [get_ports sw_pc_ins]
#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets sw_clk_IBUF]

#set_property -dict {PACKAGE_PIN E13 IOSTANDARD LVCMOS33} [get_ports {seg7_led[0]}]
#set_property -dict {PACKAGE_PIN C15 IOSTANDARD LVCMOS33} [get_ports {seg7_led[1]}]
#set_property -dict {PACKAGE_PIN C14 IOSTANDARD LVCMOS33} [get_ports {seg7_led[2]}]
#set_property -dict {PACKAGE_PIN E17 IOSTANDARD LVCMOS33} [get_ports {seg7_led[3]}]
#set_property -dict {PACKAGE_PIN F16 IOSTANDARD LVCMOS33} [get_ports {seg7_led[4]}]
#set_property -dict {PACKAGE_PIN F14 IOSTANDARD LVCMOS33} [get_ports {seg7_led[5]}]
#set_property -dict {PACKAGE_PIN F13 IOSTANDARD LVCMOS33} [get_ports {seg7_led[6]}]
#set_property -dict {PACKAGE_PIN F15 IOSTANDARD LVCMOS33} [get_ports {seg7_led[7]}]

#set_property -dict {PACKAGE_PIN A18 IOSTANDARD LVCMOS33} [get_ports {seg7_select[7]}]
#set_property -dict {PACKAGE_PIN A20 IOSTANDARD LVCMOS33} [get_ports {seg7_select[6]}]
#set_property -dict {PACKAGE_PIN B20 IOSTANDARD LVCMOS33} [get_ports {seg7_select[5]}]
#set_property -dict {PACKAGE_PIN E18 IOSTANDARD LVCMOS33} [get_ports {seg7_select[4]}]
#set_property -dict {PACKAGE_PIN F18 IOSTANDARD LVCMOS33} [get_ports {seg7_select[3]}]
#set_property -dict {PACKAGE_PIN D19 IOSTANDARD LVCMOS33} [get_ports {seg7_select[2]}]
#set_property -dict {PACKAGE_PIN E19 IOSTANDARD LVCMOS33} [get_ports {seg7_select[1]}]
#set_property -dict {PACKAGE_PIN C19 IOSTANDARD LVCMOS33} [get_ports {seg7_select[0]}]

set_property -dict {PACKAGE_PIN W4 IOSTANDARD LVCMOS33} [get_ports {switches_pin[0]}]
set_property -dict {PACKAGE_PIN R4 IOSTANDARD LVCMOS33} [get_ports {switches_pin[1]}]
set_property -dict {PACKAGE_PIN T4 IOSTANDARD LVCMOS33} [get_ports {switches_pin[2]}]
set_property -dict {PACKAGE_PIN T5 IOSTANDARD LVCMOS33} [get_ports {switches_pin[3]}]
set_property -dict {PACKAGE_PIN U5 IOSTANDARD LVCMOS33} [get_ports {switches_pin[4]}]
set_property -dict {PACKAGE_PIN W6 IOSTANDARD LVCMOS33} [get_ports {switches_pin[5]}]
set_property -dict {PACKAGE_PIN W5 IOSTANDARD LVCMOS33} [get_ports {switches_pin[6]}]
set_property -dict {PACKAGE_PIN U6 IOSTANDARD LVCMOS33} [get_ports {switches_pin[7]}]
set_property -dict {PACKAGE_PIN V5 IOSTANDARD LVCMOS33} [get_ports {switches_pin[8]}]
set_property -dict {PACKAGE_PIN R6 IOSTANDARD LVCMOS33} [get_ports {switches_pin[9]}]
set_property -dict {PACKAGE_PIN T6 IOSTANDARD LVCMOS33} [get_ports {switches_pin[10]}]
set_property -dict {PACKAGE_PIN Y6 IOSTANDARD LVCMOS33} [get_ports {switches_pin[11]}]
set_property -dict {PACKAGE_PIN AA6 IOSTANDARD LVCMOS33} [get_ports {switches_pin[12]}]
set_property -dict {PACKAGE_PIN V7 IOSTANDARD LVCMOS33} [get_ports {switches_pin[13]}]
set_property -dict {PACKAGE_PIN AB7 IOSTANDARD LVCMOS33} [get_ports {switches_pin[14]}]
set_property -dict {PACKAGE_PIN AB6 IOSTANDARD LVCMOS33} [get_ports {switches_pin[15]}]
set_property -dict {PACKAGE_PIN V9 IOSTANDARD LVCMOS33} [get_ports {switches_pin[16]}]
set_property -dict {PACKAGE_PIN V8 IOSTANDARD LVCMOS33} [get_ports {switches_pin[17]}]
set_property -dict {PACKAGE_PIN AA8 IOSTANDARD LVCMOS33} [get_ports {switches_pin[18]}]
set_property -dict {PACKAGE_PIN AB8 IOSTANDARD LVCMOS33} [get_ports {switches_pin[19]}]
set_property -dict {PACKAGE_PIN Y8 IOSTANDARD LVCMOS33} [get_ports {switches_pin[20]}]
set_property -dict {PACKAGE_PIN Y7 IOSTANDARD LVCMOS33} [get_ports {switches_pin[21]}]
set_property -dict {PACKAGE_PIN W9 IOSTANDARD LVCMOS33} [get_ports {switches_pin[22]}]
set_property -dict {PACKAGE_PIN Y7 IOSTANDARD LVCMOS33} [get_ports {switches_pin[23]}]


set_property -dict {PACKAGE_PIN N19 IOSTANDARD LVCMOS33} [get_ports {leds_pin[0]}]
set_property -dict {PACKAGE_PIN N20 IOSTANDARD LVCMOS33} [get_ports {leds_pin[1]}]
set_property -dict {PACKAGE_PIN M20 IOSTANDARD LVCMOS33} [get_ports {leds_pin[2]}]
set_property -dict {PACKAGE_PIN K13 IOSTANDARD LVCMOS33} [get_ports {leds_pin[3]}]
set_property -dict {PACKAGE_PIN K14 IOSTANDARD LVCMOS33} [get_ports {leds_pin[4]}]
set_property -dict {PACKAGE_PIN M13 IOSTANDARD LVCMOS33} [get_ports {leds_pin[5]}]
set_property -dict {PACKAGE_PIN L13 IOSTANDARD LVCMOS33} [get_ports {leds_pin[6]}]
set_property -dict {PACKAGE_PIN K17 IOSTANDARD LVCMOS33} [get_ports {leds_pin[7]}]
set_property -dict {PACKAGE_PIN J17 IOSTANDARD LVCMOS33} [get_ports {leds_pin[8]}]
set_property -dict {PACKAGE_PIN L14 IOSTANDARD LVCMOS33} [get_ports {leds_pin[9]}]
set_property -dict {PACKAGE_PIN L15 IOSTANDARD LVCMOS33} [get_ports {leds_pin[10]}]
set_property -dict {PACKAGE_PIN L16 IOSTANDARD LVCMOS33} [get_ports {leds_pin[11]}]
set_property -dict {PACKAGE_PIN K16 IOSTANDARD LVCMOS33} [get_ports {leds_pin[12]}]
set_property -dict {PACKAGE_PIN M15 IOSTANDARD LVCMOS33} [get_ports {leds_pin[13]}]
set_property -dict {PACKAGE_PIN M16 IOSTANDARD LVCMOS33} [get_ports {leds_pin[14]}]
set_property -dict {PACKAGE_PIN M17 IOSTANDARD LVCMOS33} [get_ports {leds_pin[15]}]
set_property -dict {PACKAGE_PIN A21 IOSTANDARD LVCMOS33} [get_ports {leds_pin[16]}]
set_property -dict {PACKAGE_PIN E22 IOSTANDARD LVCMOS33} [get_ports {leds_pin[17]}]
set_property -dict {PACKAGE_PIN D22 IOSTANDARD LVCMOS33} [get_ports {leds_pin[18]}]
set_property -dict {PACKAGE_PIN E21 IOSTANDARD LVCMOS33} [get_ports {leds_pin[19]}]
set_property -dict {PACKAGE_PIN D21 IOSTANDARD LVCMOS33} [get_ports {leds_pin[20]}]
set_property -dict {PACKAGE_PIN G21 IOSTANDARD LVCMOS33} [get_ports {leds_pin[21]}]
set_property -dict {PACKAGE_PIN G22 IOSTANDARD LVCMOS33} [get_ports {leds_pin[22]}]
set_property -dict {PACKAGE_PIN F21 IOSTANDARD LVCMOS33} [get_ports {leds_pin[23]}]
