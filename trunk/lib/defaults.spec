#	$Id: defaults.spec,v 1.8 2000/04/20 00:10:18 ryu Exp $

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

# GENERAL:

# The type of spice circuit simulator.  Supported types
# are hspice and smartspice.
#$spice_type	= 'smartspice';
$spice_type	= 'hspice';

# The actual command used to run spice.  The usage *must*
# be <spice_cmd> <spice_netlist>, with the spice results 
# outputed to a file with a .out filetype.  Autochar comes
# with sample wrapper scripts 'Hspice' and 'Smartspice'.
#$spice_cmd	= 'Hspice';
$spice_cmd	= 'Smartspice';

$techpath	= '/your/path/to/tech/files';
$spice_corner	= 'ttlh.sp';

# Any spice include for customized user commands.
$spice_include	= 'none';

# Any other spice commands
$spice_misc	= 'none';

# parameter values, NOT nodes
$low_value	= 0;
$high_value	= 'vhigh';
$midpoint_value	= 'vhigh/2';

# nodes
$low_node	= 'gnd';
$high_node	= 'vdd';

# scaling, for reporting results
$scale_cload	= 1;
$scale_delay	= 1;

# type of timing model:
#	linear		: output delays in slope-intercept form
#	non_linear	: output delays in table format
# If slewrate is specfied, then non_linear is enforced.
$timing_model	= 'linear';


# TRANSIENTS:

# measure propagation delays from input to output
# at these specified "percentages" of final value
$input_prop_percent	= 0.50;
$output_prop_percent	= 0.50;

# measure output transitions at these two "percentages"
# values of final value
$start_trans_percent	= 0.20;
$end_trans_percent	= 0.80;

# measure input slew rates at these two "percentages"
# values of final value
$start_slew_percent	= 0.20;
$end_slew_percent	= 0.80;

# input pulse control
$trans_delay		= '1ns';
$trans_risetime		= 'trise';
$trans_falltime		= 'tfall';
$trans_period		= 'period';
$trans_pulse_width	= 'pwidth';
$trans_timestop		= '2*period';
$trans_timestep		= '5ps';

# synopsys lookup table name
$lu_table_name		= '';

$trans_options		=
'.options
+	opts
+	list
+	nopage
+	method	= gear
+	lvltim	= 2
+	relq	= 2.0e-3
+	acct	= 1
+	post	= 1';

$smartspice_options	=
'.options
+	prpts
+	rawpts
+	format';

# OPTIMIZATION:

$optim_options		=
'.options
+	optlst	= 1
+	post	= 1';



# MODULE SPECIFIC:

# Load delay
@slewrate		= ();

# Setup/Hold
$relin			= 0.001;
$relout			= 0.001;
$criterion_percent	= 0.8;
$clock_percent		= 0.8;


1;
