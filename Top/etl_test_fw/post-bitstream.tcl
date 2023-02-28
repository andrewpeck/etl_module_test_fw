set describe [GetHogDescribe $sha]
#set dst_mcs [file normalize "$dst_dir/$proj_name\-$describe.mcs"]
#set dst_bit [file normalize "$dst_dir/$proj_name\-$describe.bit"]

file copy -force [file normalize $dst_dir/../../scripts/program.tcl] $dst_dir/program.tcl
file copy -force [file normalize $dst_dir/../../scripts/program.sh] $dst_dir/program.sh

# write_cfgmem -force -format mcs -size 64 -interface SPIx8 -loadbit \
#     "up 0x00000000 $dst_bit" -file $dst_mcs

# if [expr {[get_property SLACK [get_timing_paths -delay_type min_max]] < 0}] {
#     error "ERROR: Timing failed"
# }
