*	$Id: autochar.sp,v 1.1 1999/01/19 09:04:21 ryu Exp $

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

*	Simple Inverter

.subckt inverter in out
+	nl=0.6
+	nw=5.0
+	pl=0.6
+	pw=10.0
mn0 out in 0	0   nch l=nl w=nw
mp1 out in vdd	vdd pch l=pl w=pw
.ends


*	Simple Buffer
.subckt buffer in out
+	nl=0.6
+	nw=5.0
+	pl=0.6
+	pw=10.0
+	taper=3
mn0 in1 in 0	0   nch l=nl w=nw       
mp1 in1 in vdd	vdd pch l=pl w=pw       
mn2 out in1 0	0   nch l=nl w='taper*nw'
mp3 out in1 vdd	vdd pch l=pl w='taper*pw'
.ends


*	Simple Buffer with Infinite drive
.subckt ebuffer in out
+	nl=0.6
+	nw=5.0
+	pl=0.6
+	pw=10.0
+	taper=3
mn0 in1 in 0	0   nch l=nl w=nw       
mp1 in1 in vdd	vdd pch l=pl w=pw       
mn2 in2 in1 0	0   nch l=nl w='taper*nw'
mp3 in2 in1 vdd	vdd pch l=pl w='taper*pw'
* FO=3 Load
xload1 in2 NC1 buffer M=3
* infinite drive
ebuf out 0 in2 0 +1
.ends


*	Resistive "Buffer"
.subckt resbuffer in out
+	R=1K
rbuf in out R
.ends


*	Short "buffer"
.subckt shortbuf in out
vshort in out 0
.ends


*	Infinite drive buffer with slew rate parameter using RC
*	Input must be an ideal pulse.
*	to control the edge.
.subckt slewbuffer in out
+	rslew=1k
+	slew=slewrate		$ default from global param slewrate
+	start=slew_start	$ default from global param slew_start
+	end=slew_end		$ default from global param slew_end
.param cslew='abs(slew/(rslew*(log(start)-log(end))))'
rbuf in out1 rslew
cbuf out1 0 cslew
* infinite drive
ebuf out 0 out1 0 +1
.ends

