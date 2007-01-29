* N88W SPICE BSIM3 VERSION 3.1 (HSPICE Level 49) PARAMETERS

* DATE: Nov 16/98
* LOT: n88w                  WAF: 11
* Temperature_parameters=Default
.MODEL NCH NMOS (                                LEVEL   = 49
+VERSION = 3.1            TNOM    = 27             TOX     = 7.9E-9
+XJ      = 1.5E-7         NCH     = 1.7E17         VTH0    = 0.5232192
+K1      = 0.6154629      K2      = 4.397909E-3    K3      = 49.5247378
+K3B     = 4.7261974      W0      = 1.428416E-5    NLX     = 1.990092E-7
+DVT0W   = 0              DVT1W   = 5.3E6          DVT2W   = -0.032
+DVT0    = 5.6285572      DVT1    = 0.8617134      DVT2    = -0.0569348
+U0      = 434.5143164    UA      = 1.066678E-10   UB      = 1.842089E-18
+UC      = 6.794094E-11   VSAT    = 1.287889E5     A0      = 0.9907028
+AGS     = 0.2642984      B0      = 1.894576E-6    B1      = 5E-6
+KETA    = 1.06235E-3     A1      = 0              A2      = 1
+RDSW    = 976.0244735    PRWG    = 2.031257E-3    PRWB    = -1E-3
+WR      = 1              WINT    = 5.506511E-8    LINT    = 2.410167E-9
+XL      = -5E-8          XW      = 0              DWG     = -1.243637E-8
+DWB     = 5.537948E-9    VOFF    = -0.1310071     NFACTOR = 0.9944094
+CIT     = 0              CDSC    = 1.527511E-3    CDSCD   = 0
+CDSCB   = 0              ETA0    = 1.520266E-3    ETAB    = 0
+DSUB    = 0.1067061      PCLM    = 0.8764469      PDIBLC1 = 0.5431391
+PDIBLC2 = 4.15356E-3     PDIBLCB = 0              DROUT   = 0.996452
+PSCBE1  = 7.253118E9     PSCBE2  = 5E-10          PVAG    = 0.1772609
+DELTA   = 0.01           MOBMOD  = 1              PRT     = 0
+UTE     = -1.5           KT1     = -0.11          KT1L    = 0
+KT2     = 0.022          UA1     = 4.31E-9        UB1     = -7.61E-18
+UC1     = -5.6E-11       AT      = 3.3E4          WL      = 0
+WLN     = 1              WW      = 0              WWN     = 1
+WWL     = 0              LL      = 0              LLN     = 1
+LW      = 0              LWN     = 1              LWL     = 0
+CAPMOD  = 2              CGDO    = 3.97E-10       CGSO    = 3.97E-10
+CGBO    = 0              CJ      = 9.231271E-4    PB      = 0.8509074
+MJ      = 0.3818435      CJSW    = 1.840483E-10   PBSW    = 0.9887463
+MJSW    = 0.1583859      PVTH0   = -0.0115229     PRDSW   = -139.443262
+PK2     = 3.497665E-4    WKETA   = -1.09799E-3    LKETA   = -7.09023E-3     )
*
.MODEL PCH PMOS (                                LEVEL   = 49
+VERSION = 3.1            TNOM    = 27             TOX     = 7.9E-9
+XJ      = 1.5E-7         NCH     = 1.7E17         VTH0    = -0.5773342
+K1      = 0.6851522      K2      = -0.015814      K3      = 54.9959774
+K3B     = -6.392933      W0      = 1.353397E-5    NLX     = 3.259423E-8
+DVT0W   = 0              DVT1W   = 5.3E6          DVT2W   = -0.032
+DVT0    = 1.8077644      DVT1    = 0.7116117      DVT2    = -0.1942173
+U0      = 122.0322683    UA      = 1.131015E-9    UB      = 1.238597E-18
+UC      = -4.36690E-11   VSAT    = 1.254613E5     A0      = 0.9768805
+AGS     = 0.2600292      B0      = 1.946103E-6    B1      = 5E-6
+KETA    = -0.0183802     A1      = 0              A2      = 1
+RDSW    = 1.740457E3     PRWG    = 0.0187585      PRWB    = -1E-3
+WR      = 1              WINT    = 4.805045E-8    LINT    = 7.784353E-9
+XL      = -5E-8          XW      = 0              DWG     = -1.599628E-8
+DWB     = -2.345079E-9   VOFF    = -0.132244      NFACTOR = 1.2424817
+CIT     = 0              CDSC    = 1.413317E-4    CDSCD   = 0
+CDSCB   = 0              ETA0    = 0.262249       ETAB    = -3.889763E-3
+DSUB    = 0.6766373      PCLM    = 1.1752302      PDIBLC1 = 4.866975E-3
+PDIBLC2 = 9.081719E-3    PDIBLCB = 2.37525E-3     DROUT   = 0
+PSCBE1  = 2.01277E10     PSCBE2  = 8.854846E-9    PVAG    = 1.1037883
+DELTA   = 0.01           MOBMOD  = 1              PRT     = 0
+UTE     = -1.5           KT1     = -0.11          KT1L    = 0
+KT2     = 0.022          UA1     = 4.31E-9        UB1     = -7.61E-18
+UC1     = -5.6E-11       AT      = 3.3E4          WL      = 0
+WLN     = 1              WW      = 0              WWN     = 1
+WWL     = 0              LL      = 0              LLN     = 1
+LW      = 0              LWN     = 1              LWL     = 0
+CAPMOD  = 2              CGDO    = 4.73E-10       CGSO    = 4.73E-10
+CGBO    = 0              CJ      = 8.512763E-4    PB      = 0.99
+MJ      = 0.5834851      CJSW    = 2.199595E-10   PBSW    = 0.99
+MJSW    = 0.3015142      PVTH0   = 7.748955E-3    PRDSW   = -250.1583
+PK2     = -2.868919E-4   WKETA   = 3.674392E-3    LKETA   = -0.010084       )
*
