#
# by Frank Rysanek <rysanek@fccps.cz>
#
# Based on the source code of ioperm.c by Marcel Telka <marcel@telka.sk>
#   - thanks a million :-)
#

# Note that after changing the driver name, you also have
# to rename $(DRVNAME).c manually in this directory :-)
DRVNAME = smbfs

OBJS = smbfs.o logger.o tdi.o conn.o session.o tree.o file.o

#INCLUDES = -I/usr/include/w32api/ddk
#INCLUDES = -I/usr/x86_64-w64-mingw32/usr/include/ddk
INCLUDES = -I/usr/i686-w64-mingw32/usr/include/ddk -I/usr/i686-w64-mingw32/usr/include

# We could in fact just add -DMY_DRIVER_NAME=\"$(DRVNAME)\" to CFLAGS,
# but we'd have to be careful to "make clean" after changing
# the driver name here in the makefile...
#CFLAGS = -Wall $(INCLUDES) -DMY_DRIVER_NAME=\"$(DRVNAME)\"
CFLAGS = -Wall -Wno-unknown-pragmas $(INCLUDES) -g -msse4.2 -D_DEBUG -Wunused-parameter -Wtype-limits -Wextra -fno-exceptions -mrtd -std=c++17 -fno-rtti -D__INTRINSIC_DEFINED_InterlockedBitTestAndSet -D__INTRINSIC_DEFINED_InterlockedBitTestAndReset -Wno-address

# Kernel-mode libs:
#   libntoskrnl = basic kernel-mode environment
#   libhal = WRITE_PORT_UCHAR et al.
#KRNLIBS = -lntoskrnl -lhal
KRNLIBS = -lntoskrnl -lhal -lgcc -luuid

#CC = gcc
#CC = x86_64-w64-mingw32-gcc
CC = i686-w64-mingw32-gcc
DLLTOOL = i686-w64-mingw32-dlltool
STRIP = strip

all: $(DRVNAME).sys

# Dependencies on header files:
$(DRVNAME).sys:

# This shall get appended to the built-in set of suffixes supported:
.SUFFIXES: .sys .exe
# Otherwise the custom inference rules below wouldn't ever kick in.

# This is implicit, no need to define this explicitly:
#.c.o:
#	$(CC) $(CFLAGS) -c -o $@ $<

smbfs.o: src/smbfs.cpp src/smbfs.h src/smb.h
	$(CC) $(CFLAGS) -c -o $@ $<

logger.o: src/logger.cpp src/smbfs.h src/smb.h
	$(CC) $(CFLAGS) -c -o $@ $<

tdi.o: src/tdi.cpp src/smbfs.h src/smb.h
	$(CC) $(CFLAGS) -c -o $@ $<

conn.o: src/conn.cpp src/smbfs.h src/smb.h
	$(CC) $(CFLAGS) -c -o $@ $<

session.o: src/session.cpp src/smbfs.h src/smb.h
	$(CC) $(CFLAGS) -c -o $@ $<

tree.o: src/tree.cpp src/smbfs.h src/smb.h
	$(CC) $(CFLAGS) -c -o $@ $<

file.o: src/file.cpp src/smbfs.h src/smb.h
	$(CC) $(CFLAGS) -c -o $@ $<

smbfs.sys: $(OBJS)

# This inference rule allows us to turn an .o into a .sys without
# much hassle, implicitly.
# The downside is, that you cannot potentially add further object files
# to get linked into the .sys driver (such as, some custom ASM routines).
# Oh wait, maybe you can... try adding your .o after the last $(CC) in the rule...
.o.sys:
	$(CC)	-Wl,--base-file,$*.base \
	-Wl,--entry,DriverEntry \
	-nostartfiles -nostdlib \
	-o junk.tmp \
	$(OBJS) \
	$(KRNLIBS)
	-rm -f junk.tmp
	$(DLLTOOL) --dllname $*.sys \
	--base-file $*.base --output-exp $*.exp
	$(CC) -Wl,--subsystem,native \
	-Wl,--image-base,0x10000 \
	-Wl,--file-alignment,0x1000 \
	-Wl,--section-alignment,0x1000 \
	-Wl,--exclude-all-symbols \
	-Wl,--entry,DriverEntry \
	-Wl,--stack,0x40000 \
	-Wl,$*.exp \
	-mdll -nostartfiles -nostdlib \
	-o $*.sys \
	$(OBJS) \
	$(KRNLIBS)

#	$(STRIP) $*.sys

JUNK = *.base *.exp *.o *~ junk.tmp

clean:
	rm -f $(JUNK) *.sys

semiclean:
	rm -f $(JUNK)

