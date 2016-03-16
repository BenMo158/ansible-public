AXIS_USABLE_LIBS = GLIBC UCLIBC
include $(AXIS_TOP_DIR)/tools/build/Rules.axis

PROG = start-stop-daemon

all: $(PROG)

install: all
	$(INSTALL) -m 0755 -o root -g root $(PROG) $(prefix)/sbin

clean:
	rm -f $(PROG)
