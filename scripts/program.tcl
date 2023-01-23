set basename [file rootname [lindex [glob *.bit] 0]]
set bitfile ${basename}.bit
set ltxfile ${basename}.ltx
set part     xcku040

open_hw_manager -quiet
connect_hw_server -quiet -url localhost:3121
refresh_hw_server -quiet

set targets [get_hw_targets -quiet]
set num_targets [llength $targets]

if {$num_targets == 0} {
    puts "ERROR: No hardware targets found"
    exit 0
} else {

    # make a dictionary of the device names (e.g. xc7v...)
    set devices [dict create]
    foreach target $targets {
        close_hw_target -quiet
        open_hw_target -quiet $target
        #set device [get_hw_devices]
        set device [get_hw_devices -quiet ${part}*]
        if {[llength $device] > 0} {
            puts "Device=$device"
            dict set devices $target $device
            close_hw_target -quiet
        }
    }

}

set targets [dict keys $devices]

if {[llength $targets] == 1} {
    puts "Target $target [dict get $devices $target] found, press any key to continue."
    puts "   > Device: "
    gets stdin select
} elseif {[llength $targets] > 1} {
    puts "Multiple hardware targets found"
    for {set i 0} {$i < [llength $targets]} {incr i} {
        set target [lindex $targets $i]
        puts "  > $i $target"
        puts "      [dict get $devices $target]"
    }
    puts "  > \"all\" to program all"
    puts "  > anything else to quit"

    puts "Please select a target:"

    gets stdin select

    puts "$select selected"

    if {[string equal $select "all"]} {
        set targets $targets
    } elseif {![string is integer $select] || $select > $num_targets-1} {
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
    set device [get_hw_devices ${part}*]
    if {[llength $device] > 0} {
        current_hw_device [get_hw_devices $device]
        refresh_hw_device -update_hw_probes false $device
        set_property PROGRAM.FILE $bitfile $device
        set_property PROBES.FILE $ltxfile $device
        set_property FULL_PROBES.FILE $ltxfile $device
        program_hw_devices $device
        close_hw_target
    }
}
