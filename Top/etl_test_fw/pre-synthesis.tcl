# replace the confusing Hog GLOBAL_SHA with one that actually makes sense
set generic_string [get_property generic [current_fileset]]
if {[string first REPO_SHA $generic_string] != -1} {
    regsub -all "REPO_SHA=32'h[0-9,A-f]*" $generic_string "REPO_SHA=32'h0[string range [exec git log -n1 --format=format:\"%H\"] 1 7]" generic_string
} else {
    set generic_string "$generic_string REPO_SHA=32'h0[string range [exec git log -n1 --format=format:\"%H\"] 1 7]"
}
set_property generic $generic_string [current_fileset]
