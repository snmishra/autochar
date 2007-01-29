#	$Id: clock_gate.pl,v 1.6 2000/02/11 00:07:23 ryu Exp $

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

#   cg_run --
#	Top-level function setup/hold characterization.
#	Generate the spice netlists, run hspice, and extract
#	data.
#
sub cg_run {
    local($cetype, $ce, $clktype, $clk, $clkouttype, $clkout, $ctype, $c, $tie, @tie_list) = @_;

    printf OUT "### CLOCK ENABLE ###########################################################\n\n";
    printf OUT "Cellname:\t\"$cellname\"\n";
    printf OUT "Clock Enable:\t\"$ce\"\t($cetype)\n";
    printf OUT "Clock Input:\t\"$clk\"\t($clktype)\n";
    printf OUT "Clock Output:\t\"$clkout\"\t($clkouttype)\n";
    printf OUT "Critical Node:\t\"$c\"\t($ctype)\n\n";

    # enable setup
    &cgs_run ('lh', $cetype, $ce, $clktype, $clk, $clkouttype, $clkout, $ctype, $c, $tie, @tie_list);
    &cgs_run ('hl', $cetype, $ce, $clktype, $clk, $clkouttype, $clkout, $ctype, $c, $tie, @tie_list);

    # enable hold
    &cgh_run ('lh', $cetype, $ce, $clktype, $clk, $clkouttype, $clkout, $ctype, $c, $tie, @tie_list);
    &cgh_run ('hl', $cetype, $ce, $clktype, $clk, $clkouttype, $clkout, $ctype, $c, $tie, @tie_list);
}


#------ CLOCK ENABLE SETUP TIME CHARACTERIZATION -------------------------------

sub cgs_run {

    my($out_trans, $cetype, $ce, $clktype, $clk, $clkouttype, $clkout, $ctype, $c, $tie, @tie_list) = @_;

    local($run_name, $clktrans);
    local($optmod, $optparam, $optmeasure);

    # check
    if (($cetype ne 'active_high') && ($cetype ne 'active_low')) {
	die "ERROR: clock enable type must be either 'active_high' or 'active_low'\n";
    }
    if (($clktype ne 'rising') && ($clktype ne 'falling')) {
	die "ERROR: clock type must be either 'rising' or 'falling'\n";
    }
    if (($clkouttype ne 'inverting') && ($clkouttype ne 'non_inverting')) {
	die "ERROR: clkout type must be either 'inverting' or 'non_inverting'\n";
    }

    # give names to these puppies
    $optmod = 'optmod';
    $optparam = 'optsetup';
    $optmeasure = 'optpass';

    $run_name = &run_file_name($cellname, $ce, $clk, $clkout, 'cgs');
    open(SPICEIN,">$run_name") || die "ERROR:  Cannot open file '$run_name'.";

    # Create the hspice netlist(s)
    &print_header(SPICEIN, '*');
    printf SPICEIN "*	Char:	Gate Clock Enable Setup Time Characterization\n";
    printf SPICEIN "*	Enable:	\"$ce\"\n";
    printf SPICEIN "*	Clock:	\"$clk\"\n";
    printf SPICEIN "*	Clkout:	\"$clkout\"\n";
    printf SPICEIN "*	C:	\"$c\"\n";
    printf SPICEIN "*	Trans:	\"$out_trans\"\n";

    &cgs_print_setup (SPICEIN);
    &cgs_print_source (SPICEIN, $cetype, $clktype, $out_trans, $clkouttype);
    &cgs_print_dut (SPICEIN, $ce, $clk, $clkout, $tie, @tie_list);
    &cgs_print_measure (SPICEIN, $clktype, $out_trans, $ctype, $c);
    &cgs_print_trans (SPICEIN, $clktype, $out_trans);

    printf SPICEIN ".end\n";
    close(SPICEIN);

    &run_spice($run_name);

    &cgs_report_spice($run_name, $out_trans, $ce, $clktype, $clk, $clkouttype, $clkout, $ctype, $c);
}


sub cgs_print_setup {

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
	printf $fp "+\trelin=$relin\n";
	printf $fp "+\trelout=$relout\n";
	printf $fp ".param setup = $optparam('$setup_range[0]', '$setup_range[0]', '$setup_range[1]')\n" ;
    }

    if ($#slewrate != -1) {
	printf $fp ".param slewrate = '$slewrate[0]'\n" ;
	printf $fp ".param slew_start = '$start_slew_percent'\n" ;
	printf $fp ".param slew_end = '$end_slew_percent'\n" ;
    }
}


#	Modifies clktrans
#
sub cgs_print_source {

    my ($fp, $cetype, $clktype, $out_trans, $clkouttype) = @_;

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

    if ( (($out_trans eq 'lh') && ($clkouttype eq 'non_inverting')) ||
	 (($out_trans eq 'hl') && ($clkouttype eq 'inverting')) ) {
	$clktrans = 'rise';
    } elsif ( (($out_trans eq 'hl') && ($clkouttype eq 'non_inverting')) ||
	      (($out_trans eq 'lh') && ($clkouttype eq 'inverting')) ) {
	$clktrans = 'fall';
    } else {
	die "ERROR: unknown combination of '$out_trans' and '$clkouttype'\n";
    }

    if ($cetype eq 'active_high') {
	printf $fp "vce vce $low_value pulse (
+	'$high_value'
+	'$low_value'
+	'$trans_delay+$trans_risetime+$trans_pulse_width/2'
+	'$trans_risetime'
+	'$trans_falltime'
+	'$trans_period-$trans_risetime-$trans_pulse_width/2-setup'
+	'4*$trans_period')\n";
    } elsif ($cetype eq 'active_low') {
	printf $fp "vce vce $low_value pulse (
+	'$low_value'
+	'$high_value'
+	'$trans_delay+$trans_risetime+$trans_pulse_width/2'
+	'$trans_risetime'
+	'$trans_falltime'
+	'$trans_period-$trans_risetime-$trans_pulse_width/2-setup'
+	'4*$trans_period')\n";
    }
}


sub cgs_print_dut {

    my($fp, $ce, $clk, $clkout, $tie, $tie_list) = @_;
    my($term, $termname, $termtype);
    my($clkbuf, $cebuf, $outload);
    my($vcvs);
    local($term_no, @vcvs_list, @output_loads);
    my(@inlist, @reflist);

    $term_no = 0;

    if ($buffer{$ce} ne '') {
	$cebuf = $buffer{$ce};
    } else {
	$cebuf = $buffer{'default'};
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

    @inlist = ($ce, $clk);
    @reflist = ('ce', 'clk');

    if ($cebuf eq 'none') {
	printf $fp "vshortce vce ce DC 0\n";
    } else {
	printf $fp "xcebuf vce ce $clkbuf\n";
    }
    if ($clkbuf eq 'none') {
	printf $fp "vshortclk vclk clk DC 0\n";
    } else {
	printf $fp "xclkbuf vclk clk $clkbuf\n";
    }

    printf $fp "xgateclk\n";
    foreach $term (@termlist) {
	($termname, $termtype) = split(':', $term);
	if ($termname eq $ce) {
	    printf $fp "+\tce\t\$ $term\n";
	    next;
	}
	if ($termname eq $clk) {
	    printf $fp "+\tclk\t\$ $term\n";
	    next;
	}
	if ($termname eq $clkout) {
	    printf $fp "+\t%s\t\$ $term\n", &lookup_output_load($termname, 'clkout');
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


sub cgs_print_measure {

    my($fp, $clktype, $out_trans, $ctype, $c) = @_;

    printf $fp "\n*--- MEASURE -------------------------------------------------\n";
    printf $fp ".option autostop\n";

    printf $fp "* Measure setup time:\n";

    if ($spice_type eq 'smartspice') {
	printf $fp ".measure tran isetup param='isetup'\n";
	printf $fp ".measure tran setup param='setup'\n";
    }

    printf $fp ".measure tran setup_${out_trans} %s v(ce) val='$midpoint_value' cross=2\n",
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
    printf $fp ".measure tran vcrit find v(xgateclk.${c})\n";
    if ($clktype eq 'rising') {
	printf $fp "+\twhen v(clk)='$clock_percent*$high_value' rise=2\n"; 
    } else {
	printf $fp "+\twhen v(clk)='(1-$clock_percent)*$high_value' fall=2\n"; 
    }

    # cnode:
    if ( (($clktrans eq 'rise') && ($ctype eq 'inverting')) ||
	 (($clktrans eq 'fall') && ($ctype eq 'non_inverting')) ) {
	printf $fp ".measure tran $optmeasure param='($high_value-vcrit)/$high_value'\n";
	if ($spice_type ne 'smartspice') {
	    printf $fp "+\tgoal='${criterion_percent}'\n";
	}
    } elsif ( (($clktrans eq 'fall') && ($ctype eq 'inverting')) ||
	      (($clktrans eq 'rise') && ($ctype eq 'non_inverting')) ) {
	printf $fp ".measure tran $optmeasure param='vcrit/$high_value'\n";
	if ($spice_type ne 'smartspice') {
	    printf $fp "+\tgoal='${criterion_percent}'\n";
	}
    }
}


sub cgs_print_trans {

    my($fp, $clktype, $out_trans) = @_;
    my($j);

    printf $fp "\n*--- TRANSIENT -----------------------------------------------\n";
    if ($spice_type eq 'smartspice') {

	printf $fp "* Measure final clock->clkout time:\n";
	if ($clktype eq 'rising') {
	    printf $fp ".measure tran clk_clkout delay v(clk) val='$midpoint_value' rise=2\n";
	} else {
	    printf $fp ".measure tran clk_clkout delay v(clk) val='$midpoint_value' fall=2\n";
	}
	if ($out_trans eq 'lh') {
	    printf $fp "+\ttarg=v(clkout) val='$midpoint_value' rise=2\n";
	} elsif ($out_trans eq 'hl') {
	    printf $fp "+\ttarg=v(clkout) val='$midpoint_value' fall=2\n";
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
	printf $fp "\n* Measure final clock->clkout time:\n";
	if ($clktype eq 'rising') {
	    printf $fp ".measure tran clk_clkout trig=v(clk) val='$midpoint_value' rise=2\n";
	} else {
	    printf $fp ".measure tran clk_clkout trig=v(clk) val='$midpoint_value' fall=2\n";
	}

	if ($out_trans eq 'lh') {
	    printf $fp "+\ttarg=v(clkout) val='$midpoint_value' rise=2\n";
	} elsif ($out_trans eq 'hl') {
	    printf $fp "+\ttarg=v(clkout) val='$midpoint_value' fall=2\n";
	} else {
	    die "ERROR: unknown output transition '$out_trans'\n";
	}
    }

    if ($spice_type eq 'smartspice') {
	# common with setup_hold module
	&s_print_control($fp, $out_trans);
    }

    printf $fp "\n* Alter slewrate:\n";
    for ($j = 1; $j <= $#slewrate; $j++) {
	printf $fp ".alter\n";
	printf $fp ".param slewrate = '$slewrate[$j]'\n" ;
    }
}


sub cgs_report_spice {

    my  ($run_name, $out_trans, $ce, $clktype, $clk, $clkouttype, $clkout, $ctype, $c) = @_;

    my($base,$dir,$ext,$spiceout);
    my(@setup, @clkslew, @clk_clkout, @vcrit, @pass);
    my(@scaled_setup, @scaled_clkslew, @scaled_clk_clkout, $i);

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
	    if (($name, $value) = /^Final (clk_clkout) *= +([0-9\+\-eE\.]+)/) {
		push (@clk_clkout, $value);
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
	    if (($name, $value) = /^ +(clk_clkout) *= +([0-9\+\-eE\.]+)/) {
		push (@clk_clkout, $value);
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
    printf OUT "    InputSlew\tSetup_${out_trans}\tClock-Clkout\tCritNode\tCritPercent\n";
    printf OUT "    [s]\t\t[s]\t\t[s]\t\t[V]\n";
    printf OUT "    ----------\t----------\t----------\t----------\t----------\n";

    for ($i = 0; $i <= $#setup; $i++) {
	printf OUT "    %.4e\t%.4e\t%.4e\t%.4e\t%.4e\n",
	    $clkslew[$i], $setup[$i], $clk_clkout[$i], $vcrit[$i], $pass[$i];
    }

    @scaled_setup = &div_list($scale_delay, @setup);
    @scaled_clk_clkout = &div_list($scale_delay, @clk_clkout);
    @scaled_clkslew = &div_list($scale_delay, @clkslew);

    printf OUT "\n";
    printf OUT "    InputSlew\tSetup_${out_trans}\tClock-Clkout\tCritNode\tCritPercent\n";
    printf OUT "    [scaled]\t[scaled]\t[scaled]\t[V]\n";
    printf OUT "    ----------\t----------\t----------\t----------\t----------\n";

    for ($i = 0; $i <= $#setup; $i++) {
	printf OUT "    %.4e\t%.4e\t%.4e\t%.4e\t%.4e\n",
	    $scaled_clkslew[$i], $scaled_setup[$i],
	    $scaled_clk_clkout[$i], $vcrit[$i], $pass[$i];
    }
    printf OUT "\n\n";

    &cgs_save_data($cellname, $ce, $cetype, $clk, $clktype, ('setup_' . $out_trans),
	\@scaled_setup);

    close SPICEOUT;
}

#------ CLOCK ENABLE HOLD TIME CHARACTERIZATION --------------------------------

sub cgh_run {

    my($out_trans, $cetype, $ce, $clktype, $clk, $clkouttype, $clkout, $ctype, $c, $tie, @tie_list) = @_;

    local($run_name, $clktrans);
    local($optmod, $optparam, $optmeasure);

    # check
    if (($cetype ne 'active_high') && ($cetype ne 'active_low')) {
	die "ERROR: clock enable type must be either 'active_high' or 'active_low'\n";
    }
    if (($clktype ne 'rising') && ($clktype ne 'falling')) {
	die "ERROR: clock type must be either 'rising' or 'falling'\n";
    }
    if (($clkouttype ne 'inverting') && ($clkouttype ne 'non_inverting')) {
	die "ERROR: clkout type must be either 'inverting' or 'non_inverting'\n";
    }

    # give names to these puppies
    $optmod = 'optmod';
    $optparam = 'opthold';
    $optmeasure = 'optpass';

    $run_name = &run_file_name($cellname, $ce, $clk, $clkout, 'cgh');
    open(SPICEIN,">$run_name") || die "ERROR:  Cannot open file '$run_name'.";

    # Create the hspice netlist(s)
    &print_header(SPICEIN, '*');
    printf SPICEIN "*	Char:	Gated Clock Enable Hold Time Characterization\n";
    printf SPICEIN "*	Enable:	\"$ce\"\n";
    printf SPICEIN "*	Clock:	\"$clk\"\n";
    printf SPICEIN "*	Clkout:	\"$clkout\"\n";
    printf SPICEIN "*	C:	\"$c\"\n";
    printf SPICEIN "*	Trans:	\"$out_trans\"\n";

    &cgh_print_setup (SPICEIN);
    &cgh_print_source (SPICEIN, $cetype, $clktype, $out_trans, $clkouttype);
    &cgh_print_dut (SPICEIN, $ce, $clk, $clkout, $tie, @tie_list);
    &cgh_print_measure (SPICEIN, $clktype, $out_trans, $ctype, $c);
    &cgh_print_trans (SPICEIN, $clktype, $out_trans);

    printf SPICEIN ".end\n";
    close(SPICEIN);

    &run_spice($run_name);

    &cgh_report_spice($run_name, $out_trans, $ce, $clktype, $clk, $clkouttype, $clkout, $ctype, $c);
}


sub cgh_print_setup {

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


#	Modifies clktrans
#
sub cgh_print_source {

    my ($fp, $cetype, $clktype, $out_trans, $clkouttype) = @_;

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

    if ( (($out_trans eq 'lh') && ($clkouttype eq 'non_inverting')) ||
	 (($out_trans eq 'hl') && ($clkouttype eq 'inverting')) ) {
	$clktrans = 'rise';
    } elsif ( (($out_trans eq 'hl') && ($clkouttype eq 'non_inverting')) ||
	      (($out_trans eq 'lh') && ($clkouttype eq 'inverting')) ) {
	$clktrans = 'fall';
    } else {
	die "ERROR: unknown combination of '$out_trans' and '$clkouttype'\n";
    }

    if ($cetype eq 'active_high') {
	printf $fp "vce vce $low_value pulse (
+	'$high_value'
+	'$low_value'
+	'$trans_delay+$trans_period+hold'
+	'$trans_risetime'
+	'$trans_falltime'
+	'3*$trans_period'
+	'4*$trans_period')\n";
    } elsif ($cetype eq 'active_low') {
	printf $fp "vce vce $low_value pulse (
+	'$low_value'
+	'$high_value'
+	'$trans_delay+$trans_period+hold'
+	'$trans_risetime'
+	'$trans_falltime'
+	'3*$trans_period'
+	'4*$trans_period')\n";
    }
}


sub cgh_print_dut {

    my($fp, $ce, $clk, $clkout, $tie, $tie_list) = @_;
    my($term, $termname, $termtype);
    my($clkbuf, $outload);
    my($vcvs);
    local($term_no, @vcvs_list, @output_loads);
    my(@inlist, @reflist);

    $term_no = 0;

    if ($buffer{$ce} ne '') {
	$cebuf = $buffer{$ce};
    } else {
	$cebuf = $buffer{'default'};
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

    @inlist = ($ce, $clk);
    @reflist = ('ce', 'clk');

    if ($cebuf eq 'none') {
	printf $fp "vshortce vce ce DC 0\n";
    } else {
	printf $fp "xcebuf vce ce $clkbuf\n";
    }
    if ($clkbuf eq 'none') {
	printf $fp "vshortclk vclk clk DC 0\n";
    } else {
	printf $fp "xclkbuf vclk clk $clkbuf\n";
    }

    printf $fp "xgateclk\n";
    foreach $term (@termlist) {
	($termname, $termtype) = split(':', $term);
	if ($termname eq $ce) {
	    printf $fp "+\tce\t\$ $term\n";
	    next;
	}
	if ($termname eq $clk) {
	    printf $fp "+\tclk\t\$ $term\n";
	    next;
	}
	if ($termname eq $clkout) {
	    printf $fp "+\t%s\t\$ $term\n", &lookup_output_load($termname, 'clkout');
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


sub cgh_print_measure {

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
    printf $fp "+\ttarg=v(ce) val='$midpoint_value' cross=1\n";

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
    printf $fp ".measure tran vcrit find v(xgateclk.${c})\n";
    if ($clktype eq 'rising') {
	printf $fp "+\twhen v(clk)='$clock_percent*$high_value' rise=2\n"; 
    } else {
	printf $fp "+\twhen v(clk)='(1-$clock_percent)*$high_value' fall=2\n"; 
    }

    # cnode:
    if ( (($clktrans eq 'rise') && ($ctype eq 'inverting')) ||
	 (($clktrans eq 'fall') && ($ctype eq 'non_inverting')) ) {
	printf $fp ".measure tran $optmeasure param='($high_value-vcrit)/$high_value'\n";
	if ($spice_type ne 'smartspice') {
	    printf $fp "+\tgoal='${criterion_percent}'\n";
	}
    } elsif ( (($clktrans eq 'fall') && ($ctype eq 'inverting')) ||
	      (($clktrans eq 'rise') && ($ctype eq 'non_inverting')) ) {
	printf $fp ".measure tran $optmeasure param='vcrit/$high_value'\n";
	if ($spice_type ne 'smartspice') {
	    printf $fp "+\tgoal='${criterion_percent}'\n";
	}
    }
}


sub cgh_print_trans {

    my($fp, $clktype, $out_trans) = @_;

    printf $fp "\n*--- TRANSIENT -----------------------------------------------\n";
    if ($spice_type eq 'smartspice') {

	printf $fp "* Measure final clock->clkout time:\n";
	if ($clktype eq 'rising') {
	    printf $fp ".measure tran clk_clkout delay v(clk) val='$midpoint_value' rise=2\n";
	} else {
	    printf $fp ".measure tran clk_clkout delay v(clk) val='$midpoint_value' fall=2\n";
	}
	if ($out_trans eq 'lh') {
	    printf $fp "+\ttarg=v(clkout) val='$midpoint_value' rise=2\n";
	} elsif ($out_trans eq 'hl') {
	    printf $fp "+\ttarg=v(clkout) val='$midpoint_value' fall=2\n";
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
	printf $fp "\n* Measure final clock->clkout time:\n";
	if ($clktype eq 'rising') {
	    printf $fp ".measure tran clk_clkout trig=v(clk) val='$midpoint_value' rise=2\n";
	} else {
	    printf $fp ".measure tran clk_clkout trig=v(clk) val='$midpoint_value' fall=2\n";
	}

	if ($out_trans eq 'lh') {
	    printf $fp "+\ttarg=v(clkout) val='$midpoint_value' rise=2\n";
	} elsif ($out_trans eq 'hl') {
	    printf $fp "+\ttarg=v(clkout) val='$midpoint_value' fall=2\n";
	} else {
	    die "ERROR: unknown output transition '$out_trans'\n";
	}
    }

    if ($spice_type eq 'smartspice') {
	# common with setup_hold module
	&h_print_control($fp, $out_trans);
    }

    printf $fp "\n* Alter slewrate:\n";
    for ($j = 1; $j <= $#slewrate; $j++) {
	printf $fp ".alter\n";
	printf $fp ".param slewrate = '$slewrate[$j]'\n" ;
    }
}


sub cgh_report_spice {

    my  ($run_name, $out_trans, $ce, $clktype, $clk, $clkouttype, $clkout, $ctype, $c) = @_;

    my($base,$dir,$ext,$spiceout);
    my(@hold, @clkslew, @clk_clkout, @vcrit, @pass);
    my(@scaled_hold, @scaled_clkslew, @scaled_clk_clkout, $i);

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
	    if (($name, $value) = /^Final (clk_clkout) *= +([0-9\+\-eE\.]+)/) {
		push (@clk_clkout, $value);
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
	    if (($name, $value) = /^ +(clk_clkout) *= +([0-9\+\-eE\.]+)/) {
		push(@clk_clkout, $value);
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
    printf OUT "    InputSlew\tHold_${out_trans}\t\tClock-Clkout\tCritNode\tCritPercent\n";
    printf OUT "    [s]\t\t[s]\t\t[s]\t\t[V]\n";
    printf OUT "    ----------\t----------\t----------\t----------\t----------\n";

    for ($i = 0; $i <= $#hold; $i++) {
	printf OUT "    %.4e\t%.4e\t%.4e\t%.4e\t%.4e\n",
	    $clkslew[$i], $hold[$i], $clk_clkout[$i], $vcrit[$i], $pass[$i];
    }

    @scaled_hold = &div_list($scale_delay, @hold);
    @scaled_clk_clkout = &div_list($scale_delay, @clk_clkout);
    @scaled_clkslew = &div_list($scale_delay, @clkslew);

    printf OUT "\n";
    printf OUT "    InputSlew\tHold_${out_trans}\t\tClock-Clkout\tCritNode\tCritPercent\n";
    printf OUT "    [scaled]\t[scaled]\t[scaled]\t[V]\n";
    printf OUT "    ----------\t----------\t----------\t----------\t----------\n";

    for ($i = 0; $i <= $#hold; $i++) {
	printf OUT "    %.4e\t%.4e\t%.4e\t%.4e\t%.4e\n",
	    $scaled_clkslew[$i], $scaled_hold[$i],
	    $scaled_clk_clkout[$i], $vcrit[$i], $pass[$i];
    }
    printf OUT "\n\n";

    &cgh_save_data($cellname, $ce, $cetype, $clk, $clktype, (hold_ . $out_trans),
	\@scaled_hold);

    close SPICEOUT;
}


1;
