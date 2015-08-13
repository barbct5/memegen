CURDIR := $(shell pwd)

PROJECT = memegen

C_SRC_OUTPUT ?= $(CURDIR)/../priv/$(PROJECT)

CC=cc
CFLAGS=`pkg-config --cflags MagickWand` -g -Wall -pg
LDFLAGS=`pkg-config --libs MagickWand`

.PHONY: clean

$(C_SRC_OUTPUT): memegen.c
	$(CC) -o $@ $< $(CFLAGS) $(LDFLAGS)

clean:
	@rm -f $(C_SRC_OUTPUT)
