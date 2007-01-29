#	$Id: clock_q.pl,v 1.26 2000/02/11 00:07:23 ryu Exp $

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

#   cq_run --
#	Top-level function setup/hold characterization.
#	Generate the spice netlists, run hspice, and extract
#	data.
#
sub cq_run {

    local($d, $clktype, $clk, $qtype, $q, $tie, @tie_list) = @_;

    local($run_name);

    # check
    if (($clktype ne 'rising') && ($clktype ne 'falling')) {
	die "ERROR: clock type must be either 'rising' or 'falling'\n";
    }
    if (($qtype ne 'inverting') && ($qtype ne 'non_inverting')) {
	die "ERROR: q type must be either 'inverting' or 'non_inverting'\n";
    }

    $run_name = &run_file_name($cellname, $clk, $q, 'cq');
    open(SPICEIN,">$run_name") || die "ERROR:  Cannot open file '$run_name'.";

    # Create the hspice netlist(s)
    &print_header(SPICEIN, '*');
    printf SPICEIN "*	Char:	D-Flop Clock-Q Characterization\n";
    printf SPICEIN "*	Data:	\"$d\"\n";
    printf SPICEIN "*	Clock:	\"$clk\"\n";
    printf SPICEIN "*	Q:	\"$q\"\n";

    &cq_print_setup (SPICEIN);
    &cq_print_source (SPICEIN, $clktype, $qtype);
    &cq_print_dut (SPICEIN, $d, $clk, $q, $tie, @tie_list);
    &cq_print_measure (SPICEIN, $clktype, $qtype);
    &cq_print_trans (SPICEIN, $clktype);
    &cq_print_alter (SPICEIN);

    printf SPICEIN ".end\n";
    close(SPICEIN);

    &run_spice($run_name);

    &cq_report_spice($run_name, $d, $clktype, $clk, $qtype, $q);
}


sub cq_print_setup {

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
    printf $fp "$trans_options\n";

    if ($spice_type eq 'smartspice') {
	printf $fp "$smartspice_options\n";
    }

    printf $fp ".param setup = 'pwidth'\n" ;
    printf $fp ".param cload = '$cload[0]'\n" ;
}


sub cq_print_source {

    my ($fp, $clktype, $qtype) = @_;

    printf $fp "\n*--- INPUTS --------------------------------------------------\n";

    if ($clktype eq 'rising') {

	printf $fp "vclk0 vclk0 $low_value pulse (
+	'$low_value'
+	'$high_value'
+	'$trans_delay'
+	'$trans_risetime'
+	'$trans_falltime'
+	'$trans_pulse_width'
+	'$trans_period')\n";
	printf $fp "vclk1 vclk1 $low_value pulse (
+	'$low_value'
+	'$high_value'
+	'$trans_delay'
+	'$trans_risetime'
+	'$trans_falltime'
+	'$trans_pulse_width'
+	'$trans_period')\n";

    } elsif ($clktype eq 'falling') {

	printf $fp "vclk0 vclk0 $low_value pulse (
+	'$high_value'
+	'$low_value'
+	'$trans_delay'
+	'$trans_risetime'
+	'$trans_falltime'
+	'$trans_pulse_width'
+	'$trans_period')\n";
	printf $fp "vclk1 vclk1 $low_value pulse (
+	'$high_value'
+	'$low_value'
+	'$trans_delay'
+	'$trans_risetime'
+	'$trans_falltime'
+	'$trans_pulse_width'
+	'$trans_period')\n";

    } else {
	die "ERROR: unknown clock transition type '$clktype'\n";
    }

    printf $fp "vd0 vd0 $low_value pulse (
+	'$low_value'
+	'$high_value'
+	'$trans_delay+$trans_risetime+2*$trans_pulse_width+$trans_falltime-setup'
+	'$trans_risetime'
+	'$trans_falltime'
+	'3*$trans_period'
+	'4*$trans_period')\n";
    printf $fp "vd1 vd1 $low_value pulse (
+	'$high_value'
+	'$low_value'
+	'$trans_delay+$trans_risetime+2*$trans_pulse_width+$trans_falltime-setup'
+	'$trans_risetime'
+	'$trans_falltime'
+	'3*$trans_period'
+	'4*$trans_period')\n";

}


sub cq_print_dut {

    my($fp, $d, $clk, $q, $tie, $tie_list) = @_;
    my($term, $termname, $termtype);
    my($dbuf, $clkbuf, $outload, $vcvs);
    local($term_no, @vcvs_list, @output_loads);
    my(@inlist, @reflist);

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
    @inlist = ($d, $clk);

    printf $fp "\n*--- TEST CIRCUIT --------------------------------------------\n";

    if ($dbuf eq 'none') {
	printf $fp "vshortd0 vd0 d0 DC 0\n";
	printf $fp "vshortd1 vd1 d1 DC 0\n";
    } else {
	printf $fp "xdbuf0 vd0 d0 $dbuf\n";
	printf $fp "xdbuf1 vd1 d1 $dbuf\n";
    }
    if ($clkbuf eq 'none') {
	printf $fp "vshortclk0 vclk0 clk0 DC 0\n";
	printf $fp "vshortclk1 vclk1 clk1 DC 0\n";
    } else {
	printf $fp "xclkbuf0 vclk0 clk0 $clkbuf\n";
	printf $fp "xclkbuf1 vclk1 clk1 $clkbuf\n";
    }

    printf $fp "xflop0\n";
    @reflist = ('d0', 'clk0');
    foreach $term (@termlist) {
	($termname, $termtype) = split(':', $term);
	if ($termname eq $d) {
	    printf $fp "+\td0\t\$ $term\n";
	    next;
	}
	if ($termname eq $clk) {
	    printf $fp "+\tclk0\t\$ $term\n";
	    next;
	}
	if ($termname eq $q) {
	    printf $fp "+\tq0\t\$ $term\n";
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

    printf $fp "xflop1\n";
    @reflist = ('d1', 'clk1');
    foreach $term (@termlist) {
	($termname, $termtype) = split(':', $term);
	if ($termname eq $d) {
	    printf $fp "+\td1\t\$ $term\n";
	    next;
	}
	if ($termname eq $clk) {
	    printf $fp "+\tclk1\t\$ $term\n";
	    next;
	}
	if ($termname eq $q) {
	    printf $fp "+\tq1\t\$ $term\n";
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
    printf $fp "cload0 q0 $low_value cload\n";
    printf $fp "cload1 q1 $low_value cload\n";
    # if any
    foreach $outload (@output_loads) {
	printf $fp "$outload\n";
    }
}


sub cq_print_measure {

    my($fp, $clktype, $qtype) = @_;

    printf $fp "\n*--- MEASURE -------------------------------------------------\n";
    printf $fp ".option autostop\n";

    printf $fp "\n* Measure clock->q time:\n";
    if ($qtype eq 'non_inverting') {
	if ($clktype eq 'rising') {
	    printf $fp ".measure tran clk_q_lh %s v(clk0) val='$input_prop_r' rise=1\n",
		&trig_word();
	    printf $fp "+\ttarg=v(q0) val='$output_prop_r' rise=1\n";
	    printf $fp ".measure tran clk_q_hl %s v(clk1) val='$input_prop_r' rise=1\n",
		&trig_word();
	    printf $fp "+\ttarg=v(q1) val='$output_prop_f' fall=1\n";
	} else {
	    printf $fp ".measure tran clk_q_lh %s v(clk0) val='$input_prop_f' fall=1\n",
		&trig_word();
	    printf $fp "+\ttarg=v(q0) val='$output_prop_r' rise=1\n";
	    printf $fp ".measure tran clk_q_hl %s v(clk1) val='$input_prop_f' fall=1\n",
		&trig_word();
	    printf $fp "+\ttarg=v(q1) val='$output_prop_f' fall=1\n";
	}
	printf $fp
	    ".measure tran risetime %s v(q0) val='$trans_r1' rise=1\n",
	    &trig_word();
	printf $fp
	    "+\ttarg=v(q0) val='$trans_r2' rise=1\n";
	printf $fp
	    ".measure tran falltime %s v(q1) val='$trans_f1' fall=1\n",
	    &trig_word();
	printf $fp
	    "+\ttarg=v(q1) val='$trans_f2' fall=1\n";
    } else {
	if ($clktype eq 'rising') {
	    printf $fp ".measure tran clk_q_lh %s v(clk1) val='$input_prop_r' rise=1\n",
		&trig_word();
	    printf $fp "+\ttarg=v(q1) val='$output_prop_r' rise=1\n";
	    printf $fp ".measure tran clk_q_hl %s v(clk0) val='$input_prop_r' rise=1\n",
		&trig_word();
	    printf $fp "+\ttarg=v(q0) val='$output_prop_f' fall=1\n";
	} else {
	    printf $fp ".measure tran clk_q_lh %s v(clk1) val='$input_prop_f' fall=1\n",
		&trig_word();
	    printf $fp "+\ttarg=v(q1) val='$output_prop_r' rise=1\n";
	    printf $fp ".measure tran clk_q_hl %s v(clk0) val='$input_prop_f' fall=1\n",
		&trig_word();
	    printf $fp "+\ttarg=v(q0) val='$output_prop_f' fall=1\n";
	}
	printf $fp
	    ".measure tran risetime %s v(q1) val='$trans_r1' rise=1\n",
	    &trig_word();
	printf $fp
	    "+\ttarg=v(q1) val='$trans_r2' rise=1\n";
	printf $fp
	    ".measure tran falltime %s v(q0) val='$trans_f1' fall=1\n",
	    &trig_word();
	printf $fp
	    "+\ttarg=v(q0) val='$trans_f2' fall=1\n";
    }
}


sub cq_print_trans {

    my($fp, $clktype) = @_;

    printf $fp "\n*--- TRANSIENT -----------------------------------------------\n";
    printf $fp ".trans $trans_timestep '$trans_timestop' start='$trans_delay+$trans_pulse_width'\n";

}

sub cq_print_alter {

    my($fp) = @_;
    my($i);

    printf $fp "\n*--- ALTER ---------------------------------------------------\n";
    #foreach $c (@cload) {
    for ($i = 1; $i <= $#cload; $i++) {
	printf $fp ".alter\n";
	printf $fp ".param cload = '$cload[$i]'\n\n" ;
    }
}


sub cq_report_spice {

    my  ($run_name, $d, $clktype, $clk, $qtype, $q) = @_;

    my($base,$dir,$ext,$spiceout);
    local(@clk_q_lh, @clk_q_hl, @risetime, @falltime, @creal);

    ($base,$dir,$ext) = fileparse($run_name, '\.sp');
    $spiceout = $base . '.out';

    printf STDERR "Extracting results from '$spiceout' ...\n";

    # grab the last values
    open(SPICEOUT, $spiceout) || die "ERROR: Cannot find '$spiceout'.\n";
    while (<SPICEOUT>) {
	if (($name, $value) = /^ *(clk_q_lh) *= +([0-9\+\-eE\.]+)/) {
	    push(@clk_q_lh, $value);
	}
	if (($name, $value) = /^ *(clk_q_hl) *= +([0-9\+\-eE\.]+)/) {
	    push(@clk_q_hl, $value);
	}
	if (($name, $value) = /^ *(risetime) *= +([0-9\+\-eE\.]+)/) {
	    push(@risetime, $value);
	}
	if (($name, $value) = /^ *(falltime) *= +([0-9\+\-eE\.]+)/) {
	    push(@falltime, $value);
	}
    }
    close SPICEOUT;

    printf OUT "### CLOCK to Q #############################################################\n\n";
    printf OUT "Cellname:\t\"$cellname\"\n";
    printf OUT "D Input:\t\"$d\"\n";
    printf OUT "Clock Input:\t\"$clk\"\t($clktype)\n";
    printf OUT "Q Output:\t\"$q\"\t($qtype)\n";

    # change to real numbers
    @creal = &convert_spice_values(@cload);

    printf OUT "\n";
    &cq_report_spice_1(0);

    # report it again, this time scaled.
    if (($scale_cload != 1) || ($scale_delay != 1)) {

	@creal = &div_list($scale_cload, @creal);
	@clk_q_lh = &div_list($scale_delay, @clk_q_lh);
	@clk_q_hl = &div_list($scale_delay, @clk_q_hl);
	@risetime = &div_list($scale_delay, @risetime);
	@falltime = &div_list($scale_delay, @falltime);

	printf OUT "\n    Scaled:\n\n";
	&cq_report_spice_1(1);
	printf OUT "\n\n";
    }

    &cq_save_data($cellname, $clk, $q, $clktype,
	\@creal, \@clk_q_lh, \@clk_q_hl, \@risetime, \@falltime);
}


#
#   cq_report_spice_1 --
#	Code fragment, called by cq_report_spice only.
#
sub cq_report_spice_1 {
    my($scaled) = @_;
    my($i);

    my($risetimea, $risetimeb, $risetimer2);
    my($falltimea, $falltimeb, $falltimer2);
    my($clk_q_lha, $clk_q_lhb, $clk_q_lhr2);
    my($clk_q_hla, $clk_q_hlb, $clk_q_hlr2);

    if ($#clk_q_lh == $#creal) {
	($clk_q_lha, $clk_q_lhb, $clk_q_lhr2) = &svlinreg('lin', \@creal, \@clk_q_lh);
    }
    if ($#clk_q_hl == $#creal) {
	($clk_q_hla, $clk_q_hlb, $clk_q_hlr2) = &svlinreg('lin', \@creal, \@clk_q_hl);
    }
    if ($#risetime == $#creal) {
	($risetimea, $risetimeb, $risetimer2) = &svlinreg('lin', \@creal, \@risetime);
    }
    if ($#falltime == $#creal) {
	($falltimea, $falltimeb, $falltimer2) = &svlinreg('lin', \@creal, \@falltime);
    }

    if ($debug) {
	&dump_list (creal, @creal);
	&dump_list (clk_q_lh, @clk_q_lh);
	&dump_list (clk_q_hl, @clk_q_hl);
	&dump_list (risetime, @risetime);
	&dump_list (falltime, @falltime);
    }

    printf OUT "    Cload\tClk_Q_lh\tClk_Q_hl\tRiseTime\tFallTime\n";
    printf OUT "    [F]\t\t[s]\t\t[s]\t\t[s]\t\t[s]\n" unless $scaled;
    printf OUT "    ----------\t----------\t----------\t----------\t----------\n";
    for ($i = 0; $i <= $#creal; $i++) {
	printf OUT "    %.4e\t%.4e\t%.4e\t%.4e\t%.4e\n",
	    $creal[$i], $clk_q_lh[$i], $clk_q_hl[$i], $risetime[$i], $falltime[$i];

    }
    printf OUT "\n";
    printf OUT "    Clk_Q_lh\t= %.4e + %.4e * Cload\t(r2=%.4f)\n",
	$clk_q_lha, $clk_q_lhb, $clk_q_lhr2;
    printf OUT "    Clk_Q_hl\t= %.4e + %.4e * Cload\t(r2=%.4f)\n",
	$clk_q_hla, $clk_q_hlb, $clk_q_hlr2;
    printf OUT "    Risetime\t= %.4e + %.4e * Cload\t(r2=%.4f)\n",
	$risetimea, $risetimeb, $risetimer2;
    printf OUT "    Falltime\t= %.4e + %.4e * Cload\t(r2=%.4f)\n",
	$falltimea, $falltimeb, $falltimer2;
}



1;
