#	$Id: clock_enable.spec,v 1.6 1999/07/28 14:55:42 ryu Exp $

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

#------	CLOCK ENABLE SETUP/HOLD TIME CHARACTERIZATION --------------------------


#-------------------------------------------------------------------------------
#	The syntax are the same as the Perl language.  Any
#	valid Perl expression can be used.  In fact, this file is
#	executed directly, so the order of the definitions is
#	important:  Be sure the '&autochar' command, which is actually
#	a subroutine call to the function 'autochar', is called after
#	the necessary definitions are made.
#-------------------------------------------------------------------------------

# Any of the global defaults may be changed here.  See
# $AUTOCHAR/lib/defaults.pl for a list of what they are.

# $spice_cmd		= 'hspice';
# $techpath		= '/path/to/spice/libraries';
# $spice_corner		= 'hspice.ttlh';
# $spice_include	= '.include /some/special/include.file';
# $scale_cload		= 0.66e-15;
# $scale_delay		= 0.060e-9;
# $trans_period		= '2ns';
# etc.


#-------------------------------------------------------------------------------
# Specify the characterization type.

$sim_type	= 'clock_enable';


#-------------------------------------------------------------------------------
# Specify the name of the spice subckt and the file containing
# the spice subckt.

$cellname	= 'dff';
$spice_netlist	= 'dff.sp';


#-------------------------------------------------------------------------------
# List of the terms to the cell.  Order is unimportant.
# Each name is prefixed by a ":x" letter to indicate type:
#	:i	= input
#	:o	= output
#	:b	= biput
#	:v	= vdd supply
#	:g	= gnd

# Declare the list manually
@termlist	= (
    'd:i',
    'clk:i',
    'q:o',
);


# Alternatively, get the term definition from other netlist.
# @termlist	= &read_spice_terms ("filename", $cellname);


#-------------------------------------------------------------------------------
# Define input buffers.  The name of the buffer is a two-port subckt
# that will be placed between the input pulse source and the input
# term being characterized.  Typically, this is a buffer of some sort.
# If 'none' is specified, then no buffer will be added.

$buffer{'d'}		= 'buf';
$buffer{'clk'}		= 'buf';
# $buffer{'in3'}	= 'none';

# Define any special differential inputs.  For example,
# in0 and in1 are defined as a differential input pair,
# with in1 being the reference.
# $differential{'in0'}	= 'in1';

# Define any special equivalent inputs.  For example,
# in0 and in1 are defined as a equivalent input pair,
# with in1 being the reference.
# $equivalent{'in0'}	= 'in1';


#-------------------------------------------------------------------------------
# Define the output loads.

# Specify the loads for the output(s) that are not being characterized.
# If 'none' is specified, then no output loading is added.  Use
# the words 'cap:', 'res:', or 'subckt:' to indicate an output load that
# is an ideal capacitor, an ideal resistor, or a one-port spice subckt.

$load{'default'}	= 'none';
$load{'q'}		= 'cap:10ff';
# $load{'out1'}		= 'cap:10ff'; 
# $load{'out1'}		= 'res:1K'; 
# $load{'out1'}		= 'subckt:buf_4x'; 


#-------------------------------------------------------------------------------
# Define the setup and hold constraints.

# Define the relative input parameter variation
# and relative output results function variance for convergence.
# See the hspice 'Optimization' chapter for details.
$relin		= 0.001;
$relout		= 0.001;

# Define the percentage to use to determine pass/fail:
# if the voltage of the internal node is >= the specified percentage
# of its final value, then it is said to be passing.  If
# it is < the given percentage of its final value, then
# it is said to be failing.  The measurement of the internal
# node is made when the clock is at the specified percent
# of its final value.
$criterion_percent	= 0.8;
$clock_percent		= 0.8;

# Define the range of minimum and maximum setup values allowed.
# Setup time is defined positive before the clock.
@setup_range		= ('0', '1ns');

# Define the range of minimum and maximum hold values allowed.
# Hold time is defined positive after the clock.
@hold_range		= ('0', '1ns');


#-------------------------------------------------------------------------------
# Characterization command.  The general form is:
#	&autochar ( <d>, <cetype>, <ce>, <clktype>, <clk>, <qtype>, <q>, <ctype>, <c>,
#		[ <tie>, <unused>+] );
#
#	<d>		= name of the flop data input term
#	<cetype>	= either 'active_high' or 'active_low' clock edges
#	<ce>		= name of the flop clock enable term
#	<clktype>	= either 'rising' or 'falling' clock edges
#	<clk>		= name of the flop clock term
#	<qtype>		= either 'inverting' or 'non_inverting' w.r.t. d
#	<q>		= name of the flop data output term
#	<ctype>		= either 'inverting' or 'non_inverting' w.r.t. d
#	<c>		= name of the internal criterion node
#
#	Optional:
#	<tie>	= how to tie the other inputs, either 'tie_high' or 'tie_low'
#	<unused>= name(s) of the inputs to be tied.  These are regular
#		  perl expresssions.  Be sure to write brackets [ and ]
#		  as \[ and \], respectively.  < and > are ok.
#

# characterize all inputs
&autochar (
    'd',
    'active_high',	'ce',
    'rising',		'clk',
    'non_inverting',	'q',
    'inverting',	'n10');


#-------------------------------------------------------------------------------
# In some cases, it is desirable to skip the characterization of certain arcs
# and to copy the data from another set of arcs instead.  The general form is:
#	&copychar (<cetype>, <ce>, <clktype>, <clk>, <refce>, <refclk>);

# &copychar (
    'active_high',	'ce',
    'falling',		'ph1_b',
    'ce', 'ph1');


# Must return a value to make perl happy.
1;
