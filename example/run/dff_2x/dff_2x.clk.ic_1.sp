*	$Id$

*	DO NOT EDIT.  This file generated automagically.
*	Created: Sun Jan  9  3:27:05 US/Pacific 2000
*	User: ryu

*	Char:	Input Capacitance Characterization
*	Input:	"clk"

*--- SETUP ---------------------------------------------------
.include '/people/ryu/src/autochar-1.5.5/tech/tsmc35/include/ttlh.sp'
.include 'dff_2x.sp'
.include /people/ryu/src/autochar-1.5.5/tech/tsmc35/lib/autochar.sp
.options
+	optlst	= 1
+	post	= 1
.model optmod opt
.param ceq = optcap('10fF', '1fF', '1pF')

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
+	input0	$ clk:i
+	gnd	$ clk_n:i
+	dff_2x

*--- LOADS ---------------------------------------------------
ceff input1 0 ceq

*--- MEASURE -------------------------------------------------
.option autostop
.measure tran dut_r trig=v(in0) val='vhigh/2' rise=1
+	targ=v(input0) val='vhigh/2' rise=1
.measure tran dut_f trig=v(in0) val='vhigh/2' fall=1
+	targ=v(input0) val='vhigh/2' fall=1
.measure tran dut_delay param='(dut_r + dut_f)/2.0'
.measure tran cap_r trig=v(in1) val='vhigh/2' rise=1
+	targ=v(input1) val='vhigh/2' rise=1
.measure tran cap_f trig=v(in1) val='vhigh/2' fall=1
+	targ=v(input1) val='vhigh/2' fall=1
.measure tran cap_delay param='(cap_r + cap_f)/2.0'
.measure tran opterror param='abs(dut_delay - cap_delay)' goal=0

*--- TRANSIENT -----------------------------------------------
.trans 5ps '2*period' sweep
+	optimize=optcap
+	results=opterror
+	model=optmod


* Final value:
.alter
.trans 5ps '2*period'
.measure tran ceff param='ceq'
.end
