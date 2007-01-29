#	$Id: Makefile,v 1.6 1999/02/07 02:49:56 ryu Exp $

#	Copyright (C) 1999 Robert K. Yu
#	email: robert@yu.org

#	This file is part of Autochar.

#	Autochar is free software; you can redistribute it and/or modify
#	it under the terms of the GNU General Public License as published by
#	the Free Software Foundation; either version 2, or (at your option)
#	any later version.

#	Autochar is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#	GNU General Public License for more details.

#	You should have received a copy of the GNU General Public License
#	along with Autochar; see the file COPYING.  If not, write to the
#	Free Software Foundation, Inc., 59 Temple Place - Suite 330,
#	Boston, MA 02111-1307, USA.

# Optional:
# AUTOCHAR	= $(HOME)/src/autochar
# PERL		= /usr/bin/perl

INSTALL_DIR	= $(AUTOCHAR)/bin

CSH_FILES	=

PERL_FILES	= autochar.pl \
		  Hspice.pl \
		  Smartspice.pl

SH_FILES	=

CSH_EXE		= $(CSH_FILES:%.csh=$(INSTALL_DIR)/%)
PERL_EXE	= $(PERL_FILES:%.pl=$(INSTALL_DIR)/%)
SH_EXE		= $(SH_FILES:%.sh=$(INSTALL_DIR)/%)

INSTALL_MODE	= 555

# targets

default:
	@echo "Usage: make <target>"
	@echo "% make install"
	@echo "% make clean"

all: install

install: csh_exe perl_exe sh_exe

clean:
	-rm -f $(CSH_EXE) $(PERL_EXE) $(SH_EXE)

csh_exe: $(CSH_EXE)
perl_exe: $(PERL_EXE)
sh_exe: $(SH_EXE)

# pattern rules

$(INSTALL_DIR)/%:%.sh
	install -m $(INSTALL_MODE) $< $@

$(INSTALL_DIR)/%:%.pl
	rm -f $@
	sed -e "s#PERL#$(PERL)#g" $< > $@
	chmod $(INSTALL_MODE) $@

$(INSTALL_DIR)/%:%.csh
	install -m $(INSTALL_MODE) $< $@

