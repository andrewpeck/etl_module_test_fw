set basename [file rootname [lindex [glob *.bit] 0]]
set bitfile ${basename}.bit
set ltxfile ${basename}.ltx

open_hw_manager
connect_hw_server -allow_non_jtag
open_hw_target
current_hw_device [get_hw_devices xcku040_0]
refresh_hw_device -update_hw_probes false [lindex [get_hw_devices xcku040_0] 0]
set_property PROGRAM.FILE $bitfile [get_hw_devices xcku040_0]
set_property PROBES.FILE $ltxfile [get_hw_devices xcku040_0]
set_property FULL_PROBES.FILE $ltxfile [get_hw_devices xcku040_0]
program_hw_devices [get_hw_devices xcku040_0]
refresh_hw_device [lindex [get_hw_devices xcku040_0] 0]
