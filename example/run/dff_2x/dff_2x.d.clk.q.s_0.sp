*	$Id$

*	DO NOT EDIT.  This file generated automagically.
*	Created: Sun Jan  9  3:27:05 US/Pacific 2000
*	User: ryu

*	Char:	D-Flop Setup Time Characterization
*	Data:	"d"
*	Clock:	"clk"
*	Q:	"q"
*	C:	"mout"
*	Trans:	"lh"

*--- SETUP ---------------------------------------------------
.include '/people/ryu/src/autochar-1.5.5/tech/tsmc35/include/ttlh.sp'
.include 'dff_2x.sp'
.include /people/ryu/src/autochar-1.5.5/tech/tsmc35/lib/autochar.sp
.options
+	optlst	= 1
+	post	= 1
.model optmod opt method=bisection
+	relin = 0.001
+	relout = 0.001
.param setup = optsetup('0', '0', '1.5ns')
.param slewrate = '4.00002e-11'
.param slew_start = '0.1'
.param slew_end = '0.9'

*--- INPUTS --------------------------------------------------
vclk vclk 0 pulse (
+	'0'
+	'vhigh'
+	'1ns+trise/2'
+	'0'
+	'0'
+	'pwidth+trise/2+tfall/2'
+	'period')
vd vd 0 pulse (
+	'0'
+	'vhigh'
+	'1ns+trise+2*pwidth+tfall-setup'
+	'trise'
+	'tfall'
+	'3*period'
+	'4*period')

*--- TEST CIRCUIT --------------------------------------------
xdbuf vd d ebuffer
xclkbuf vclk clk slewbuffer
xflop
+	q	$ q:o
+	d	$ d:i
+	clk	$ clk:i
+	diff_1	$ clk_n:i
+	dff_2x
e1 diff_1 0 clk vdd -1

*--- LOADS ---------------------------------------------------
c0 q 0 100ff

*--- MEASURE -------------------------------------------------
.option autostop
* Measure setup time:
.measure tran setup_lh trig= v(d) val='vhigh/2' cross=1
+	targ=v(clk) val='vhigh/2' rise=2
* Measure clock slew rate:
.measure tran clkslew trig= v(clk) val='0+0.1*vhigh' rise=2
+	targ=v(clk) val='0+0.9*vhigh' rise=2

* Measure internal criterion node:
.measure tran vcrit find v(xflop.mout)
+	when v(clk)='0.8*vhigh' rise=2
.measure tran optpass param='(vhigh-vcrit)/vhigh'
+	goal='0.8'

*--- TRANSIENT -----------------------------------------------
.trans 5ps '2*period' sweep
+	optimize=optsetup
+	results=optpass
+	model=optmod
.trans 5ps '2*period'

* Measure final clock->q time:
.measure tran clk_q trig=v(clk) val='vhigh/2' rise=2
+	targ=v(q) val='vhigh/2' rise=1

* Alter slewrate:
.alter
.param slewrate = '7.99998e-11'
.alter
.param slewrate = '1.2e-10'
.alter
.param slewrate = '1.600002e-10'
.alter
.param slewrate = '3.19998e-10'
.end
