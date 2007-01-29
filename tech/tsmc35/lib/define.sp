*	$Id: define.sp,v 1.2 2000/01/04 06:05:33 ryu Exp $

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


********************************************************************************
*	DEFAULTS
********************************************************************************
.lib defaults
.param
+	trise	= 200ps
+	tfall	= 200ps
+	period	= 6ns
+	pwidth	= 3ns

.options
+	scale	= 1.0e-6

.endl


********************************************************************************
*	VOLTAGE
********************************************************************************
.lib low_voltage
.param
+	vhigh = '3.3*0.9'
+	vlow = 0
+	vmidpoint = '(vhigh+vlow)/2'
.endl

.lib nominal_voltage
.param
+	vhigh = '3.3'
+	vlow = 0
+	vmidpoint = '(vhigh+vlow)/2'
.endl

.lib high_voltage
.param
+	vhigh = '3.3*1.1'
+	vlow = 0
+	vmidpoint = '(vhigh+vlow)/2'
.endl


********************************************************************************
*	TEMPERATURE
********************************************************************************
.lib low_temp
.temp 0
.endl

.lib nominal_temp
.temp 25
.endl

.lib high_temp
.temp 100
.endl


********************************************************************************
*	SUPPLIES
********************************************************************************
.lib supplies
VVDD VDD 0 dc vhigh
VGND GND 0 dc 0
.global VDD GND
.endl
