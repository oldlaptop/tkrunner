.POSIX:

PREFIX = /usr/local
LIB = $(PREFIX)/lib/tcl
BIN = $(PREFIX)/bin
MAN = $(PREFIX)/share/man

default:
	@echo "valid targets: install"
	@echo "influential macros:"
	@echo "PREFIX = $(PREFIX)"
	@echo "LIB = $(LIB)"
	@echo "BIN = $(BIN)"
	@echo "MAN = $(MAN)"

install:
	mkdir -p $(LIB)
	mkdir -p $(BIN)
	mkdir -p $(MAN)/man1
	cp -pR trun $(LIB)
	cp -p tkrunner $(BIN)
	cp -p tkrunner.1 $(MAN)/man1
