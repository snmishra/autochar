*	$Id: ttlh,v 1.4 1999/01/19 08:15:10 ryu Exp ryu $

*	Copyright (C) 1999 Robert K. Yu
*	email: robert@yu.org

*	This file is part of Autochar.

*	Autochar is free software; you can redistribute it and/or modify
*	it under the terms of the GNU General Public License as published by
*	the Free Software Foundation; either version 2, or (at your option)
*	any later version.

*	Autochar is distributed in the hope that it will be useful,
*	but WITHOUT ANY WARRANTY; without even the implied warranty of
*	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*	GNU General Public License for more details.

*	You should have received a copy of the GNU General Public License
*	along with Autochar; see the file COPYING.  If not, write to the
*	Free Software Foundation, Inc., 59 Temple Place - Suite 330,
*	Boston, MA 02111-1307, USA.


*	Sample hspice include file to read
*	in hspice models, library, and conditions.

*	ttlh :=
*	    t ypical N
*	    t ypical P
*	    l ow Vdd
*	    h igh temperature

.lib     /people/ryu/src/autochar-1.5.6/tech/tsmc35/lib/define.sp defaults
.lib     /people/ryu/src/autochar-1.5.6/tech/tsmc35/lib/define.sp low_voltage
.lib	 /people/ryu/src/autochar-1.5.6/tech/tsmc35/lib/define.sp high_temp
.lib     /people/ryu/src/autochar-1.5.6/tech/tsmc35/lib/define.sp supplies

.include /people/ryu/src/autochar-1.5.6/tech/tsmc35/lib/models.sp
