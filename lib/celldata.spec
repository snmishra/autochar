#	$Id: celldata.spec,v 1.11 1999/07/28 14:55:31 ryu Exp $

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

#------	CELL DATA --------------------------------------------------------------

$cellname = 'xor3';

# Any cell property is of the form:
# $celldata{"$cellname:cellprop:<propname>"} = <propvalue> ;
$celldata{"$cellname:cellprop:area"} = 10;

# A special property with the propname "section" will
# simple output that section verbatim.
# $celldata{"$cellname:cellprop:section"} = q% ... %;

# Any terminal property is of the form:
# $celldata{"$cellname:termprop:<termname>:<propname>"} = <propvalue> ;
$celldata{"$cellname:termprop:out:function"} = 'in0 ^ in1 ^ in2';


1;
