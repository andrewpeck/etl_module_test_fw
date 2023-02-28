set basename [file rootname [lindex [glob *.bit] 0]]
set bitfile ${basename}.bit
set binfile ${basename}.bin
set ltxfile ${basename}.ltx
set part     xcku040

open_hw_manager -quiet
connect_hw_server -quiet -url localhost:3121
refresh_hw_server -quiet

set known_boards [dict create \
    210308AB9AC5 "BU Right 192.168.0.11" \
    210308AB9ACD "BU Left 192.168.0.10" \
    210308B0B4F5 "CI 192.168.0.12"]

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
    set target $targets
    puts "Target $target [dict get $devices $target] found, press y key to continue."
    gets stdin select
    if {[string equal $select "y"]} {
        set targets $target
    } else {
        puts "No target selected"
        exit 0
    }
} elseif {[llength $targets] > 1} {
    puts "Multiple hardware targets found"
    for {set i 0} {$i < [llength $targets]} {incr i} {
        set target [lindex $targets $i]
        puts "  > $i $target"
        puts "      [dict get $devices $target]"

        set dsn [lindex [split "$target" "/"] end]
        if {[dict exists $known_boards $dsn]} {
        puts "      ([dict get $known_boards $dsn])"

        }
    }

    puts "  > \"all\" to program all"
    puts "  > anything else to quit"

    puts "Please select a target:"

    gets stdin select

    puts "$select selected"

    if {[string equal $select "all"]} {
        set targets $targets
    } elseif {![string is integer $select] || $select > $num_targets-1} {
        puts "Invalid target selected"
        exit 0
    } else {
        set targets [lindex $targets $select]
        puts " > selected $targets"
    }
}

foreach target $targets {
    puts " > Programming $target"
    get_hw_targets
    open_hw_target $target
    set device [dict get $devices $target]
    if {[llength $device] > 0} {

        set programmed "False"

        if {[string equal $device $device]} {
            puts "do you want to program the Flash? y/n"
            gets stdin select
            if {[string equal $select "y"]} {
                puts " > Programming Flash"
                program_flash $binfile $device "mt25qu256-spi-x1_x2_x4"
                boot_hw_device  [lindex [get_hw_devices $device] 0]
                set programmed "True"
            }
        }

        if {[string equal $programmed "True"] == 0} {
            puts " > Programming FPGA"
            current_hw_device [get_hw_devices $device]
            refresh_hw_device -update_hw_probes false $device
            set_property PROGRAM.FILE $bitfile $device
            set_property PROBES.FILE $ltxfile $device
            set_property FULL_PROBES.FILE $ltxfile $device
            program_hw_devices $device
            close_hw_target
        }
    }
}
