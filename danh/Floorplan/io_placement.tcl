set io_set 	[get_db insts -if {.base_cell.base_class eq pad}]
set conner_set 	[get_db insts -if {.base_cell.base_class eq corner}]
set io_in_set	{}
set io_out_set	{}

foreach item $io_set {
	set io_dir [get_db [lindex [get_db $item .pins] 1] .direction]
	
	if { $io_dir eq in } {
		lappend io_in_set $item
	} else {
		lappend io_out_set $item
	}
			
}
