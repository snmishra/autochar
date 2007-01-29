#	$Id: globals.pl,v 1.22 2000/01/28 05:33:23 ryu Exp $

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

# software version
$version	= '1.5.6 -- January 27, 2000';

# Integer value used to make spice runs unique.
$spice_run	= 0;

# List of spice runs, used to prevent from
# clobbering previous runs
%spice_run_list	= ();

$input_prop_f	= 0;
$input_prop_r	= 0;
$output_prop_f	= 0;
$output_prop_r	= 0;
$slew_f1	= 0;
$slew_f2	= 0;
$slew_r1	= 0;
$slew_r2	= 0;
$trans_f1	= 0;
$trans_f2	= 0;
$trans_r1	= 0;
$trans_r2	= 0;


1;

