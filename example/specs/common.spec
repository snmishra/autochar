#	$Id: common.spec,v 1.3 1999/01/21 06:35:11 ryu Exp ryu $

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

#------	SETUP ------------------------------------------------------------------

# Smartspice
#$spice_type		= 'smartspice';
#$spice_cmd		= 'Smartspice';

# Hspice
$spice_type		= 'hspice';
$spice_cmd		= 'Hspice';

$techpath		= $ENV{'TECHDIR'} . '/include';
$spice_corner		= 'ttlh.sp';
$spice_include		= '.include ' . $ENV{'TECHDIR'} . '/lib/autochar.sp';
$scale_cload		= '1.0e-12';
$scale_delay		= 0.060e-9;

# 50% input to 50% output prop delay
# 10% output to 90% output transition delay
$input_prop_percent	= 0.5;
$output_prop_percent	= 0.5;
$start_trans_percent	= 0.1;
$end_trans_percent	= 0.9;
$start_slew_percent	= 0.1;
$end_slew_percent	= 0.9;

# 50% input to 10% output prop delay
# 10% output to 50% output transition delay
#$input_prop_percent	= 0.5;
#$output_prop_percent	= 0.1;
#$start_trans_percent	= 0.1;
#$end_trans_percent	= 0.5;
#$start_slew_percent	= 0.1;
#$end_slew_percent	= 0.9;

$lu_table_name		= 'UNKNOWN';
$timing_model		= 'non_linear';

@slewrate		= &mult_list( $scale_delay, (0.66667, 1.33333, 2, 2.66667, 5.3333));
@cload			= &mult_list( '5.0e-15', (0.5, 2, 5, 10, 15, 24));

1;
