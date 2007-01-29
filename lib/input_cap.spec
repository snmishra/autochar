#	$Id: input_cap.spec,v 1.13 1999/07/28 14:55:42 ryu Exp $

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

#------	INPUT CAPACITANCE CHARACTERIZATION -------------------------------------


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

$sim_type	= 'input_cap';


#-------------------------------------------------------------------------------
# Specify the name of the spice subckt and the file containing
# the spice subckt.

$cellname	= 'nand3_8x';
$spice_netlist	= 'nand3_8x.sp';


#-------------------------------------------------------------------------------
# List of the terms to the cell.  Order is unimportant.
# Each name is prefixed by a ":x" letter to indicate type:
#	.i	= input
#	.o	= output
#	.b	= biput
#	.v	= vdd supply
#	.g	= gnd

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
# Define input buffers.  The name of the buffer is a two-port subckt
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

# Define any special equivalent inputs.  For example,
# in0 and in1 are defined as a equivalent input pair,
# with in1 being the reference.
# $equivalent{'in0'}	= 'in1';


#-------------------------------------------------------------------------------
# Define the input capacitance range values.

$cstart	= '1pF';
$cmin	= '1fF';
$cmax	= '12pF';


#-------------------------------------------------------------------------------
# Define the output loads.

# Specify the loads for the output(s) that are not being characterized.
# If 'none' is specified, then no output loading is added.  Use
# the words 'cap:', 'res:', or 'subckt:' to indicate an output load that
# is an ideal capacitor, an ideal resistor, or a one-term spice subckt.

$load{'default'}	= 'none';
# $load{'out1'}		= 'cap:10ff'; 
# $load{'out1'}		= 'res:1K'; 
# $load{'out1'}		= 'subckt:buf_4x'; 


#-------------------------------------------------------------------------------
# Characterization command.  The general form is:
#	&autochar ( <input>, [ <tie>, <unused>+] );
#
#	<input>	= name or expression of the input to characterize 
#
#	Optional:
#	<tie>	= how to tie the other inputs, either 'tie_high' or 'tie_low'
#	<unused>= name(s) of the inputs to be tied.  These are regular
#		  perl expresssions.  Be sure to write brackets [ and ]
#		  as \[ and \], respectively.
#

# characterize all inputs
&autochar ('.*');

# characterize certain inputs
# &autochar ('in1', tie_high, '.*');


#-------------------------------------------------------------------------------
# In some cases, it is desirable to skip the characterization of certain arcs
# and to copy the data from another set of arcs instead.  The general form is:
#	&copychar (<input>, <ref_input>);

# &copychar ('in0', 'in1');


# Must return a value to make perl happy.
1;
