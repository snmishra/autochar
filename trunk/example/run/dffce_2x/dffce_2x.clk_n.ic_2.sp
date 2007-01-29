*	$Id$

*	DO NOT EDIT.  This file generated automagically.
*	Created: Thu Jan 28 21:16:28 1999
*	User: ryu

*	Char:	Input Capacitance Characterization
*	Input:	"clk_n"

*--- SETUP ---------------------------------------------------
.include '/home/ryu/src/autochar/autochar-1.5/tech/tsmc35/include/ttlh.sp'
.include 'dffce_2x.sp'
.include /home/ryu/src/autochar/autochar-1.5/tech/tsmc35/lib/autochar.sp
.param ceq = '10fF'

*--- INPUTS --------------------------------------------------
vin0 in0 0 pulse (
+	'0'
+	'vhigh'
+	'1ns'
+	'trise'
+	'tfall'
+	'pwidth'
+	'period')
vin1 in1 0 pulse (
+	'0'
+	'vhigh'
+	'1ns'
+	'trise'
+	'tfall'
+	'pwidth'
+	'period')

*--- TEST CIRCUIT --------------------------------------------
xbuf0 in0 input0 buffer
xbuf1 in1 input1 buffer
xdut0
+	out_0	$ q:o
+	gnd	$ d:i
+	gnd	$ clk:i
+	input0	$ clk_n:i
+	dffce_2x

*--- LOADS ---------------------------------------------------
ceff input1 0 ceq

*--- MEASURE -------------------------------------------------
.option autostop
.measure tran dut_r delay v(in0) val='vhigh/2' rise=1
+	targ=v(input0) val='vhigh/2' rise=1
.measure tran dut_f delay v(in0) val='vhigh/2' fall=1
+	targ=v(input0) val='vhigh/2' fall=1
.measure tran dut_delay param='(dut_r + dut_f)/2.0'
.measure tran cap_r delay v(in1) val='vhigh/2' rise=1
+	targ=v(input1) val='vhigh/2' rise=1
.measure tran cap_f delay v(in1) val='vhigh/2' fall=1
+	targ=v(input1) val='vhigh/2' fall=1
.measure tran cap_delay param='(cap_r + cap_f)/2.0'
.measure tran opterror param='abs(dut_delay - cap_delay)'

*--- TRANSIENT -----------------------------------------------
.trans 5ps '2*period'
.modif proff prtbl
+	optimize ceq=opt('1fF' '1pF' '10fF')
+	targets opterror=1e-15
+	options avg=0.001
.end
