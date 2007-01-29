#	$Id: dff.spec,v 1.5 1999/07/28 14:47:51 ryu Exp ryu $

#	Copyright (C) 1999 Robert K. Yu
#	email: robert@yu.org

#	This file is part of Autochar.

#	Autochar is free software; you can redistribute it and/or modify
#	it under the terms of the GNU General Public License as published by
#	the Free Software Foundation; either version 2, or (at your option)
#	any later version.

#	Autochar is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#	GNU General Public License for more details.

#	You should have received a copy of the GNU General Public License
#	along with Autochar; see the file COPYING.  If not, write to the
#	Free Software Foundation, Inc., 59 Temple Place - Suite 330,
#	Boston, MA 02111-1307, USA.

#------	CELL DATA --------------------------------------------------------------

$spice_netlist	= $cellname . '.sp';
@termlist	= &read_spice_terms ($spice_netlist, $cellname);

$celldata{"$cellname:cellprop:area"}			= 0;
$celldata{"$cellname:cellprop:cell_footprint"}		= q/"dff"/;
$celldata{"$cellname:termprop:q:max_capacitance"}	= q/cap_factor * cap_unit * 2/ ;
$celldata{"$cellname:termprop:q:max_fanout"}		= q/max_fanout_num/ ;

# synopsys
$celldata{"$cellname:termprop:q:function"}		= q/"IQ"/ ;
$celldata{"$cellname:termprop:q:internal_node"}		= q/"Q"/ ;
#$celldata{"$cellname:termprop:q_bar:function"}		= q/"IQN"/ ;
#$celldata{"$cellname:termprop:q_bar:internal_node"}	= q/"QN"/ ;

# insert this section for q, q_bar
#$celldata{"$cellname:cellprop:section"}			= q%
#	ff ("IQ","IQN") {
#	    next_state : "d";
#	    clocked_on : "clk";
#	}
#	statetable ( "  d   clk ", " Q  QN") {
#	    table  : "  -   ~R  : - - :  N   N, \
#			H/L  R  : - - : H/L L/H";
#	}% ;

# insert this section for q only
$celldata{"$cellname:cellprop:section"}			= q%
	ff ("IQ") {
	    next_state : "d";
	    clocked_on : "clk";
	}
	statetable ( "  d   clk ", " Q ") {
	    table  : "  -   ~R  : - - :  N, \
			H/L  R  : - - : H/L";
	}% ;


#------	INPUT CAPACITANCE CHARACTERIZATION -------------------------------------

$sim_type		= 'input_cap';
$buffer{'default'}	= 'buffer';
$cstart			= '10fF';
$cmin			= '1fF';
$cmax			= '1pF';
$load{'default'}	= 'none';

&autochar ('.*');


#------ SETUP/HOLD -------------------------------------------------------------

$sim_type		= 'setup_hold';
$buffer{'d'}		= 'ebuffer';
$buffer{'clk'}		= 'ebuffer';
$differential{'clk_n'}	= 'clk';
$load{'default'}	= 'cap:100ff';

$criterion_percent	= 0.8;
$clock_percent		= 0.8;

if ($spice_type eq 'smartspice') {
    $window		= 600;
    $iterations		= 20;
    $resolution		= 5;
    $setup_hold_scale	= '1e-12';
} else {
    $relin		= 0.001;
    $relout		= 0.001;
    @setup_range	= ('0', '1.5ns');
    @hold_range		= ('-1.5ns', '0');
}

$lu_table_name		= 'slew';

&autochar ('d',
    'rising', 'clk',
    'non_inverting', 'q',
    'inverting', 'mout');

&copychar('d', 'falling', 'clk_n', 'd', 'clk');


#------	CLOCK->Q LOAD DELAY CHARACTERIZATION -----------------------------------

$sim_type		= 'clock_q';
$load{'default'}	= 'cap:100ff';
$lu_table_name		= 'cload';

&autochar ('d',
    'rising', 'clk',
    'non_inverting', 'q');

&copychar('falling', 'clk_n', 'q', 'clk', 'q');


1;
