#	$Id: clkbuf.spec,v 1.3 1999/01/21 06:35:11 ryu Exp $

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
$celldata{"$cellname:cellprop:cell_footprint"}		= q/"clkbuf"/;


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
$buffer{'d_bar'}	= 'ebuffer';
$buffer{'ph1'}		= 'ebuffer';
$differential{'ph1_b'}	= 'ph1';
$differential{'ph2'}	= 'ph1';
$equivalent{'ph2_b'}	= 'ph1';
$load{'default'}	= 'cap:100ff';
$relin			= 0.001;
$relout			= 0.001;
$criterion_percent	= 0.8;
$clock_percent		= 0.8;
@setup_range		= ('0', '0.5ns');
@hold_range		= ('-0.5ns', '0');
$lu_table_name		= 'slew';

&autochar (
    'd_bar',
    'rising',		'ph1',
    'inverting',	'q',
    'non_inverting',	'internal',
    tie_low,		'scanmode');

&copychar('d_bar', 'falling', 'ph1_b', 'd_bar', 'ph1');


#------ CLOCK ENABLE SETUP/HOLD ------------------------------------------------

$sim_type		= 'clock_enable';
$buffer{'d_bar'}	= 'ebuffer';
$buffer{'en'}		= 'ebuffer';
$buffer{'ph1'}		= 'ebuffer';
$differential{'ph1_b'}	= 'ph1';
$differential{'ph2'}	= 'ph1';
$equivalent{'ph2_b'}	= 'ph1';
$load{'default'}	= 'cap:100ff';
$relin			= 0.001;
$relout			= 0.001;
$criterion_percent	= 0.8;
$clock_percent		= 0.8;
@setup_range		= ('0', '0.5ns');
@hold_range		= ('-0.5ns', '0');

&autochar (
    'd_bar',
    'active_high',		'en',
    'rising',			'ph1',
    'inverting',		'q',
    'non_inverting',		'internal',
    tie_low,			'scanmode');

&copychar(
    'active_high',	'en',
    'falling',		'ph1_b',
    'en', 'ph1');


#------	CLOCK->Q LOAD DELAY CHARACTERIZATION -----------------------------------

$sim_type		= 'clock_q';
$load{'default'}	= 'cap:100ff';
$lu_table_name		= 'cload';

&autochar ('d_bar',
    'rising', 'ph1',
    'inverting', 'q',
    tie_low, 'sbus<1>', 'sbus<3>', 'sbus<5>', 'sbus<7>');

&copychar('falling', 'ph1_b', 'q', 'ph1', 'q');


1;
