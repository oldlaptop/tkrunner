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

and then bound to a keyboard shortcut in your window manager.
When
**tkrunner**
is first invoked, it displays its window (unless told otherwise with -quiet),
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
Specifically, the environment it provides
differs from a clean, default
tclsh(1)
session as follows:

*	All commands are evaluated in the namespace
	**::trun**.

*	The default
	**namespace path**
	contains the
	mathop(n)
	and
	mathfunc(n)
	namespaces.

*	The
	**::trun**
	namespace itself provides several commands:

	runcmd

	> Accepts the same pipeline syntax as
	> exec(n)
	> while automatically redirecting pipeline output to a temporary file, and
	> backgrounding the pipeline.

	openurl

	> Expects a single
	> *url*
	> argument, and passes it to
	> xdg-open(1)
	> via runcmd.

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

	-	Command lines that begin with a shortcut name and a colon, for example,
		'wp:Main Page'
		are evaluated in the
		**::trun::shortcuts**
		namespace after replacing the colon with a space.

	-	All other command lines are treated as
		exec(n)
		pipelines and passed to
		**runcmd**.

	Any command that causes the unknown handler to be invoked causes the dialog to
	be hidden after a few seconds.

Commands entered at the dialog box are evaluated and their results displayed
at the bottom of the dialog.
Any errors are also caught and indicated here.
This environment is a child
interp(n)
and therefore cannot directly introspect or mangle the main application's state,
but it does have full control over its own state, and the full Tcl language at
its disposal.

## SHORTCUTS

No shortcuts are implemented yet.
They are envisioned to function like the Web Shortcuts supported by
**Konqueror**
and
**KRunner**.

# EXAMPLES

Run a program in the default search path:

	xterm

Open a directory full of text files in
kate(1)
using the
glob(n)
command (note that Tcl syntax applies, not the Bourne shell as in most other
run-command dialog utilities):

	kate [glob -types f /home/user/src/tkrunner/*]

Evaluate arithmetic expressions in infix notation (with the
expr(n)
command):

	expr {sin(3 * 3.14159 / 2)}

Or in prefix notation (with the commands found in the
mathop(n)
and
mathfunc(n)
namespaces):

	sin [/ [* 3 3.14159] 2]

# BUGS

Much functionality remains to be implemented.

Up-to-date information on any issues may be found on the Gitub issue tracker:
https://github.com/oldlaptop/tkrunner/issues

OpenBSD 6.7 - June 21, 2020
