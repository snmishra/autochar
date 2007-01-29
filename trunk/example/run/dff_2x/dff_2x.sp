*	$Id: dff_2x.sp,v 1.6 1999/01/30 21:06:48 ryu Exp $

.subckt xgate out in gaten gatep
+	wp=4
+	wn=2
m0 in gatep out vdd pch l=0.35 w=wp
m1 in gaten out gnd nch l=0.35 w=wn
.ends

.subckt inv out in
+	wp=12
+	wn=6
m0 out in gnd gnd nch l=0.35 w=wn
m1 out in vdd vdd pch l=0.35 w=wp
.ends

.subckt dff_2x q d clk clk_n
* Begin port declarations
* port output q
* port input d
* port input clk
* port input clk_n
* End port declarations
x1 min d clk_n clk xgate
x2 min mout inv wp=2 wn=1
x3 mout min inv
x4 s mout clk clk_n xgate
x5 s s_n inv wp=2 wn=1
x6 s_n s inv
x7 q s inv
cmin min gnd 5fF
cmout mout gnd 5fF
cs s gnd 5fF
cs_n s_n gnd 5fF
.ends
