.POSIX:

PREFIX = /usr/local
LIB = $(PREFIX)/lib/tcl
BIN = $(PREFIX)/bin

default:
	@echo "valid targets: install"
	@echo "influential macros:"
	@echo "PREFIX = $(PREFIX)"
	@echo "LIB = $(LIB)"
	@echo "BIN = $(BIN)"

install:
	mkdir -p $(LIB)
	mkdir -p $(BIN)
	cp -R trun $(LIB)
	cp tkrunner $(BIN)
