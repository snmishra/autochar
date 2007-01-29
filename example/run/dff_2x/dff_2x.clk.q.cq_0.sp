*	$Id$

*	DO NOT EDIT.  This file generated automagically.
*	Created: Sun Jan  9  3:27:05 US/Pacific 2000
*	User: ryu

*	Char:	D-Flop Clock-Q Characterization
*	Data:	"d"
*	Clock:	"clk"
*	Q:	"q"

*--- SETUP ---------------------------------------------------
.include '/people/ryu/src/autochar-1.5.5/tech/tsmc35/include/ttlh.sp'
.include 'dff_2x.sp'
.include /people/ryu/src/autochar-1.5.5/tech/tsmc35/lib/autochar.sp
.options
+	opts
+	list
+	nopage
+	method	= gear
+	lvltim	= 2
+	relq	= 2.0e-3
+	acct	= 1
+	post	= 1
.param setup = 'pwidth'
.param cload = '2.5e-15'

*--- INPUTS --------------------------------------------------
vclk0 vclk0 0 pulse (
+	'0'
+	'vhigh'
+	'1ns'
+	'trise'
+	'tfall'
+	'pwidth'
+	'period')
vclk1 vclk1 0 pulse (
+	'0'
+	'vhigh'
+	'1ns'
+	'trise'
+	'tfall'
+	'pwidth'
+	'period')
vd0 vd0 0 pulse (
+	'0'
+	'vhigh'
+	'1ns+trise+2*pwidth+tfall-setup'
+	'trise'
+	'tfall'
+	'3*period'
+	'4*period')
vd1 vd1 0 pulse (
+	'vhigh'
+	'0'
+	'1ns+trise+2*pwidth+tfall-setup'
+	'trise'
+	'tfall'
+	'3*period'
+	'4*period')

*--- TEST CIRCUIT --------------------------------------------
xdbuf0 vd0 d0 ebuffer
xdbuf1 vd1 d1 ebuffer
xclkbuf0 vclk0 clk0 ebuffer
xclkbuf1 vclk1 clk1 ebuffer
xflop0
+	q0	$ q:o
+	d0	$ d:i
+	clk0	$ clk:i
+	diff_0	$ clk_n:i
+	dff_2x
xflop1
+	q1	$ q:o
+	d1	$ d:i
+	clk1	$ clk:i
+	diff_1	$ clk_n:i
+	dff_2x
e0 diff_0 0 clk0 vdd -1
e1 diff_1 0 clk1 vdd -1

*--- LOADS ---------------------------------------------------
cload0 q0 0 cload
cload1 q1 0 cload

*--- MEASURE -------------------------------------------------
.option autostop

* Measure clock->q time:
.measure tran clk_q_lh trig= v(clk0) val='0+0.5*vhigh' rise=1
+	targ=v(q0) val='0+0.5*vhigh' rise=1
.measure tran clk_q_hl trig= v(clk1) val='0+0.5*vhigh' rise=1
+	targ=v(q1) val='0+(1-0.5)*vhigh' fall=1
.measure tran risetime trig= v(q0) val='0+0.1*vhigh' rise=1
+	targ=v(q0) val='0+0.9*vhigh' rise=1
.measure tran falltime trig= v(q1) val='0+(1-0.1)*vhigh' fall=1
+	targ=v(q1) val='0+(1-0.9)*vhigh' fall=1

*--- TRANSIENT -----------------------------------------------
.trans 5ps '2*period' start='1ns+pwidth'

*--- ALTER ---------------------------------------------------
.alter
.param cload = '1e-14'

.alter
.param cload = '2.5e-14'

.alter
.param cload = '5e-14'

.alter
.param cload = '7.5e-14'

.alter
.param cload = '1.2e-13'

.end
