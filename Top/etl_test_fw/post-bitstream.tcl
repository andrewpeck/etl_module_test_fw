set describe [GetGitDescribe $sha]
set dst_mcs [file normalize "$dst_dir/$proj_name\-$describe.mcs"]
set dst_bit [file normalize "$dst_dir/$proj_name\-$describe.bit"]

write_cfgmem -format mcs -size 64 -interface SPIx8 -loadbit \
    "up 0x00000000 $dst_bit" -file $dst_mcs

if [expr {[get_property SLACK [get_timing_paths -delay_type min_max]] < 0}] {
    error "ERROR: Timing failed"
}
