
.subckt nand2_4x in0 in1 out 

* Begin port declarations
* port input in0
* port input in1
* port output out
* End port declarations

mn0 out in0 n0 gnd nch w=20 l=0.35
mn1 n0 in1 gnd gnd nch w=20 l=0.35
mp2 out in0 vdd vdd pch w=20 l=0.35
mp3 out in1 vdd vdd pch w=20 l=0.35

c1 in0 gnd 10e-15 
c2 in1 gnd 10e-15 
c3 out gnd 20e-15 

.ENDS 
