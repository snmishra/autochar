*	$Id$

*	DO NOT EDIT.  This file generated automagically.
*	Created: Sun Jan  9  3:27:08 US/Pacific 2000
*	User: ryu

*	Char:	Load Delay Characterization
*	Type:	"inverting"
*	Input:	"in1"
*	Output:	"out"

*--- SETUP ---------------------------------------------------
.include '/people/ryu/src/autochar-1.5.5/tech/tsmc35/include/ttlh.sp'
.include 'nand2_4x.sp'
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
.param cload = '2.5e-15'
.param slewrate = '4.00002e-11'
.param slew_start = '0.1'
.param slew_end = '0.9'
.param tau = 'slewrate/abs(log(slew_start)-log(slew_end))'

*--- INPUTS --------------------------------------------------
vinr vinr 0 exp (
+	'0'
+	'vhigh'
+	'1ns'
+	'tau'
+	'1ns+1000*tau'
+	'tau')
vinf vinf 0 exp (
+	'vhigh'
+	'0'
+	'1ns'
+	'tau'
+	'1ns+1000*tau'
+	'tau')

*--- TEST CIRCUIT --------------------------------------------
vshortr vinr inputr DC 0
xdut0
+	vdd	$ in0:i
+	inputr	$ in1:i
+	outputf	$ out:o
+	nand2_4x
vshortf vinf inputf DC 0
xdut1
+	vdd	$ in0:i
+	inputf	$ in1:i
+	outputr	$ out:o
+	nand2_4x

*--- LOADS ---------------------------------------------------
cloadr outputr 0 cload
cloadf outputf 0 cload

*--- MEASURE -------------------------------------------------
.option autostop
* Prop delay measurements:
.measure tran tplh trig= v(inputf) val='0+(1-0.5)*vhigh' fall=1
+	targ=v(outputr) val='0+0.5*vhigh' rise=1
.measure tran tphl trig= v(inputr) val='0+0.5*vhigh' rise=1
+	targ=v(outputf) val='0+(1-0.5)*vhigh' fall=1

* Output rise and fall time measurements:
.measure tran risetime trig= v(outputr) val='0+0.1*vhigh' rise=1
+	targ=v(outputr) val='0+0.9*vhigh' rise=1
.measure tran falltime trig= v(outputf) val='0+(1-0.1)*vhigh' fall=1
+	targ=v(outputf) val='0+(1-0.9)*vhigh' fall=1

* Input rise and fall time measurements:
.measure tran inputrise trig= v(inputr) val='0+0.1*vhigh' rise=1
+	targ=v(inputr) val='0+0.9*vhigh' rise=1
.measure tran inputfall trig= v(inputf) val='0+(1-0.1)*vhigh' fall=1
+	targ=v(inputf) val='0+(1-0.9)*vhigh' fall=1

*--- TRANSIENT -----------------------------------------------
.trans 5ps '2*period'

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

.alter
.param slewrate = '7.99998e-11'
.param tau = 'slewrate/abs(log(slew_start)-log(slew_end))'
.param cload = '2.5e-15'

.alter
.param slewrate = '7.99998e-11'
.param tau = 'slewrate/abs(log(slew_start)-log(slew_end))'
.param cload = '1e-14'

.alter
.param slewrate = '7.99998e-11'
.param tau = 'slewrate/abs(log(slew_start)-log(slew_end))'
.param cload = '2.5e-14'

.alter
.param slewrate = '7.99998e-11'
.param tau = 'slewrate/abs(log(slew_start)-log(slew_end))'
.param cload = '5e-14'

.alter
.param slewrate = '7.99998e-11'
.param tau = 'slewrate/abs(log(slew_start)-log(slew_end))'
.param cload = '7.5e-14'

.alter
.param slewrate = '7.99998e-11'
.param tau = 'slewrate/abs(log(slew_start)-log(slew_end))'
.param cload = '1.2e-13'

.alter
.param slewrate = '1.2e-10'
.param tau = 'slewrate/abs(log(slew_start)-log(slew_end))'
.param cload = '2.5e-15'

.alter
.param slewrate = '1.2e-10'
.param tau = 'slewrate/abs(log(slew_start)-log(slew_end))'
.param cload = '1e-14'

.alter
.param slewrate = '1.2e-10'
.param tau = 'slewrate/abs(log(slew_start)-log(slew_end))'
.param cload = '2.5e-14'

.alter
.param slewrate = '1.2e-10'
.param tau = 'slewrate/abs(log(slew_start)-log(slew_end))'
.param cload = '5e-14'

.alter
.param slewrate = '1.2e-10'
.param tau = 'slewrate/abs(log(slew_start)-log(slew_end))'
.param cload = '7.5e-14'

.alter
.param slewrate = '1.2e-10'
.param tau = 'slewrate/abs(log(slew_start)-log(slew_end))'
.param cload = '1.2e-13'

.alter
.param slewrate = '1.600002e-10'
.param tau = 'slewrate/abs(log(slew_start)-log(slew_end))'
.param cload = '2.5e-15'

.alter
.param slewrate = '1.600002e-10'
.param tau = 'slewrate/abs(log(slew_start)-log(slew_end))'
.param cload = '1e-14'

.alter
.param slewrate = '1.600002e-10'
.param tau = 'slewrate/abs(log(slew_start)-log(slew_end))'
.param cload = '2.5e-14'

.alter
.param slewrate = '1.600002e-10'
.param tau = 'slewrate/abs(log(slew_start)-log(slew_end))'
.param cload = '5e-14'

.alter
.param slewrate = '1.600002e-10'
.param tau = 'slewrate/abs(log(slew_start)-log(slew_end))'
.param cload = '7.5e-14'

.alter
.param slewrate = '1.600002e-10'
.param tau = 'slewrate/abs(log(slew_start)-log(slew_end))'
.param cload = '1.2e-13'

.alter
.param slewrate = '3.19998e-10'
.param tau = 'slewrate/abs(log(slew_start)-log(slew_end))'
.param cload = '2.5e-15'

.alter
.param slewrate = '3.19998e-10'
.param tau = 'slewrate/abs(log(slew_start)-log(slew_end))'
.param cload = '1e-14'

.alter
.param slewrate = '3.19998e-10'
.param tau = 'slewrate/abs(log(slew_start)-log(slew_end))'
.param cload = '2.5e-14'

.alter
.param slewrate = '3.19998e-10'
.param tau = 'slewrate/abs(log(slew_start)-log(slew_end))'
.param cload = '5e-14'

.alter
.param slewrate = '3.19998e-10'
.param tau = 'slewrate/abs(log(slew_start)-log(slew_end))'
.param cload = '7.5e-14'

.alter
.param slewrate = '3.19998e-10'
.param tau = 'slewrate/abs(log(slew_start)-log(slew_end))'
.param cload = '1.2e-13'

.end
