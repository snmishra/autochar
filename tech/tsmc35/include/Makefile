#	$Id: Makefile,v 1.6 1999/02/07 02:48:58 ryu Exp $

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

# Set TECHDIR here to over-ride environment variable.
#TECHDIR	=

CORNERS	= ttlh

default:
	@echo "Usage: make <target>"
	@echo "% make install"
	@echo "% make clean"

install:
	@for i in $(CORNERS); \
	do \
	    echo Creating $$i.sp ... ; \
	    sed -e "s#TECHDIR#$(TECHDIR)#g" $$i > $$i.sp ; \
	done

clean:
	@for i in $(CORNERS); \
	do \
	    echo Removing $$i.sp ... ; \
	    rm -f $$i.sp ; \
	done
