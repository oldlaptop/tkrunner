TKRUNNER(1) - General Commands Manual

# NAME

**tkrunner** - run command dialog for X in Tcl/Tk

# SYNOPSIS

**tkrunner**
\[-quiet]

# DESCRIPTION

**tkrunner**
displays a Run Command dialog box that accepts an extended
Tcl(n)
syntax.
It is intended to be invoked from an X startup file such as
*~/.xsession*
or
*~/.xinitrc*
in the background:

	tkrunner -quiet &

and then bound to a keyboard shortcut in your window manager or desktop environment.
When
**tkrunner**
is first invoked, it displays its window
(unless told otherwise with -quiet)
but stays resident after it is destroyed.
Afterwards, when invoked again,
**tkrunner**
will instruct the running instance to display its window again, using Tk's
send(n)
facility.

## USAGE

The Run Command dialog accepts the full
Tcl(n)
syntax, with several extensions.
Specifically, the environment it provides differs from a clean, default Tcl
interpreter as follows:

*	The
	http(n)
	package is loaded.
	(It is used internally for URL processing.)

*	The
	**trun**
	package is loaded, which provides the
	**::trun**
	namespace
	(described below).

*	The default
	**namespace path**
	contains the
	mathop(n)
	and
	mathfunc(n)
	namespaces, as well as
	**::trun**.

*	The
	**::trun**
	namespace itself provides several commands:

	**1glob** *arg* \[arg...]

	> Identical to
	> glob(n),
	> but returns only the first element of the list of matches; useful for specifying
	> URLs.

	**runcmd** *arg* \[arg...]

	> Accepts the same pipeline syntax as
	> exec(n)
	> while automatically redirecting pipeline output to a temporary file, and
	> backgrounding the pipeline.

	**openurl** *url*

	> Passes its
	> *url*
	> argument directly to
	> xdg-open(1)
	> via runcmd.

	**go** *url*

	> Alias to
	> **openurl**.

*	The
	**::trun**
	namespace contains a child namespace called
	**shortcuts**
	that supplies implementations of the shortcuts described under
	*SHORTCUTS*
	as commands.

*	The
	**namespace unknown**
	facility is used to implement syntactic sugar as follows:

	-	Command lines that appear to be valid URLs are passed to
		**openurl**.

	-	Command lines that are valid shortcut specifications are evaluated in the
		**::trun::shortcuts**
		namespace, after replacing the colon with a space and concatenating all but the
		first element in the Tcl list thus produced.
		The commandline
		'dd:tcl documentation'
		is therefore transformed to
		'dd {tcl documentation}'
		and evaluated.

	-	All other command lines are treated as
		exec(n)
		pipelines and passed to
		**runcmd**.

	Any command that causes the unknown handler to be invoked also causes the dialog
	to be hidden after a few seconds.

*	The command
	**hide**
	is present in the root namespace, and causes the dialog box to hide itself.

Commands entered at the dialog box are evaluated and their results added to the
history display at the bottom of the dialog, preceded by a sequence number
indicating which command produced the results.
Any errors are also caught and indicated here.
The command itself is also added to the command history, which may be navigated
by pressing the Up and Down keys while the command entry widget has input focus.
The numeric indicator to the left of the command entry widget will update to
show which results in the output history it corresponds to.

The execution environment provided by
**tkrunner**
is a child
interp(n)
and therefore cannot directly introspect or mangle the main application's state,
but it does have full control over its own state, and the full Tcl language is
at its disposal.

## SHORTCUTS

Shortcuts are inspired by the Web Shortcuts supported by
**Konqueror**
and
**KRunner**.
Shortcut specifications consist of a shortcut name and a shortcut query,
separated by a single colon, for example:

	wp:Main Page

Running a shortcut generally results in a URL being opened in the user's default
application with
xdg-open(1),
but other behaviors are possible.
The currently implemented shortcuts are:

**amazon**

> Amazon.com search for the shortcut query.

**deb**

> Debian package search for the shortcut query.

**dd**

> DuckDuckGo search for the shortcut query.

**dman**

> Debian manpage search for the shortcut query, interpreted as for the
> **man**
> shortcut.

**ebay**

> eBay search for the shortcut query.

**gg**

> Google search for the shortcut query.

**man**

> Local manpage search.
> The shortcut query is interpreted as a manual page
> specifier in the typical name(section) format, and a lookup is performed with
> man(1);
> if the section is omitted, the section argument to
> man(1)
> will be omitted, and the first matching page will be selected.
> The manual page will be formatted as HTML using
> mandoc(1)
> and opened with
> xdg-open(1).
> mandoc(1)
> must be installed, and the system's implementation of
> man(1)
> must support the
> **-w**
> option to print the paths to manual page source files.

**om**

> man.openbsd.org search for the shortcut query, interpreted as for the
> **man**
> shortcut.

**mbl**

> man.bsd.lv search for the shortcut query, interpreted as for the
> **man**
> shortcut.

**op**

> openports.pl pkgname search for the shortcut query.

**tip**

> Interpret the shortcut query as a Tcl Improvement Proposal (TIP) number and open
> it.

**tips**

> Search Tcl Improvement Proposals for the shortcut query.

**thash**

> Interpret the shortcut query as a commit hash in one of the
> [https://core.tcl-lang.org](https://core.tcl-lang.org)
> fossil repositories and attempt to open it.

**tw**

> Full-text Tcl wiki search for the shortcut query.

**wp**

> Wikipedia search for the shortcut query.

**wikt**

> Wiktionary search for the shortcut query.

**yt**

> YouTube search for the shortcut query.

All shortcuts are implemented as commands in the ::trun::shortcuts namespace.

# REMOTE-CALLABLE COMMANDS

The following commands are defined in the application's root interpreter and may
be called by other Tk applications with
send(n).
**tkrunner**
uses
"tkrunner"
as its Tk application name.

**show**

> Shows the Run Command dialog, raising its focus it it is already shown.

**hide**

> Hides the Run Command dialog, if it is shown.

**run** *cmd*

> Run a command as though it was entered at the dialog box, properly registering
> it in the command history.

# EXAMPLES

Run a program in the default search path:

	xterm

Open a directory full of text files in
kate(1)
using the
glob(n)
command
(note that Tcl syntax applies, not the Bourne shell as in most other
run-command dialog utilities)
:

	kate {*}[glob -types f /home/user/src/tkrunner/*]

Open a file under the current user's home directory; note the use of the
**1glob**
command to avoid the need for a construct like
"\[lindex \[glob ~/downloads/paper.pdf] 0]"
:

	file://[1glob ~/Downloads/paper.pdf]

Evaluate arithmetic expressions in infix notation
(with the
expr(n)
command)
:

	expr {sin(3 * 3.14159 / 2)}

Or in prefix notation
(with the commands found in the
mathop(n)
and
mathfunc(n)
namespaces)
:

	sin [/ [* 3 3.14159] 2]

Start the spreadsheet program
**abs**
(once found in an OpenBSD package of the same name),
whose name clashed with the
mathfunc(n)
command
**abs**
(the
';hide'
at the end may be omitted, since it merely causes the dialog to hide itself
after executing the command)
:

	runcmd abs ;hide

# BUGS

Much functionality remains to be implemented.

The GUI layout originated as a rough prototype, but seems to be working well.
It should still be considered changeable at the whim of the author.

> "This is only temporary, unless it works."
> &#8212; Red Green

Up-to-date information on any issues may be found on the Github issue tracker:
[https://github.com/oldlaptop/tkrunner/issues](https://github.com/oldlaptop/tkrunner/issues)

Void Linux - September 12, 2021
