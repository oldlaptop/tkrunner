.POSIX:

TCLSH = /usr/bin/env tclsh
PREFIX = /usr/local
LIB = $(PREFIX)/lib/tcl
BIN = $(PREFIX)/bin
MAN = $(PREFIX)/share/man
XDG_APPLICATIONS = $(PREFIX)/share/applications

default:
	@echo "valid targets: install, test, README.md"
	@echo "influential macros:"
	@echo "PREFIX = $(PREFIX)"
	@echo "LIB = $(LIB)"
	@echo "BIN = $(BIN)"
	@echo "MAN = $(MAN)"
	@echo "XDG_APPLICATIONS = $(XDG_APPLICATIONS)"

install:
	mkdir -p $(LIB)
	mkdir -p $(BIN)
	mkdir -p $(MAN)/man1
	mkdir -p $(XDG_APPLICATIONS)
	cp -pR trun $(LIB)
	cp -p tkrunner $(BIN)
	cp -p tkrunner.1 $(MAN)/man1
	cp -p tkrunner.desktop $(XDG_APPLICATIONS)
	@echo "you may wish to run update-desktop-database, kbuildsycoca, or similar"

test:
	$(TCLSH) trun/trun.tcl

README.md: tkrunner.1
	-mandoc -T markdown -W base $? > $@
