#=== FUNCTION ================================================================
# NAME: print_usage
# DESCRIPTION: Display usage information for this script.
# PARAMETER 1: script name
#=============================================================================
function print_usage() {
cat <<- EOT
Run a mhealth benchmarking test given an options.

usage : $1 -c <config file> -t <time> -w <workers> -o <operation> [-d]

example usage : $1 -c mhealth_test.cfg -t 60 -w 1 -o login
		
-c <config: location of config file> 
-t <time: (in seconds) 30 | 60 | 120>
-w <workers: 1 | 10 | 20 | 100>
-o <operation: all | login | nonstandardlogin | loginreadwrite>
-d (debug, prints diagnostic information)
EOT
}

#=== FUNCTION ================================================================
# NAME: print_debug
# DESCRIPTION: used to print debug information
# PARAMETER 1: message
#=============================================================================
function print_debug() {
	if [ "$DEBUG" == TRUE ]; 
	then 
		echo "**DEBUG**: $1"; 
	fi
}

#=== FUNCTION ================================================================
# NAME: print_exception
# DESCRIPTION: used to print exception information
# PARAMETER 1: message
#=============================================================================
function print_exception() {
	echo "**EXCEPTION**: $1" >> $results_dir/exception.txt
}
