set inst_set [get_db insts -if {.is_pad == false && .is_macro == false}]
set out "LCS.txt"
set fp [open $out w]

foreach i $inst_set {
	puts $fp $i	
	
}

close $fp
