#! PERL

#	$Id: autochar.pl,v 1.41 2000/01/07 05:23:41 ryu Exp $

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

$autochar = $ENV{'AUTOCHAR'};

use Getopt::Std;
use File::Basename;

# load program defaults
require $autochar . '/lib/defaults.spec';

# load program components
require $autochar . '/src/utils.pl';
require $autochar . '/src/common.pl';
require $autochar . '/src/math.pl';
require $autochar . '/src/globals.pl';
require $autochar . '/src/model.pl';
require $autochar . '/src/data.pl';

# load characterization modules
require $autochar . '/src/load_delay.pl';
require $autochar . '/src/input_cap.pl';
require $autochar . '/src/setup_hold.pl';
require $autochar . '/src/clock_q.pl';
require $autochar . '/src/clock_enable.pl';
require $autochar . '/src/clock_gate.pl';


#-------------------------------------------------------------------------------
#	Parse Command
#-------------------------------------------------------------------------------

&copyright();

getopts('Dhso:c:');

$input_spec = $ARGV[0];
($base,$dir,$type) = fileparse($input_spec, '\..*');

$rptout = $base . '.rpt';

if ($opt_h || !$input_spec) {
    print "Usage: $Program [-hs] [-c cellname] [-o report] input+\n";
    print "   -h: help usage\n";
    print "   -s: skip running spice if output found\n";
    print "       (default: run hspice)\n";
    print "   -c: cellname\n";
    print "       (default: none)\n";
    print "   -o: output report\n";
    print "       (default: input.rpt)\n";
    print "input: input control file(s)\n";
    exit 0;
}

$rptout = ($opt_o) ? $opt_o : $rptout; 
$skip = $opt_s;
$cellname = $opt_c;
$debug = $opt_D;

open(OUT, "> $rptout") || die "ERROR:  Cannot create file '$rptout'.\n";
&print_header(OUT, "#");


#-------------------------------------------------------------------------------
#	Main
#-------------------------------------------------------------------------------

# run each spec file
foreach $input_spec (@ARGV) {

    (-e $input_spec) || die "ERROR: Cannot open '$input_spec'.\n";
    printf STDERR "Evaluating '$input_spec' ...\n";

    # run spec
    require $input_spec;
}

close(OUT);
printf STDERR "Created '$rptout'.\n";

exit 0;

#-------------------------------------------------------------------------------
#	Subroutines
#-------------------------------------------------------------------------------

#    autochar --
#	Called directly from spec file.
#
sub autochar {
    my(@arguments) = @_;

    # reset counter with each call to 'autochar'.
    $spice_run = 0;

    &init_autochar();

    if ($sim_type eq 'load_delay') {
	&ld_run(@arguments);
    } elsif ($sim_type eq 'input_cap') {
	&ic_run(@arguments);
    } elsif ($sim_type eq 'setup_hold') {
	&sh_run(@arguments);
    } elsif ($sim_type eq 'clock_q') {
	&cq_run(@arguments);
    } elsif ($sim_type eq 'clock_enable') {
	&ce_run(@arguments);
    } elsif ($sim_type eq 'clock_gate') {
	&cg_run(@arguments);
    } else {
	die "ERROR: unknown simulation type '$sim_type'.\n";
    }
}


#    copychar --
#	Called directly from spec file.
#
sub copychar {
    my(@arguments) = @_;

    if ($sim_type eq 'load_delay') {
	&ld_copy_data($cellname, @arguments);
    } elsif ($sim_type eq 'input_cap') {
	&ic_copy_data($cellname, @arguments);
    } elsif ($sim_type eq 'setup_hold') {
	&sh_copy_data($cellname, @arguments);
    } elsif ($sim_type eq 'clock_q') {
	&cq_copy_data($cellname, @arguments);
    } elsif ($sim_type eq 'clock_enable') {
	&ce_copy_data($cellname, @arguments);
    } elsif ($sim_type eq 'clock_gate') {
	&cg_copy_data($cellname, @arguments);
    } else {
	die "ERROR: unknown simulation type '$sim_type'.\n";
    }
}

sub copyright {
    print "
                              AutoChar

                   Version $version
                   Copyright (C) 1999 Robert K. Yu
		        email: robert\@yu.org

    Autochar is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2, or (at your option)
    any later version.

    Autochar is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Autochar; see the file COPYING.  If not, write to the
    Free Software Foundation, Inc., 59 Temple Place - Suite 330,
    Boston, MA 02111-1307, USA.\n\n";

}

sub init_autochar {
    &set_measure_values (
	\$input_prop_r, \$input_prop_f,
	\$output_prop_r, \$output_prop_f,
	\$trans_r1, \$trans_r2,
	\$trans_f1, \$trans_f2,
	\$slew_r1, \$slew_r2,
	\$slew_f1, \$slew_f2);
}


