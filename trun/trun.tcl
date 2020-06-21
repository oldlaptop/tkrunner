package provide trun 0.1

namespace eval trun {

namespace path [concat [namespace path] ::tcl::mathop ::tcl::mathfunc]

proc runcmd {args} {
	# we don't want the channel, just the filename
	close [file tempfile spewfile trun.spew]
	exec -ignorestderr -- >>& $spewfile {*}$args &
	return "launched exec(n) pipeline `$args &` (output in $spewfile)"
}

proc openurl {url} {
	runcmd xdg-open $url
}

proc unknown {args} {
	# if we have a URL (regexp from RFC3986 with parts 1 and 3 made mandatory)
	if {[regexp {^(([^:/?#]+):)(//([^/?#]*))([^?#]*)(\?([^#]*))?(#(.*))?} $args]} {
		return [openurl $args]
	# if we have a shortcut spec...
	} elseif {[regexp {^[a-z]+:[^:]} $args]} {
		# Try it as a shortcut
		set spec [string map {: { }} $args]
		set script [list [lindex $spec 0] [lrange spec 1 end]]

		return [namespace eval [namespace current]::shortcuts $script]
	# otherwise treat it as an exec(n) pipeline
	} else {
		return [runcmd {*}$args]
	}
}
namespace unknown unknown

namespace eval shortcuts {
	proc unknown {shortcut args} {
		error "no such shortcut $shortcut"
	}
	namespace unknown unknown
}

} ;# namespace eval trun
