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

# {*}
package require Tcl 8.5

# used for ::http::formatQuery
package require http

package provide trun 0.1

namespace eval trun {

proc runcmd {args} {
	# we don't want the channel, just the filename
	# note that the command could have an explicit path specification
	close [file tempfile spewfile trun-[file tail [lindex $args 0]].spew]
	exec -ignorestderr -- >>& $spewfile {*}$args &
	return "launched exec(n) pipeline `$args &` (output in $spewfile)"
}

proc openurl {url} {
	runcmd xdg-open $url
}
interp alias {} go {} openurl

proc 1glob {args} {
	lindex [glob $args] 0
}

proc unknown {args} {
	# if we have a URL (regexp from RFC3986 with parts 1 and 3 made mandatory,
	# and internal spaces disallowed in the protocol and host)
	if {[regexp {^(([^:/?#[:space:]]+):)(//([^/?#[:space:]]*))([^?#]*)(\?([^#]*))?(#(.*))?} $args]} {
		return [openurl [join $args]]
	# if we have a shortcut spec...
	} elseif {[regexp {^[a-z]+:[^:]} $args]} {
		# Try it as a shortcut
		set spec [join $args]
		set pivot [string first : $spec]
		set script [list [string range $spec 0 $pivot-1] [string range $spec $pivot+1 end]]

		return [namespace eval [namespace current]::shortcuts $script]
	# if we have the name/path of a non-executable file...
	} elseif {
		[file pathtype $args] eq {absolute} &&
		[file exists $args] &&
		!([file isfile $args] && [file executable $args])
	} {
		return [openurl [join $args]]
	# otherwise treat it as an exec(n) pipeline
	} else {
		return [runcmd {*}$args]
	}
}

proc Decompress {file} {
	set decompressor {}

	# These decompressor names are chosen with an eye to "mainstream"
	# linuxes, on the theory that systems for which one or more of these
	# choices are wrong (such as OpenBSD) are likely to be systems that do
	# not do things like bzip2 all the manual pages (as OpenBSD is).
	switch -glob -- $file {
		*.gz { set decompressor zcat }
		*.bz2 { set decompressor bzcat }
		*.xz { set decompressor xzcat }
		default { }
	}
	if {$decompressor eq {}} {
		return $file
	} else {
		set fd [file tempfile output trun-decompressed]
		try {
			exec $decompressor $file >@ $fd
			return $output
		} finally {
			close $fd
		}
	}
}

namespace eval shortcuts {
	namespace path [concat [namespace path] [namespace parent]]

	variable manexp {([[:alnum:]\-_:\.]+)(\(([[:digit:]]?[[:lower:]]?)\))?}

	# Amazon search
	proc amazon {query} {
		openurl https://amazon.com/s?[http::formatQuery k $query]
	}

	# Debian package search
	proc deb {query} {
		# quoteString
		package require http 2.9.1

		openurl https://packages.debian.org/[http::quoteString $query]
	}

	# DuckDuckGo search
	proc dd {query} {
		openurl https://duckduckgo.com/?[http::formatQuery q $query]
	}

	# Debian manpage search
	proc dman {query} {
		variable manexp

		# manpages.debian.org is tolerant of the stray .
		regexp $manexp $query -> name -> section
		openurl https://manpages.debian.org/$name.$section
	}

	# eBay search
	proc ebay {query} {
		openurl https://www.ebay.com/sch/i.html?[http::formatQuery _nkw $query]
	}

	# Google search
	proc gg {query} {
		openurl https://google.com/search?[http::formatQuery q $query]
	}

	# Local manpage search; requires mandoc be installed and man(1) support the
	# -w option
	proc man {query} {
		variable manexp

		if {[auto_execok mandoc] eq ""} {
			error "the man: shortcut requires mandoc"
		}

		regexp $manexp $query -> name -> section
		# a stray empty argument will confuse man(1)
		if {$section eq ""} {
			set sources [exec man -w $name]
		} else {
			set sources [exec man -w $section $name]
		}

		set messages [list]
		foreach src $sources {
			if {[string match */cat*/*.0 $src]} {
				# Display unformatted pages directly.
				set outname $src
			} else {
				set outchan [file tempfile outname trun-man-${name}_${section}.html]
				try {
					exec mandoc -T html [Decompress $src] >@ $outchan
				} finally {
					close $outchan
				}
			}
			lappend messages [openurl $outname]
		}

		return [join $messages \n]
	}

	# Helper for man.cgi manpage searches.
	proc Man.cgi {url query} {
		variable manexp

		regexp $manexp $query -> name -> section

		set url $url/$name

		# man.cgi is confused by a stray .
		if {$section ne ""} {
			set url ${url}.$section
		}

		openurl $url
	}

	# OpenBSD manpage search
	proc om {query} {
		Man.cgi "https://man.openbsd.org" $query
	}

	# man.bsd.lv manpage search
	proc mbl {query} {
		Man.cgi "https://man.bsd.lv" $query
	}

	# man.voidlinux.org manpage search
	proc vman {query} {
		Man.cgi "https://man.voidlinux.org" $query
	}

	# openports.pl pkgname search
	proc op {pkgname} {
		openurl https://openports.pl/search?[http::formatQuery pkgname $pkgname]
	}

	# TIPs by number
	proc tip {n} {
		set n [expr {entier($n)}]
		openurl https://core.tcl-lang.org/tips/doc/trunk/tip/$n.md
	}

	# TIP search
	proc tips {query} {
		openurl https://core.tcl-lang.org/tips/search?[http::formatQuery s $query y all]
	}

	# Tcl core commits
	proc thash {hash} {
		openurl https://core.tcl-lang.org/redirect?[http::formatQuery name $hash]
	}

	# Tcl wiki full-text search
	proc tw {query} {
		openurl https://wiki.tcl-lang.org/search?[http::formatQuery Q $query]
	}

	# Wolfram Alpha query
	proc wa {query} {
		openurl https://www.wolframalpha.com/input/?[http::formatQuery i $query]
	}

	# Wikipedia search
	proc wp {query} {
		openurl https://en.wikipedia.org/w/index.php?[http::formatQuery search $query]
	}

	# Wiktionary search
	proc wikt {query} {
		openurl https://en.wiktionary.org/w/index.php?[http::formatQuery search $query]
	}

	# YouTube search
	proc yt {query} {
		openurl https://www.youtube.com/results?[http::formatQuery search_query $query]
	}

	proc unknown {shortcut args} {
		error "no such shortcut $shortcut"
	}
	namespace unknown unknown
}

} ;# namespace eval trun

if {[info exists ::argv0] && $::argv0 eq [info script]} {
	package require tcltest
	::tcltest::configure -testdir [file dirname [info script]]
	::tcltest::configure {*}$argv
	::tcltest::runAllTests
}
