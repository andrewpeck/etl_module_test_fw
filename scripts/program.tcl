set basename [file rootname [lindex [glob *.bit] 0]]
set bitfile ${basename}.bit
set ltxfile ${basename}.ltx

open_hw_manager
connect_hw_server -allow_non_jtag
set targets [get_hw_targets]
set num_targets [llength $targets]

if {$num_targets == 0} {
    error "No hardware targets found"
} elseif {[llength $targets] > 1} {
    puts "Multiple hardware targets found"
    for {set i 0} {$i < $num_targets} {incr i} {
        puts "  > $i [lindex $targets $i]"
    }
    puts "  > \"all\" to program all"

    puts "Please select a target:"

    gets stdin select

    puts "$select selected"

    if {[string equal $select "all"]} {
        set targets $targets
    } elseif {$select > $num_targets-1} {
        error "Invalid target selected"
    } else {
        set targets [lindex $targets $select]
        puts " > selected $targets"
    }

}

foreach target $targets {
  puts " > Programming $target"
  get_hw_targets
  open_hw_target $target
  set device [get_hw_devices xcku040*]
  current_hw_device [get_hw_devices $device]
  refresh_hw_device -update_hw_probes false $device
  set_property PROGRAM.FILE $bitfile $device
  set_property PROBES.FILE $ltxfile $device
  set_property FULL_PROBES.FILE $ltxfile $device
  program_hw_devices $device
  close_hw_target
}
