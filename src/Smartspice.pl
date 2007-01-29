#! PERL

#	$Id: Smartspice.pl,v 1.3 1999/01/20 13:34:18 ryu Exp $

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


($Program) = $0 =~ /([^\/]*)$/;

#-------------------------------------------------------------------------------
#	Setup
#-------------------------------------------------------------------------------

use Getopt::Std;
use File::Basename;


#-------------------------------------------------------------------------------
#	Parse Command
#-------------------------------------------------------------------------------

getopts('ho:r:');

$input = $ARGV[0];
($base,$dir,$type) = fileparse($input, '\.\w+$');

$output = $base . '.out';
$raw = $base . '.raw';
$log = $base . '.log';

if ($opt_h || !$input) {
    print "Usage: $Program [-h] [-o spiceout] [-r raw] spicein\n";
    print "   -h: help usage\n";
    print "   -o: spice output\n";
    print "       (default: input.out)\n";
    print "   -r: raw spice output\n";
    print "       (default: input.raw)\n";
    print "input: spice input\n";
    exit 0;
}

$output = ($opt_o) ? $opt_o : $output; 
$raw = ($opt_r) ? $opt_r : $raw; 


#-------------------------------------------------------------------------------
#	Main
#-------------------------------------------------------------------------------

# run smartspice
`smartspice -b $input -o $output -r $raw >& $log`;


exit 0;
