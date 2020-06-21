# Copyright (c) 2020 Peter Piwowarski <peterjpiwowarski@gmail.com>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

package require http

package provide trun 0.1

namespace eval trun {

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
		set script [list [lindex $spec 0] [lrange $spec 1 end]]

		return [namespace eval [namespace current]::shortcuts $script]
	# otherwise treat it as an exec(n) pipeline
	} else {
		return [runcmd {*}$args]
	}
}

namespace eval shortcuts {
	namespace path [concat [namespace path] [namespace parent]]

	# DuckDuckGo search
	proc dd {query} {
		openurl https://duckduckgo.com/?[http::formatQuery q $query]
	}

	# Google search
	proc gg {query} {
		openurl https://google.com/search?[http::formatQuery q $query]
	}

	# Local manpage search; requires mandoc be installed and man(1) support the
	# -w option
	proc man {query} {
		if {[auto_execok mandoc] eq ""} {
			error "the man: shortcut requires mandoc"
		}

		regexp {([[:alnum:]\-_:\.]+)(\(([[:digit:]]?[[:lower:]]?)\))?} $query -> name -> section
		if {$section eq ""} {
			set src [lindex [exec man -w $name] 0]
		} else {
			set src [exec man -w $section $name]
		}

		set outchan [file tempfile outname tkrunner-man.html]
		try {
			exec mandoc -T html $src >@ $outchan
		} finally {
			close $outchan
		}
		openurl $outname
	}

	# openports.pl pkgname search
	proc op {pkgname} {
		openurl https://openports.pl/search?[http::formatQuery pkgname $pkgname]
	}

	# Wikipedia search
	proc wp {query} {
		openurl https://en.wikipedia.org/w/index.php?[http::formatQuery search $query]
	}

	proc unknown {shortcut args} {
		error "no such shortcut $shortcut"
	}
	namespace unknown unknown
}

} ;# namespace eval trun
