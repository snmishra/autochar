#	$Id: clock_q.spec,v 1.12 1999/07/28 14:55:42 ryu Exp $

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

#------	CLOCK->Q LOAD DELAY CHARACTERIZATION -----------------------------------


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

$sim_type	= 'clock_q';


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
    'in0:i',
    'in1:i',
    'in2:i',
    'out:o',
);


# Alternatively, get the term definition from other netlist.
# @termlist	= &read_spice_terms ("filename", $cellname);


#-------------------------------------------------------------------------------
# Define input buffers.  The name of the buffer is a two-term subckt
# that will be placed between the input pulse source and the input
# term being characterized.  Typically, this is a buffer of some sort.
# If 'none' is specified, then no buffer will be added.

$buffer{'default'}	= 'buf_3x';
$buffer{'in2'}		= 'buf_4x';
# $buffer{'in3'}	= 'none';


# Define any special differential inputs.  For example,
# in0 and in1 are defined as a differential input pair,
# with in1 being the reference.
# $differential{'in0'}	= 'in1';

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

# Vary the cload to the output being characterized.
# @cload	= &vary_list(<start>, <incr>, <N>, <units>);
@cload		= &vary_list(10, 10, 5, 'ff');

# Or specify the explicit list of cload values
# @cload	= ('10ff', '20ff', '30ff');

# Specify the loads for the output(s) that are not being characterized.
# If 'none' is specified, then no output loading is added.  Use
# the words 'cap:', 'res:', or 'subckt:' to indicate an output load that
# is an ideal capacitor, an ideal resistor, or a one-port spice subckt.

$load{'default'}	= 'none';
# $load{'out1'}		= 'cap:10ff'; 
# $load{'out1'}		= 'res:1K'; 
# $load{'out1'}		= 'subckt:buf_4x'; 


#-------------------------------------------------------------------------------
# Characterization command.  The general form is:
#	&autochar ( <d>, <clktype>, <clk>, <qtype>, <q>, [ <tie>, <unused>+] );
#
#	<d>		= name of the flop data input term
#	<clktype>	= either 'rising' or 'falling' clock edges
#	<clk>		= name of the flop clock term
#	<qtype>		= either 'inverting' or 'non_inverting' w.r.t. d
#	<q>		= name of the flop data output term
#
#	Optional:
#	<tie>	= how to tie the other inputs, either 'tie_high' or 'tie_low'
#	<unused>= name(s) of the inputs to be tied.  These are regular
#		  perl expresssions.  Be sure to write brackets [ and ]
#		  as \[ and \], respectively.  < and > are ok.
#

&autochar ('d', 'rising', 'clk', 'non_inverting', 'q');


#-------------------------------------------------------------------------------
# In some cases, it is desirable to skip the characterization of certain arcs
# and to copy the data from another set of arcs instead.  The general form is:
#	&copychar (<clktype>, <clk>, <q>, <ref_clk>, <ref_q>);

# &copychar ('falling', 'ph1_b', 'q', 'ph1', 'q');


# Must return a value to make perl happy.
1;
