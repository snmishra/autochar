#	$Id: and4.spec,v 1.5 1999/06/08 14:43:36 ryu Exp $

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
$celldata{"$cellname:cellprop:cell_footprint"}		= q/"and4"/;
$celldata{"$cellname:termprop:out:function"}		= q/"(in0 in1 in2 in3)"/;


#------	LOAD DELAY -------------------------------------------------------------

$sim_type		= 'load_delay';
$buffer{'default'}	= 'slewbuffer';
$load{'default'}	= 'cap:100ff';
$lu_table_name		= 'slew_cload';

&autochar ('non_inverting', 'in0', 'out', tie_high, '.*');
&autochar ('non_inverting', 'in1', 'out', tie_high, '.*');
&autochar ('non_inverting', 'in2', 'out', tie_high, '.*');
&autochar ('non_inverting', 'in3', 'out', tie_high, '.*');


#------	INPUT CAPACITANCE CHARACTERIZATION -------------------------------------

$sim_type		= 'input_cap';
$buffer{'default'}	= 'buffer';
$cstart			= '10fF';
$cmin			= '1fF';
$cmax			= '1pF';
$load{'default'}	= 'none';

&autochar ('.*');


1;
