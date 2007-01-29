#	$Id: mux2.spec,v 1.4 1999/06/08 14:43:36 ryu Exp $

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
$celldata{"$cellname:cellprop:cell_footprint"}		= q/"mux2"/;
$celldata{"$cellname:termprop:z:function"}		= q/"(in0 sel' + in1 sel)'"/;
$celldata{"$cellname:termprop:z:max_capacitance"}	= q/cap_factor * cap_unit * 2/ ;
$celldata{"$cellname:termprop:z:max_fanout"}		= q/max_fanout_num/ ;


#------	LOAD DELAY -------------------------------------------------------------

$sim_type		= 'load_delay';
$buffer{'default'}	= 'slewbuffer';
$load{'default'}	= 'cap:100ff';
$lu_table_name		= 'slew_cload';

&autochar ('inverting', 'in0', 'z', tie_low, 'sel');
&autochar ('inverting', 'in1', 'z', tie_high, 'sel');
&autochar ('non_inverting', 'sel', 'z', tie_low, 'in1');


#------	INPUT CAPACITANCE CHARACTERIZATION -------------------------------------

$sim_type		= 'input_cap';
$buffer{'default'}	= 'buffer';
$cstart			= '10fF';
$cmin			= '1fF';
$cmax			= '1pF';
$load{'default'}	= 'none';

&autochar ('.*');


1;
