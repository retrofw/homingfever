CHAINPREFIX := /opt/mipsel-linux-uclibc
CROSS_COMPILE := $(CHAINPREFIX)/usr/bin/mipsel-linux-

CC = $(CROSS_COMPILE)gcc
CXX = $(CROSS_COMPILE)g++
STRIP = $(CROSS_COMPILE)strip

SYSROOT     := $(shell $(CXX) --print-sysroot)
SDL_CFLAGS  := $(shell $(SYSROOT)/usr/bin/sdl-config --cflags)
SDL_LIBS    := $(shell $(SYSROOT)/usr/bin/sdl-config --libs)

CFLAGS		:= $(SDL_CFLAGS) -DNO_FRAMELIMIT -DSCREEN_SCALE=1 -DHOME_DIR
LDFLAGS		:= $(SDL_LIBS) -lm

TARGET		?= homingfever/homingfever.dge
SRCDIR		:= src
OBJDIR		:= /tmp/homingfever.obj

SRC		:= $(wildcard $(SRCDIR)/*.c)
OBJ		:= $(SRC:$(SRCDIR)/%.c=$(OBJDIR)/%.o)

ifdef DEBUG
	CFLAGS	+= -Wall -Wextra -Werror -ggdb -pedantic -std=gnu89 -DDEBUG
else
	CFLAGS	+= -O2
endif

.PHONY: all opk clean

all: $(TARGET)

$(TARGET): $(OBJ)
	$(CC) $(CFLAGS) $^ $(LDFLAGS) -o $@
ifndef DEBUG
	$(STRIP) $@
endif

$(OBJ): $(OBJDIR)/%.o: $(SRCDIR)/%.c | $(OBJDIR)
	$(CC) -c $(CFLAGS) $< -o $@

$(OBJDIR):
	mkdir -p $@

clean:
	rm -Rf $(TARGET) $(OBJDIR)

ipk: all
	@rm -rf /tmp/.homingfever-ipk/ && mkdir -p /tmp/.homingfever-ipk/root/home/retrofw/games/homingfever /tmp/.homingfever-ipk/root/home/retrofw/apps/gmenu2x/sections/games
	@cp -r homingfever/data homingfever/homingfever.dge homingfever/homingfever.lnk homingfever/homingfever.man.txt homingfever/homingfever.png /tmp/.homingfever-ipk/root/home/retrofw/games/homingfever
	@cp homingfever/homingfever.lnk /tmp/.homingfever-ipk/root/home/retrofw/apps/gmenu2x/sections/games
	@sed "s/^Version:.*/Version: $$(date +%Y%m%d)/" homingfever/control > /tmp/.homingfever-ipk/control
	@cp homingfever/conffiles /tmp/.homingfever-ipk/
	@tar --owner=0 --group=0 -czvf /tmp/.homingfever-ipk/control.tar.gz -C /tmp/.homingfever-ipk/ control conffiles
	@tar --owner=0 --group=0 -czvf /tmp/.homingfever-ipk/data.tar.gz -C /tmp/.homingfever-ipk/root/ .
	@echo 2.0 > /tmp/.homingfever-ipk/debian-binary
	@ar r homingfever/homingfever.ipk /tmp/.homingfever-ipk/control.tar.gz /tmp/.homingfever-ipk/data.tar.gz /tmp/.homingfever-ipk/debian-binary

opk: all
	mksquashfs \
	homingfever/default.retrofw.desktop \
	homingfever/homingfever.dge \
	homingfever/homingfever.man.txt \
	homingfever/homingfever.png	\
	homingfever/homingfever.opk \
	-all-root -noappend -no-exports -no-xattrs
