#	$Id: setup_hold.pl,v 1.34 2000/02/11 00:07:23 ryu Exp $

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

#   sh_run --
#	Top-level function setup/hold characterization.
#	Generate the spice netlists, run hspice, and extract
#	data.
#
sub sh_run {
    local($d, $clktype, $clk, $qtype, $q, $ctype, $c, $tie, @tie_list) = @_;

    printf OUT "### SETUP/HOLD #############################################################\n\n";
    printf OUT "Cellname:\t\"$cellname\"\n";
    printf OUT "D Input:\t\"$d\"\n";
    printf OUT "Clock Input:\t\"$clk\"\t($clktype)\n";
    printf OUT "Q Output:\t\"$q\"\t($qtype)\n";
    printf OUT "Critical Node:\t\"$c\"\t($ctype)\n\n";

    &s_run ('lh', $d, $clktype, $clk, $qtype, $q, $ctype, $c, $tie, @tie_list);
    &s_run ('hl', $d, $clktype, $clk, $qtype, $q, $ctype, $c, $tie, @tie_list);

    &h_run ('lh', $d, $clktype, $clk, $qtype, $q, $ctype, $c, $tie, @tie_list);
    &h_run ('hl', $d, $clktype, $clk, $qtype, $q, $ctype, $c, $tie, @tie_list);

    printf OUT "\n\n",
}


#------ SETUP TIME CHARACTERIZATION --------------------------------------------

sub s_run {

    my($out_trans, $d, $clktype, $clk, $qtype, $q, $ctype, $c, $tie, @tie_list) = @_;

    local($run_name, $dtrans);
    local($optmod, $optparam, $optmeasure);

    # check
    if (($clktype ne 'rising') && ($clktype ne 'falling')) {
	die "ERROR: clock type must be either 'rising' or 'falling'\n";
    }
    if (($qtype ne 'inverting') && ($qtype ne 'non_inverting')) {
	die "ERROR: q type must be either 'inverting' or 'non_inverting'\n";
    }

    # give names to these puppies
    $optmod = 'optmod';
    $optparam = 'optsetup';
    $optmeasure = 'optpass';

    $run_name = &run_file_name($cellname, $d, $clk, $q, 's');
    open(SPICEIN,">$run_name") || die "ERROR:  Cannot open file '$run_name'.";

    # Create the hspice netlist(s)
    &print_header(SPICEIN, '*');
    printf SPICEIN "*	Char:	D-Flop Setup Time Characterization\n";
    printf SPICEIN "*	Data:	\"$d\"\n";
    printf SPICEIN "*	Clock:	\"$clk\"\n";
    printf SPICEIN "*	Q:	\"$q\"\n";
    printf SPICEIN "*	C:	\"$c\"\n";
    printf SPICEIN "*	Trans:	\"$out_trans\"\n";

    &s_print_setup (SPICEIN);
    &s_print_source (SPICEIN, $clktype, $out_trans, $qtype);
    &s_print_dut (SPICEIN, $d, $clk, $q, $tie, @tie_list);
    &s_print_measure (SPICEIN, $clktype, $out_trans, $ctype, $c);
    &s_print_trans (SPICEIN, $clktype, $out_trans);

    printf SPICEIN ".end\n";
    close(SPICEIN);

    &run_spice($run_name);

    &s_report_spice($run_name, $out_trans, $d, $clktype, $clk, $qtype, $q, $ctype, $c);
}


sub s_print_setup {

    my ($fp) = @_;

    printf $fp "\n*--- SETUP ---------------------------------------------------\n";
    printf $fp ".include '$techpath/$spice_corner'\n";
    printf $fp ".include '$spice_netlist'\n";
    if ($spice_include ne 'none') {
	printf $fp "$spice_include\n";
    }
    if ($spice_misc ne 'none') {
	printf $fp "$spice_misc\n";
    }

    if ($spice_type eq 'smartspice') {
	printf $fp "$smartspice_options\n";
	printf $fp ".param isetup = 0\n" ;
	printf $fp ".param setup_hold_scale = '$setup_hold_scale'\n" ;
	printf $fp ".param setup = 'isetup*setup_hold_scale'\n" ;
    } else {
	printf $fp "$optim_options\n";
	printf $fp ".model $optmod opt method=bisection\n";
	printf $fp "+\trelin = $relin\n";
	printf $fp "+\trelout = $relout\n";
	printf $fp ".param setup = $optparam('$setup_range[0]', '$setup_range[0]', '$setup_range[1]')\n" ;
    }

    if ($#slewrate != -1) {
	printf $fp ".param slewrate = '$slewrate[0]'\n" ;
	printf $fp ".param slew_start = '$start_slew_percent'\n" ;
	printf $fp ".param slew_end = '$end_slew_percent'\n" ;
    }
}


#	Modifies dtrans
#
sub s_print_source {

    my ($fp, $clktype, $out_trans, $qtype) = @_;

    printf $fp "\n*--- INPUTS --------------------------------------------------\n";

    if ($clktype eq 'rising') {
	if ($#slewrate != -1) {
	    printf $fp "vclk vclk $low_value pulse (
+	'$low_value'
+	'$high_value'
+	'$trans_delay+$trans_risetime/2'
+	'0'
+	'0'
+	'$trans_pulse_width+$trans_risetime/2+$trans_falltime/2'
+	'$trans_period')\n";
	} else {
	    printf $fp "vclk vclk $low_value pulse (
+	'$low_value'
+	'$high_value'
+	'$trans_delay'
+	'$trans_risetime'
+	'$trans_falltime'
+	'$trans_pulse_width'
+	'$trans_period')\n";
	}
    } elsif ($clktype eq 'falling') {
	if ($#slewrate != -1) {
	    printf $fp "vclk vclk $low_value pulse (
+	'$high_value'
+	'$low_value'
+	'$trans_delay+$trans_risetime/2'
+	'0'
+	'0'
+	'$trans_pulse_width+$trans_risetime/2+$trans_falltime/2'
+	'$trans_period')\n";
	} else {
	    printf $fp "vclk vclk $low_value pulse (
+	'$high_value'
+	'$low_value'
+	'$trans_delay'
+	'$trans_risetime'
+	'$trans_falltime'
+	'$trans_pulse_width'
+	'$trans_period')\n";
	}
    } else {
	die "ERROR: unknown clock transition type '$clktype'\n";
    }

    if ( (($out_trans eq 'lh') && ($qtype eq 'non_inverting')) ||
	 (($out_trans eq 'hl') && ($qtype eq 'inverting')) ) {

	$dtrans = 'rise';
	printf $fp "vd vd $low_value pulse (
+	'$low_value'
+	'$high_value'
+	'$trans_delay+$trans_risetime+2*$trans_pulse_width+$trans_falltime-setup'
+	'$trans_risetime'
+	'$trans_falltime'
+	'3*$trans_period'
+	'4*$trans_period')\n";

    } elsif ( (($out_trans eq 'hl') && ($qtype eq 'non_inverting')) ||
	      (($out_trans eq 'lh') && ($qtype eq 'inverting')) ) {

	$dtrans = 'fall';
	printf $fp "vd vd $low_value pulse (
+	'$high_value'
+	'$low_value'
+	'$trans_delay+$trans_risetime+2*$trans_pulse_width+$trans_falltime-setup'
+	'$trans_risetime'
+	'$trans_falltime'
+	'3*$trans_period'
+	'4*$trans_period')\n";

    } else {
	die "ERROR: unknown combination of '$out_trans' and '$qtype'\n";
    }
}


sub s_print_dut {

    my($fp, $d, $clk, $q, $tie, $tie_list) = @_;
    my($term, $termname, $termtype);
    my($dbuf, $clkbuf, $outload);
    my($vcvs, @inlist, @reflist);
    local($term_no, @vcvs_list, @output_loads);

    $term_no = 0;

    if ($buffer{$d} ne '') {
	$dbuf = $buffer{$d};
    } else {
	$dbuf = $buffer{'default'};
    }
    if ($buffer{$clk} ne '') {
	$clkbuf = $buffer{$clk};
    } else {
	$clkbuf = $buffer{'default'};
    }
    if ($#slewrate != -1) {
	$clkbuf = 'slewbuffer';
	printf STDERR "INFO: slewbuffer buffer used for slew rate setup_hold at clock input.\n";
    }

    printf $fp "\n*--- TEST CIRCUIT --------------------------------------------\n";

    @inlist = ($d, $clk);
    @reflist = ('d', 'clk');

    if ($dbuf eq 'none') {
	printf $fp "vshortd vd d DC 0\n";
    } else {
	printf $fp "xdbuf vd d $dbuf\n";
    }
    if ($clkbuf eq 'none') {
	printf $fp "vshortclk vclk clk DC 0\n";
    } else {
	printf $fp "xclkbuf vclk clk $clkbuf\n";
    }

    printf $fp "xflop\n";
    foreach $term (@termlist) {
	($termname, $termtype) = split(':', $term);
	if ($termname eq $d) {
	    printf $fp "+\td\t\$ $term\n";
	    next;
	}
	if ($termname eq $clk) {
	    printf $fp "+\tclk\t\$ $term\n";
	    next;
	}
	if ($termname eq $q) {
	    printf $fp "+\t%s\t\$ $term\n", &lookup_output_load($termname, 'q');
	    next;
	}
	if ($termtype eq 'i') {
	    printf $fp "+\t%s\t\$ $term\n",
		&lookup_input($termname, \@inlist, \@reflist, $tie, @tie_list);
	    next;
	}
	if ($termtype eq 'o') {
	    printf $fp "+\t%s\t\$ $term\n", &lookup_output_load($termname);
	    next;
	}
    }
    printf $fp "+\t$cellname\n";

    # if any
    foreach $vcvs (@vcvs_list) {
	printf $fp "$vcvs\n";
    }

    printf $fp "\n*--- LOADS ---------------------------------------------------\n";
    # if any
    foreach $outload (@output_loads) {
	printf $fp "$outload\n";
    }
}


sub s_print_measure {

    my($fp, $clktype, $out_trans, $ctype, $c) = @_;

    printf $fp "\n*--- MEASURE -------------------------------------------------\n";
    printf $fp ".option autostop\n";

    printf $fp "* Measure setup time:\n";

    if ($spice_type eq 'smartspice') {
	printf $fp ".measure tran isetup param='isetup'\n";
	printf $fp ".measure tran setup param='setup'\n";
    }

    printf $fp ".measure tran setup_${out_trans} %s v(d) val='$midpoint_value' cross=1\n",
	&trig_word();
    if ($clktype eq 'rising') {
	printf $fp "+\ttarg=v(clk) val='$midpoint_value' rise=2\n";
    } else {
	printf $fp "+\ttarg=v(clk) val='$midpoint_value' fall=2\n";
    }

    printf $fp "* Measure clock slew rate:\n";
    if ($clktype eq 'rising') {
	printf $fp
	    ".measure tran clkslew %s v(clk) val='$slew_r1' rise=2\n",
	    &trig_word();
	printf $fp
	    "+\ttarg=v(clk) val='$slew_r2' rise=2\n";
    } else {
	printf $fp
	    ".measure tran clkslew %s v(clk) val='$slew_f1' fall=2\n",
	    &trig_word();
	printf $fp
	    "+\ttarg=v(clk) val='$slew_f2' fall=2\n";
    }

    printf $fp "\n* Measure internal criterion node:\n";
    printf $fp ".measure tran vcrit find v(xflop.${c})\n";
    if ($clktype eq 'rising') {
	printf $fp "+\twhen v(clk)='$clock_percent*$high_value' rise=2\n"; 
    } else {
	printf $fp "+\twhen v(clk)='(1-$clock_percent)*$high_value' fall=2\n"; 
    }

    # cnode:
    if ( (($dtrans eq 'rise') && ($ctype eq 'inverting')) ||
	 (($dtrans eq 'fall') && ($ctype eq 'non_inverting')) ) {
	printf $fp ".measure tran $optmeasure param='($high_value-vcrit)/$high_value'\n";
	if ($spice_type ne 'smartspice') {
	    printf $fp "+\tgoal='${criterion_percent}'\n";
	}
    } elsif ( (($dtrans eq 'fall') && ($ctype eq 'inverting')) ||
	      (($dtrans eq 'rise') && ($ctype eq 'non_inverting')) ) {
	printf $fp ".measure tran $optmeasure param='vcrit/$high_value'\n";
	if ($spice_type ne 'smartspice') {
	    printf $fp "+\tgoal='${criterion_percent}'\n";
	}
    }
}


sub s_print_trans {

    my($fp, $clktype, $out_trans) = @_;
    my($j);

    printf $fp "\n*--- TRANSIENT -----------------------------------------------\n";
    if ($spice_type eq 'smartspice') {

	printf $fp "* Measure final clock->q time:\n";
	if ($clktype eq 'rising') {
	    printf $fp ".measure tran clk_q delay v(clk) val='$midpoint_value' rise=2\n";
	} else {
	    printf $fp ".measure tran clk_q delay v(clk) val='$midpoint_value' fall=2\n";
	}
	if ($out_trans eq 'lh') {
	    printf $fp "+\ttarg=v(q) val='$midpoint_value' rise=1\n";
	} elsif ($out_trans eq 'hl') {
	    printf $fp "+\ttarg=v(q) val='$midpoint_value' fall=1\n";
	} else {
	    die "ERROR: unknown output transition '$out_trans'\n";
	}
	printf $fp ".trans $trans_timestep '$trans_timestop'\n";

    } else {
	printf $fp ".trans $trans_timestep '$trans_timestop' sweep
+	optimize=$optparam
+	results=$optmeasure
+	model=$optmod\n";

	# Have to put this here in order for bisect to work. A
	# failed measurement during bisect causes bisect to abort.
	printf $fp ".trans $trans_timestep '$trans_timestop'\n";
	printf $fp "\n* Measure final clock->q time:\n";
	if ($clktype eq 'rising') {
	    printf $fp ".measure tran clk_q trig=v(clk) val='$midpoint_value' rise=2\n";
	} else {
	    printf $fp ".measure tran clk_q trig=v(clk) val='$midpoint_value' fall=2\n";
	}
	if ($out_trans eq 'lh') {
	    printf $fp "+\ttarg=v(q) val='$midpoint_value' rise=1\n";
	} elsif ($out_trans eq 'hl') {
	    printf $fp "+\ttarg=v(q) val='$midpoint_value' fall=1\n";
	} else {
	    die "ERROR: unknown output transition '$out_trans'\n";
	}
    }

    if ($spice_type eq 'smartspice') {
	&s_print_control($fp, $out_trans);
    }

    printf $fp "\n* Alter slewrate:\n";
    for ($j = 1; $j <= $#slewrate; $j++) {
	printf $fp ".alter\n";
	printf $fp ".param slewrate = '$slewrate[$j]'\n" ;
    }
}


sub s_print_control {
    my($fp, $out_trans) = @_;

    printf $fp "\n*--- CONTROL -------------------------------------------------\n";
    printf $fp ".control
# find fail
modif loop=${iterations} stop ${optmeasure} le ${criterion_percent} isetup -= (0)${window} prtbl
set fail = \$isetup
# find pass
modif loop=${iterations} stop ${criterion_percent} le ${optmeasure} isetup += (0)${window} prtbl
set pass = \$isetup

set i = 0
set window = \`expr \$pass - \$fail\`

# Save measurements
set save_setup = \$setup_${out_trans}
set save_clkslew = \$clkslew
set save_clk_q = \$clk_q
set save_vcrit = \$vcrit
set save_${optmeasure} = \$${optmeasure}

echo Iteration \$i: Pass = \$pass, Fail = \$fail, Window = \$window, Setup = \$save_setup, Criterion = \$save_${optmeasure}
";

    printf $fp "
# Binary search
while (\$window > ${resolution}) 
    set i = \`expr \$i + 1\`
    set sum = \`expr \$pass + \$fail\`
    set midpoint = \`expr \$sum / 2\`

    modif loop=1 isetup = \$midpoint prtbl

    if (\$${optmeasure} > ${criterion_percent} or \$${optmeasure} eq ${criterion_percent})
	set pass = \$midpoint

	# Save measurements
	set save_setup = \$setup_${out_trans}
	set save_clkslew = \$clkslew
	set save_clk_q = \$clk_q
	set save_vcrit = \$vcrit
	set save_${optmeasure} = \$${optmeasure}

    else
	set fail = \$midpoint
    end
    set window = \`expr \$pass - \$fail\`

    echo Iteration \$i: Pass = \$pass, Fail = \$fail, Window = \$window, Setup = \$save_setup, Criterion = \$save_${optmeasure}
end

echo Final setup_${out_trans} = \$save_setup
echo Final clkslew = \$clkslew
echo Final clk_q = \$clk_q
echo Final vcrit = \$vcrit
echo Final ${optmeasure} = \$${optmeasure}

.endc\n";

}

sub s_report_spice {

    my($run_name, $out_trans, $d, $clktype, $clk, $qtype, $q, $ctype, $c) = @_;

    my($base,$dir,$ext,$spiceout);
    my(@setup, @clkslew, @clk_q, @vcrit, @pass);
    my(@scaled_setup, @scaled_clkslew, @scaled_clk_q, $i);

    ($base,$dir,$ext) = fileparse($run_name, '\.sp');
    $spiceout = $base . '.out';

    printf STDERR "Extracting results from '$spiceout' ...\n";

    # grab the last values
    open(SPICEOUT, $spiceout) || die "ERROR: Cannot find '$spiceout'.\n";

    if ($spice_type eq 'smartspice') {
	while (<SPICEOUT>) {
	    if (($name, $value) = /^Final (setup_${out_trans}) *= +([0-9\+\-eE\.]+)/) {
		push(@setup, $value);
		next;
	    }
	    if (($name, $value) = /^Final (clkslew) *= +([0-9\+\-eE\.]+)/) {
		push (@clkslew, $value);
		next;
	    }
	    if (($name, $value) = /^Final (clk_q) *= +([0-9\+\-eE\.]+)/) {
		push (@clk_q, $value);
		next;
	    }
	    if (($name, $value) = /^Final (vcrit) *= +([0-9\+\-eE\.]+)/) {
		push (@vcrit, $value);
		next;
	    }
	    if (($name, $value) = /^Final ($optmeasure) *= +([0-9\+\-eE\.]+)/) {
		push (@pass, $value);
		next;
	    }
	}
    } else {
	while (<SPICEOUT>) {
	    if (($name, $value) = /^ +(setup_${out_trans}) *= +([0-9\+\-eE\.]+)/) {
		push(@setup, $value);
		next;
	    }
	    if (($name, $value) = /^ +(clkslew) *= +([0-9\+\-eE\.]+)/) {
		push (@clkslew, $value);
		next;
	    }
	    if (($name, $value) = /^ +(clk_q) *= +([0-9\+\-eE\.]+)/) {
		push (@clk_q, $value);
		next;
	    }
	    if (($name, $value) = /^ +(vcrit) *= +([0-9\+\-eE\.]+)/) {
		push (@vcrit, $value);
		next;
	    }
	    if (($name, $value) = /^ +($optmeasure) *= +([0-9\+\-eE\.]+)/) {
		push (@pass, $value);
		next;
	    }
	}
    }

    @setup = &halve_list(@setup);
    @clkslew = &halve_list(@clkslew);
    @vcrit = &halve_list(@vcrit);
    @pass = &halve_list(@pass);

    printf OUT "\n";
    printf OUT "    InputSlew\tSetup_${out_trans}\tClock-Q\t\tCritNode\tCritPercent\n";
    printf OUT "    [s]\t\t[s]\t\t[s]\t\t[V]\n";
    printf OUT "    ----------\t----------\t----------\t----------\t----------\n";

    for ($i = 0; $i <= $#setup; $i++) {
	printf OUT "    %.4e\t%.4e\t%.4e\t%.4e\t%.4e\n",
	    $clkslew[$i], $setup[$i], $clk_q[$i], $vcrit[$i], $pass[$i];
    }

    @scaled_setup = &div_list($scale_delay, @setup);
    @scaled_clk_q = &div_list($scale_delay, @clk_q);
    @scaled_clkslew = &div_list($scale_delay, @clkslew);

    printf OUT "\n";
    printf OUT "    InputSlew\tSetup_${out_trans}\tClock-Q\t\tCritNode\tCritPercent\n";
    printf OUT "    [scaled]\t[scaled]\t[scaled]\t[V]\n";
    printf OUT "    ----------\t----------\t----------\t----------\t----------\n";

    for ($i = 0; $i <= $#setup; $i++) {
	printf OUT "    %.4e\t%.4e\t%.4e\t%.4e\t%.4e\n",
	    $scaled_clkslew[$i], $scaled_setup[$i],
	    $scaled_clk_q[$i], $vcrit[$i], $pass[$i];
    }

    &s_save_data($cellname, $d, $clk, $clktype, ('setup_' . $out_trans), \@scaled_setup);

    close SPICEOUT;
}

#------ HOLD TIME CHARACTERIZATION ---------------------------------------------

sub h_run {

    my($out_trans, $d, $clktype, $clk, $qtype, $q, $ctype, $c, $tie, @tie_list) = @_;

    local($run_name, $dtrans);
    local($optmod, $optparam, $optmeasure);

    # check
    if (($clktype ne 'rising') && ($clktype ne 'falling')) {
	die "ERROR: clock type must be either 'rising' or 'falling'\n";
    }
    if (($qtype ne 'inverting') && ($qtype ne 'non_inverting')) {
	die "ERROR: q type must be either 'inverting' or 'non_inverting'\n";
    }

    # give names to these puppies
    $optmod = 'optmod';
    $optparam = 'opthold';
    $optmeasure = 'optpass';

    $run_name = &run_file_name($cellname, $d, $clk, $q, 'h');
    open(SPICEIN,">$run_name") || die "ERROR:  Cannot open file '$run_name'.";

    # Create the hspice netlist(s)
    &print_header(SPICEIN, '*');
    printf SPICEIN "*	Char:	D-Flop Hold Time Characterization\n";
    printf SPICEIN "*	Data:	\"$d\"\n";
    printf SPICEIN "*	Clock:	\"$clk\"\n";
    printf SPICEIN "*	Q:	\"$q\"\n";
    printf SPICEIN "*	C:	\"$c\"\n";
    printf SPICEIN "*	Trans:	\"$out_trans\"\n";

    &h_print_setup (SPICEIN);
    &h_print_source (SPICEIN, $clktype, $out_trans, $qtype);
    &h_print_dut (SPICEIN, $d, $clk, $q, $tie, @tie_list);
    &h_print_measure (SPICEIN, $clktype, $out_trans, $ctype, $c);
    &h_print_trans (SPICEIN, $clktype, $out_trans);

    printf SPICEIN ".end\n";
    close(SPICEIN);

    &run_spice($run_name);

    &h_report_spice($run_name, $out_trans, $d, $clktype, $clk, $qtype, $q, $ctype, $c);
}


sub h_print_setup {

    my ($fp) = @_;

    printf $fp "\n*--- SETUP ---------------------------------------------------\n";
    printf $fp ".include '$techpath/$spice_corner'\n";
    printf $fp ".include '$spice_netlist'\n";
    if ($spice_include ne 'none') {
	printf $fp "$spice_include\n";
    }
    if ($spice_misc ne 'none') {
	printf $fp "$spice_misc\n";
    }

    if ($spice_type eq 'smartspice') {
	printf $fp "$smartspice_options\n";
	printf $fp ".param ihold = 0\n" ;
	printf $fp ".param setup_hold_scale = '$setup_hold_scale'\n" ;
	printf $fp ".param hold = 'ihold*setup_hold_scale'\n" ;
    } else {
	printf $fp "$optim_options\n";
	printf $fp ".model $optmod opt method=bisection\n";
	printf $fp "+\trelin=$relin\n";
	printf $fp "+\trelout=$relout\n";
	printf $fp ".param hold = $optparam('$hold_range[0]', '$hold_range[0]', '$hold_range[1]')\n" ;
    }

    if ($#slewrate != -1) {
	printf $fp ".param slewrate = '$slewrate[0]'\n" ;
	printf $fp ".param slew_start = '$start_slew_percent'\n" ;
	printf $fp ".param slew_end = '$end_slew_percent'\n" ;
    }
}


#	Modifies dtrans
#
sub h_print_source {

    my ($fp, $clktype, $out_trans, $qtype) = @_;

    printf $fp "\n*--- INPUTS --------------------------------------------------\n";

    if ($clktype eq 'rising') {
	if ($#slewrate != -1) {
	    printf $fp "vclk vclk $low_value pulse (
+	'$low_value'
+	'$high_value'
+	'$trans_delay+$trans_risetime/2'
+	'0'
+	'0'
+	'$trans_pulse_width+$trans_risetime/2+$trans_falltime/2'
+	'$trans_period')\n";
	} else {
	    printf $fp "vclk vclk $low_value pulse (
+	'$low_value'
+	'$high_value'
+	'$trans_delay'
+	'$trans_risetime'
+	'$trans_falltime'
+	'$trans_pulse_width'
+	'$trans_period')\n";
	}
    } elsif ($clktype eq 'falling') {
	if ($#slewrate != -1) {
	    printf $fp "vclk vclk $low_value pulse (
+	'$high_value'
+	'$low_value'
+	'$trans_delay+$trans_risetime/2'
+	'0'
+	'0'
+	'$trans_pulse_width+$trans_risetime/2+$trans_falltime/2'
+	'$trans_period')\n";
	} else {
	    printf $fp "vclk vclk $low_value pulse (
+	'$high_value'
+	'$low_value'
+	'$trans_delay'
+	'$trans_risetime'
+	'$trans_falltime'
+	'$trans_pulse_width'
+	'$trans_period')\n";
	}
    } else {
	die "ERROR: unknown clock transition type '$clktype'\n";
    }

    if ( (($out_trans eq 'lh') && ($qtype eq 'non_inverting')) ||
	 (($out_trans eq 'hl') && ($qtype eq 'inverting')) ) {

	$dtrans = 'rise';
	printf $fp "vd vd $low_value pulse (
+	'$low_value'
+	'$high_value'
+	'$trans_delay+$trans_risetime+$trans_pulse_width'
+	'$trans_risetime'
+	'$trans_falltime'
+	'$trans_pulse_width+hold'
+	'4*$trans_period')\n";

    } elsif ( (($out_trans eq 'hl') && ($qtype eq 'non_inverting')) ||
	      (($out_trans eq 'lh') && ($qtype eq 'inverting')) ) {

	$dtrans = 'fall';
	printf $fp "vd vd $low_value pulse (
+	'$high_value'
+	'$low_value'
+	'$trans_delay+$trans_risetime+$trans_pulse_width'
+	'$trans_risetime'
+	'$trans_falltime'
+	'$trans_pulse_width+hold'
+	'4*$trans_period')\n";

    } else {
	die "ERROR: unknown combination of '$out_trans' and '$qtype'\n";
    }
}


sub h_print_dut {

    my($fp, $d, $clk, $q, $tie, $tie_list) = @_;
    my($term, $termname, $termtype);
    my($dbuf, $clkbuf, $outload);
    my($vcvs, @inlist, @reflist);
    local($term_no, @vcvs_list, @output_loads);

    $term_no = 0;

    if ($buffer{$d} ne '') {
	$dbuf = $buffer{$d};
    } else {
	$dbuf = $buffer{'default'};
    }
    if ($buffer{$clk} ne '') {
	$clkbuf = $buffer{$clk};
    } else {
	$clkbuf = $buffer{'default'};
    }
    if ($#slewrate != -1) {
	$clkbuf = 'slewbuffer';
	printf STDERR "INFO: slewbuffer buffer used for slew rate setup_hold at clock input.\n";
    }

    printf $fp "\n*--- TEST CIRCUIT --------------------------------------------\n";

    @inlist = ($d, $clk);
    @reflist = ('d', 'clk');

    if ($dbuf eq 'none') {
	printf $fp "vshortd vd d DC 0\n";
    } else {
	printf $fp "xdbuf vd d $dbuf\n";
    }
    if ($clkbuf eq 'none') {
	printf $fp "vshortclk vclk clk DC 0\n";
    } else {
	printf $fp "xclkbuf vclk clk $clkbuf\n";
    }

    printf $fp "xflop\n";
    foreach $term (@termlist) {
	($termname, $termtype) = split(':', $term);
	if ($termname eq $d) {
	    printf $fp "+\td\t\$ $term\n";
	    next;
	}
	if ($termname eq $clk) {
	    printf $fp "+\tclk\t\$ $term\n";
	    next;
	}
	if ($termname eq $q) {
	    printf $fp "+\t%s\t\$ $term\n", &lookup_output_load($termname, 'q');
	    next;
	}
	if ($termtype eq 'i') {
	    printf $fp "+\t%s\t\$ $term\n",
		&lookup_input($termname, \@inlist, \@reflist, $tie, @tie_list);
	    next;
	}
	if ($termtype eq 'o') {
	    printf $fp "+\t%s\t\$ $term\n", &lookup_output_load($termname);
	    next;
	}
    }
    printf $fp "+\t$cellname\n";

    # if any
    foreach $vcvs (@vcvs_list) {
	printf $fp "$vcvs\n";
    }

    printf $fp "\n*--- LOADS ---------------------------------------------------\n";
    # if any
    foreach $outload (@output_loads) {
	printf $fp "$outload\n";
    }
}


sub h_print_measure {

    my($fp, $clktype, $out_trans, $ctype, $c) = @_;

    printf $fp "\n*--- MEASURE -------------------------------------------------\n";
    printf $fp ".option autostop\n";

    if ($spice_type eq 'smartspice') {
	printf $fp ".measure tran ihold param='ihold'\n";
	printf $fp ".measure tran hold param='hold'\n";
    }

    printf $fp "* Measure hold time:\n";
    if ($clktype eq 'rising') {
	printf $fp ".measure tran hold_${out_trans} %s v(clk) val='$midpoint_value' rise=2\n",
	    &trig_word();
    } else {
	printf $fp ".measure tran hold_${out_trans} %s v(clk) val='$midpoint_value' fall=2\n",
	    &trig_word();
    }
    printf $fp "+\ttarg=v(d) val='$midpoint_value' cross=2\n";

    printf $fp "* Measure clock slew rate:\n";
    if ($clktype eq 'rising') {
	printf $fp
	    ".measure tran clkslew %s v(clk) val='$slew_r1' rise=2\n",
	    &trig_word();
	printf $fp
	    "+\ttarg=v(clk) val='$slew_r2' rise=2\n";
    } else {
	printf $fp
	    ".measure tran clkslew %s v(clk) val='$slew_f1' fall=2\n",
	    &trig_word();
	printf $fp
	    "+\ttarg=v(clk) val='$slew_f2' fall=2\n";
    }

    printf $fp "\n* Measure internal criterion node:\n";
    printf $fp ".measure tran vcrit find v(xflop.${c})\n";
    if ($clktype eq 'rising') {
	printf $fp "+\twhen v(clk)='$clock_percent*$high_value' rise=2\n"; 
    } else {
	printf $fp "+\twhen v(clk)='(1-$clock_percent)*$high_value' fall=2\n"; 
    }

    # cnode:
    if ( (($dtrans eq 'rise') && ($ctype eq 'inverting')) ||
	 (($dtrans eq 'fall') && ($ctype eq 'non_inverting')) ) {
	printf $fp ".measure tran $optmeasure param='($high_value-vcrit)/$high_value'\n";
	if ($spice_type ne 'smartspice') {
	    printf $fp "+\tgoal='${criterion_percent}'\n";
	}
    } elsif ( (($dtrans eq 'fall') && ($ctype eq 'inverting')) ||
	      (($dtrans eq 'rise') && ($ctype eq 'non_inverting')) ) {
	printf $fp ".measure tran $optmeasure param='vcrit/$high_value'\n";
	if ($spice_type ne 'smartspice') {
	    printf $fp "+\tgoal='${criterion_percent}'\n";
	}
    }
}


sub h_print_trans {

    my($fp, $clktype, $out_trans) = @_;

    printf $fp "\n*--- TRANSIENT -----------------------------------------------\n";
    if ($spice_type eq 'smartspice') {

	printf $fp "* Measure final clock->q time:\n";
	if ($clktype eq 'rising') {
	    printf $fp ".measure tran clk_q delay v(clk) val='$midpoint_value' rise=2\n";
	} else {
	    printf $fp ".measure tran clk_q delay v(clk) val='$midpoint_value' fall=2\n";
	}
	if ($out_trans eq 'lh') {
	    printf $fp "+\ttarg=v(q) val='$midpoint_value' rise=1\n";
	} elsif ($out_trans eq 'hl') {
	    printf $fp "+\ttarg=v(q) val='$midpoint_value' fall=1\n";
	} else {
	    die "ERROR: unknown output transition '$out_trans'\n";
	}
	printf $fp ".trans $trans_timestep '$trans_timestop'\n";

    } else {
	printf $fp ".trans $trans_timestep '$trans_timestop' sweep
+	optimize=$optparam
+	results=$optmeasure
+	model=$optmod\n";

	# Have to put this here in order for bisect to work. A
	# failed measurement during bisect causes bisect to abort.
	printf $fp ".trans $trans_timestep '$trans_timestop'\n";
	printf $fp "\n* Measure final clock->q time:\n";
	if ($clktype eq 'rising') {
	    printf $fp ".measure tran clk_q trig=v(clk) val='$midpoint_value' rise=2\n";
	} else {
	    printf $fp ".measure tran clk_q trig=v(clk) val='$midpoint_value' fall=2\n";
	}

	if ($out_trans eq 'lh') {
	    printf $fp "+\ttarg=v(q) val='$midpoint_value' rise=1\n";
	} elsif ($out_trans eq 'hl') {
	    printf $fp "+\ttarg=v(q) val='$midpoint_value' fall=1\n";
	} else {
	    die "ERROR: unknown output transition '$out_trans'\n";
	}
    }

    if ($spice_type eq 'smartspice') {
	&h_print_control($fp, $out_trans);
    }

    printf $fp "\n* Alter slewrate:\n";
    for ($j = 1; $j <= $#slewrate; $j++) {
	printf $fp ".alter\n";
	printf $fp ".param slewrate = '$slewrate[$j]'\n" ;
    }
}

sub h_print_control {
    my($fp, $out_trans) = @_;

    printf $fp "\n*--- CONTROL -------------------------------------------------\n";
    printf $fp ".control
# find fail
modif loop=${iterations} stop ${optmeasure} le ${criterion_percent} ihold -= (0)${window} prtbl
set fail = \$ihold
# find pass
modif loop=${iterations} stop ${criterion_percent} le ${optmeasure} ihold += (0)${window} prtbl
set pass = \$ihold

set i = 0
set window = \`expr \$pass - \$fail\`

# Save measurements
set save_hold = \$hold_${out_trans}
set save_clkslew = \$clkslew
set save_clk_q = \$clk_q
set save_vcrit = \$vcrit
set save_${optmeasure} = \$${optmeasure}

echo Iteration \$i: Pass = \$pass, Fail = \$fail, Window = \$window, hold = \$save_hold
";

    printf $fp "
# Binary search
while (\$window > ${resolution}) 
    set i = \`expr \$i + 1\`
    set sum = \`expr \$pass + \$fail\`
    set midpoint = \`expr \$sum / 2\`

    modif loop=1 ihold = \$midpoint prtbl

    if (\$${optmeasure} > ${criterion_percent} or \$${optmeasure} eq ${criterion_percent})
	set pass = \$midpoint

	# Save measurements
	set save_hold = \$hold_${out_trans}
	set save_clkslew = \$clkslew
	set save_clk_q = \$clk_q
	set save_vcrit = \$vcrit
	set save_${optmeasure} = \$${optmeasure}

    else
	set fail = \$midpoint
    end
    set window = \`expr \$pass - \$fail\`

    echo Iteration \$i: Pass = \$pass, Fail = \$fail, Window = \$window, hold = \$save_hold
end

echo Final hold_${out_trans} = \$save_hold
echo Final clkslew = \$clkslew
echo Final clk_q = \$clk_q
echo Final vcrit = \$vcrit
echo Final ${optmeasure} = \$${optmeasure}

.endc\n";

}

sub h_report_spice {

    my  ($run_name, $out_trans, $d, $clktype, $clk, $qtype, $q, $ctype, $c) = @_;

    my($base,$dir,$ext,$spiceout);
    my(@hold, @clkslew, @clk_q, @vcrit, @pass);
    my(@scaled_hold, @scaled_clkslew, @scaled_clk_q, $i);

    ($base,$dir,$ext) = fileparse($run_name, '\.sp');
    $spiceout = $base . '.out';

    printf STDERR "Extracting results from '$spiceout' ...\n";

    # grab the last values
    open(SPICEOUT, $spiceout) || die "ERROR: Cannot find '$spiceout'.\n";
    if ($spice_type eq 'smartspice') {
	while (<SPICEOUT>) {
	    if (($name, $value) = /^Final (hold_${out_trans}) *= +([0-9\+\-eE\.]+)/) {
		push(@hold, $value);
		next;
	    }
	    if (($name, $value) = /^Final (clkslew) *= +([0-9\+\-eE\.]+)/) {
		push (@clkslew, $value);
		next;
	    }
	    if (($name, $value) = /^Final (clk_q) *= +([0-9\+\-eE\.]+)/) {
		push (@clk_q, $value);
		next;
	    }
	    if (($name, $value) = /^Final (vcrit) *= +([0-9\+\-eE\.]+)/) {
		push (@vcrit, $value);
		next;
	    }
	    if (($name, $value) = /^Final ($optmeasure) *= +([0-9\+\-eE\.]+)/) {
		push (@pass, $value);
		next;
	    }
	}
    } else {
	while (<SPICEOUT>) {
	    if (($name, $value) = /^ +(hold_${out_trans}) *= +([0-9\+\-eE\.]+)/) {
		push(@hold, $value);
		next;
	    }
	    if (($name, $value) = /^ +(clkslew) *= +([0-9\+\-eE\.]+)/) {
		push (@clkslew, $value);
		next;
	    }
	    if (($name, $value) = /^ +(clk_q) *= +([0-9\+\-eE\.]+)/) {
		push(@clk_q, $value);
		next;
	    }
	    if (($name, $value) = /^ +(vcrit) *= +([0-9\+\-eE\.]+)/) {
		push (@vcrit, $value);
		next;
	    }
	    if (($name, $value) = /^ +($optmeasure) *= +([0-9\+\-eE\.]+)/) {
		push (@pass, $value);
		next;
	    }
	}
    }

    @hold = &halve_list(@hold);
    @clkslew = &halve_list(@clkslew);
    @vcrit = &halve_list(@vcrit);
    @pass = &halve_list(@pass);

    printf OUT "\n";
    printf OUT "    InputSlew\tHold_${out_trans}\t\tClock-Q\t\tCritNode\tCritPercent\n";
    printf OUT "    [s]\t\t[s]\t\t[s]\t\t[V]\n";
    printf OUT "    ----------\t----------\t----------\t----------\t----------\n";

    for ($i = 0; $i <= $#hold; $i++) {
	printf OUT "    %.4e\t%.4e\t%.4e\t%.4e\t%.4e\n",
	    $clkslew[$i], $hold[$i], $clk_q[$i], $vcrit[$i], $pass[$i];
    }

    @scaled_hold = &div_list($scale_delay, @hold);
    @scaled_clk_q = &div_list($scale_delay, @clk_q);
    @scaled_clkslew = &div_list($scale_delay, @clkslew);

    printf OUT "\n";
    printf OUT "    InputSlew\tHold_${out_trans}\t\tClock-Q\t\tCritNode\tCritPercent\n";
    printf OUT "    [scaled]\t[scaled]\t[scaled]\t[V]\n";
    printf OUT "    ----------\t----------\t----------\t----------\t----------\n";

    for ($i = 0; $i <= $#hold; $i++) {
	printf OUT "    %.4e\t%.4e\t%.4e\t%.4e\t%.4e\n",
	    $scaled_clkslew[$i], $scaled_hold[$i],
	    $scaled_clk_q[$i], $vcrit[$i], $pass[$i];
    }

    &h_save_data($cellname, $d, $clk, $clktype, (hold_ . $out_trans), \@scaled_hold);

    close SPICEOUT;
}

1;
