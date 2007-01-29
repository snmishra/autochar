#	$Id: load_delay.pl,v 1.41 2000/02/11 00:07:23 ryu Exp $

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

#
#   ld_run --
#	Top-level function to load delay characterization.
#	Generate the spice netlists, run hspice, and extract
#	data.
#
sub ld_run {

    local($type, $in, $out, $tie, @tie_list) = @_;
    local($run_name);

    $run_name = &run_file_name($cellname, $in, $out, 'ld');
    open(SPICEIN,">$run_name") || die "ERROR:  Cannot open file '$run_name'.";

    # Create the hspice netlist(s)
    &print_header(SPICEIN, '*');
    printf SPICEIN "*	Char:	Load Delay Characterization\n";
    printf SPICEIN "*	Type:	\"$type\"\n";
    printf SPICEIN "*	Input:	\"$in\"\n";
    printf SPICEIN "*	Output:	\"$out\"\n";

    &ld_print_setup (SPICEIN);
    &ld_print_source (SPICEIN, $type);
    &ld_print_dut (SPICEIN, $type, $in, $out, $tie, @tie_list);
    &ld_print_measure (SPICEIN, $type);
    &ld_print_trans (SPICEIN);
    &ld_print_alter (SPICEIN);

    printf SPICEIN ".end\n";
    close(SPICEIN);

    &run_spice($run_name);

    &ld_report_spice($type, $in, $out, $run_name);
}

sub ld_copy {
    my($in, $out, $refin, $refout);
}


sub ld_print_setup {

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

    printf $fp ".param cload = '$cload[0]'\n" ;

    if ($#slewrate != -1) {
	printf $fp ".param slewrate = '$slewrate[0]'\n" ;
	printf $fp ".param slew_start = '$start_slew_percent'\n" ;
	printf $fp ".param slew_end = '$end_slew_percent'\n" ;
	printf $fp ".param tau = 'slewrate/abs(log(slew_start)-log(slew_end))'\n" ;
    }
}


sub ld_print_source {

    my ($fp, $type) = @_;

    printf $fp "\n*--- INPUTS --------------------------------------------------\n";
    if (($type eq 'inverting') ||
	($type eq 'non_inverting') ||
	($type eq 'hh') ||
	($type eq 'hl')) {

	if ($#slewrate != -1) {
	    # exponential
	    printf $fp "vinr vinr $low_value exp (
+	'$low_value'
+	'$high_value'
+	'$trans_delay'
+	'tau'
+	'$trans_delay+1000*tau'
+	'tau')\n";
	} else {
	    # pulse
	    printf $fp "vinr vinr $low_value pulse (
+	'$low_value'
+	'$high_value'
+	'$trans_delay'
+	'$trans_risetime'
+	'$trans_falltime'
+	'$trans_pulse_width'
+	'$trans_period')\n";
	}
    }

    if (($type eq 'inverting') ||
	($type eq 'non_inverting') ||
	($type eq 'lh') ||
	($type eq 'll')) {

	if ($#slewrate != -1) {
	    # exponential
	    printf $fp "vinf vinf $low_value exp (
+	'$high_value'
+	'$low_value'
+	'$trans_delay'
+	'tau'
+	'$trans_delay+1000*tau'
+	'tau')\n";
	} else {
	    # pulse
	    printf $fp "vinf vinf $low_value pulse (
+	'$high_value'
+	'$low_value'
+	'$trans_delay'
+	'$trans_risetime'
+	'$trans_falltime'
+	'$trans_pulse_width'
+	'$trans_period')\n";
	}
    }
}


sub ld_print_dut {

    my($fp, $type, $in, $out, $tie, $tie_list) = @_;
    my($term, $termname, $termtype);
    my($buf, $outload);
    my($vcvs, $inlist, $reflist);
    local($term_no, @vcvs_list, @output_loads);

    $term_no = 0;

    if ($buffer{$in} ne '') {
	$buf = $buffer{$in};
    } else {
	$buf = $buffer{'default'};
    }
    if ($#slewrate != -1) {
	$buf = 'none';
	printf STDERR "INFO: no buffers used for slew rate load_delay.\n";
	#printf STDERR "INFO: using buffer '$buf' for slew rate load_delay.\n";
    }

    printf $fp "\n*--- TEST CIRCUIT --------------------------------------------\n";

    @inlist = ($in);
    if (($type eq 'inverting') ||
	($type eq 'non_inverting') ||
	($type eq 'hh') ||
	($type eq 'hl')) {

	@reflist = ('inputr');

	if ($buf eq 'none') {
	    printf $fp "vshortr vinr inputr DC 0\n";
	} else {
	    printf $fp "xbufr vinr inputr $buf\n";
	}

	printf $fp "xdut0\n";
	foreach $term (@termlist) {
	    ($termname, $termtype) = split(':', $term);
	    if ($termname eq $in) {
		printf $fp "+\tinputr\t\$ $term\n";
		next;
	    }
	    if ($termname eq $out) {
		if (($type eq 'non_inverting') || ($type eq 'hh')) {
		    printf $fp "+\toutputr\t\$ $term\n";
		} else {
		    printf $fp "+\toutputf\t\$ $term\n";
		}
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
    }

    if (($type eq 'inverting') ||
	($type eq 'non_inverting') ||
	($type eq 'lh') ||
	($type eq 'll')) {

	@reflist = ('inputf');

	if ($buf eq 'none') {
	    printf $fp "vshortf vinf inputf DC 0\n";
	} else {
	    printf $fp "xbuff vinf inputf $buf\n";
	}

	printf $fp "xdut1\n";
	foreach $term (@termlist) {
	    ($termname, $termtype) = split(':', $term);
	    if ($termname eq $in) {
		printf $fp "+\tinputf\t\$ $term\n";
		next;
	    }
	    if ($termname eq $out) {
		if (($type eq 'non_inverting') || ($type eq 'll')) {
		    printf $fp "+\toutputf\t\$ $term\n";
		} else {
		    printf $fp "+\toutputr\t\$ $term\n";
		}
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
    }

    # if any
    foreach $vcvs (@vcvs_list) {
	printf $fp "$vcvs\n";
    }

    printf $fp "\n*--- LOADS ---------------------------------------------------\n";
    if (($type eq 'inverting') ||
	($type eq 'non_inverting') ||
	($type eq 'hh') ||
	($type eq 'lh')) {
	printf $fp "cloadr outputr $low_value cload\n";
    }
    if (($type eq 'inverting') ||
	($type eq 'non_inverting') ||
	($type eq 'hl') ||
	($type eq 'll')) {
	printf $fp "cloadf outputf $low_value cload\n";
    }
    foreach $outload (@output_loads) {
	printf $fp "$outload\n";
    }
}

sub ld_print_measure {

    my($fp, $type) = @_;

    printf $fp "\n*--- MEASURE -------------------------------------------------\n";
    printf $fp ".option autostop\n";

    printf $fp "* Prop delay measurements:\n";
    if (($type eq 'non_inverting') || ($type eq 'hh')) {
	printf $fp
	    ".measure tran tplh %s v(inputr) val='$input_prop_r' rise=1\n",
	    &trig_word();
	printf $fp
	    "+\ttarg=v(outputr) val='$output_prop_r' rise=1\n";
    }
    if (($type eq 'non_inverting') || ($type eq 'll')) {
	printf $fp
	    ".measure tran tphl %s v(inputf) val='$input_prop_f' fall=1\n",
	    &trig_word();
	printf $fp
	    "+\ttarg=v(outputf) val='$output_prop_f' fall=1\n";
    }
    if (($type eq 'inverting') || ($type eq 'lh')) {
	printf $fp
	    ".measure tran tplh %s v(inputf) val='$input_prop_f' fall=1\n",
	    &trig_word();
	printf $fp
	    "+\ttarg=v(outputr) val='$output_prop_r' rise=1\n";
    }
    if (($type eq 'inverting') || ($type eq 'hl')) {
	printf $fp
	    ".measure tran tphl %s v(inputr) val='$input_prop_r' rise=1\n",
	    &trig_word();
	printf $fp
	    "+\ttarg=v(outputf) val='$output_prop_f' fall=1\n";
    }

    printf $fp "\n* Output rise and fall time measurements:\n";
    if (($type eq 'inverting') ||
	($type eq 'non_inverting') ||
	($type eq 'hh') ||
	($type eq 'lh')) {
	printf $fp
	    ".measure tran risetime %s v(outputr) val='$trans_r1' rise=1\n",
	    &trig_word();
	printf $fp
	    "+\ttarg=v(outputr) val='$trans_r2' rise=1\n";
    }
    if (($type eq 'inverting') ||
	($type eq 'non_inverting') ||
	($type eq 'll') ||
	($type eq 'hl')) {
	printf $fp
	    ".measure tran falltime %s v(outputf) val='$trans_f1' fall=1\n",
	    &trig_word();
	printf $fp
	    "+\ttarg=v(outputf) val='$trans_f2' fall=1\n";
    }

    printf $fp "\n* Input rise and fall time measurements:\n";
    if (($type eq 'inverting') ||
	($type eq 'non_inverting') ||
	($type eq 'hh') ||
	($type eq 'hl')) {
	printf $fp
	    ".measure tran inputrise %s v(inputr) val='$slew_r1' rise=1\n",
	    &trig_word();
	printf $fp
	    "+\ttarg=v(inputr) val='$slew_r2' rise=1\n";
    }
    if (($type eq 'inverting') ||
	($type eq 'non_inverting') ||
	($type eq 'll') ||
	($type eq 'lh')) {
	printf $fp
	    ".measure tran inputfall %s v(inputf) val='$slew_f1' fall=1\n",
	    &trig_word();
	printf $fp
	    "+\ttarg=v(inputf) val='$slew_f2' fall=1\n";
    }
}


sub ld_print_trans {

    my($fp) = @_;

    printf $fp "\n*--- TRANSIENT -----------------------------------------------\n";
    printf $fp ".trans $trans_timestep '$trans_timestop'\n";
}


sub ld_print_alter {

    my($fp) = @_;
    my($i, $j);

    printf $fp "\n*--- ALTER ---------------------------------------------------\n";
    #foreach $c (@cload) {
    for ($i = 1; $i <= $#cload; $i++) {
	printf $fp ".alter\n";
	printf $fp ".param cload = '$cload[$i]'\n\n" ;
    }

    for ($j = 1; $j <= $#slewrate; $j++) {
	for ($i = 0; $i <= $#cload; $i++) {
	    printf $fp ".alter\n";
	    printf $fp ".param slewrate = '$slewrate[$j]'\n" ;
	    printf $fp ".param tau = 'slewrate/abs(log(slew_start)-log(slew_end))'\n";
	    printf $fp ".param cload = '$cload[$i]'\n\n" ;
	}
    }
}


sub ld_report_spice {

    local($type, $in, $out, $run_name) = @_;
    my($base,$dir,$ext,$spiceout);
    my($i);

    local(@tplh, @tphl, @risetime, @falltime, @creal);
    local(@inputrise, @inputfall);

    ($base,$dir,$ext) = fileparse($run_name, '\.sp');
    $spiceout = $base . '.out';

    printf STDERR "Extracting results from '$spiceout' ...\n";

    open(SPICEOUT, $spiceout) || die "ERROR: Cannot find '$spiceout'.\n";

    while (<SPICEOUT>) {
	if (($name, $value) = /^ *(tplh) *= +([0-9\+\-eE\.]+)/) {
	    push(@tplh, $value);
	}
	if (($name, $value) = /^ *(tphl) *= +([0-9\+\-eE\.]+)/) {
	    push(@tphl, $value);
	}
	if (($name, $value) = /^ *(risetime) *= +([0-9\+\-eE\.]+)/) {
	    push(@risetime, $value);
	}
	if (($name, $value) = /^ *(falltime) *= +([0-9\+\-eE\.]+)/) {
	    push(@falltime, $value);
	}
	if (($name, $value) = /^ *(inputrise) *= +([0-9\+\-eE\.]+)/) {
	    push(@inputrise, $value);
	}
	if (($name, $value) = /^ *(inputfall) += +([0-9\+\-eE\.]+)/) {
	    push(@inputfall, $value);
	}
    }
    close SPICEOUT;

    printf OUT "### LOAD DELAY #############################################################\n\n";
    printf OUT "Cellname:\t\"$cellname\"\n";
    printf OUT "Input:\t\t\"$in\"\n";
    printf OUT "Output:\t\t\"$out\"\n";
    printf OUT "Transition:\t\"$type\"\n";

    # change to real numbers
    @creal = &convert_spice_values(@cload);

    printf OUT "\n";
    &ld_report_spice_1(0);

    # report it again, this time scaled.
    if (($scale_cload != 1) || ($scale_delay != 1)) {

	@creal = &div_list($scale_cload, @creal);
	@tplh = &div_list($scale_delay, @tplh);
	@tphl = &div_list($scale_delay, @tphl);
	@risetime = &div_list($scale_delay, @risetime);
	@falltime = &div_list($scale_delay, @falltime);
	@inputrise = &div_list($scale_delay, @inputrise);
	@inputfall = &div_list($scale_delay, @inputfall);

	printf OUT "\n    Scaled:\n\n";
	&ld_report_spice_1(1);
	printf OUT "\n\n";
    }

    &ld_save_data($cellname, $type, $in, $out, \@creal,
	\@tplh, \@tphl, \@risetime, \@falltime, \@inputrise, \@inputfall);
}


#
#   ld_report_spice_1 --
#	Code fragment, called by ld_report_spice only.
#
sub ld_report_spice_1 {
    my($scaled) = @_;

    my($risetimea, $risetimeb, $risetimer2);
    my($falltimea, $falltimeb, $falltimer2);
    my($tplha, $tplhb, $tplhr2);
    my($tphla, $tphlb, $tphlr2);

    if ($#tplh == $#creal) {
	($tplha, $tplhb, $tplhr2) = &svlinreg('lin', \@creal, \@tplh);
    }
    if ($#tphl == $#creal) {
	($tphla, $tphlb, $tphlr2) = &svlinreg('lin', \@creal, \@tphl);
    }
    if ($#risetime == $#creal) {
	($risetimea, $risetimeb, $risetimer2) = &svlinreg('lin', \@creal, \@risetime);
    }
    if ($#falltime == $#creal) {
	($falltimea, $falltimeb, $falltimer2) = &svlinreg('lin', \@creal, \@falltime);
    }

    if ($debug) {
	&dump_list (creal, @creal);
	&dump_list (tplh, @tplh);
	&dump_list (tphl, @tphl);
	&dump_list (risetime, @risetime);
	&dump_list (falltime, @falltime);
	&dump_list (inputrise, @inputrise);
	&dump_list (inputfall, @inputfall);
    }

    printf OUT "    Cload\tTplh\t\tTphl\t\tRiseTime\tFallTime\tInputRise\tInputFall\n";
    printf OUT "    [F]\t\t[s]\t\t[s]\t\t[s]\t\t[s]\t\t[s]\t\t[s]\n" unless $scaled;
    printf OUT "    ----------\t----------\t----------\t----------\t----------\t----------\t----------\n";
    for ($i = 0; $i <= $#tplh; $i++) {
	printf OUT "    %.4e\t%.4e\t%.4e\t%.4e\t%.4e\t%.4e\t%.4e\n",
	    $creal[$i % ($#creal + 1)], $tplh[$i], $tphl[$i], $risetime[$i], $falltime[$i], $inputrise[$i], $inputfall[$i];

    }

    if ($#slewrate == -1) {
	printf OUT "\n";
	printf OUT "    Tplh\t= %.4e + %.4e * Cload\t(r2=%.4f)\n",
	    $tplha, $tplhb, $tplhr2;
	printf OUT "    Tphl\t= %.4e + %.4e * Cload\t(r2=%.4f)\n",
	    $tphla, $tphlb, $tphlr2;
	printf OUT "    Risetime\t= %.4e + %.4e * Cload\t(r2=%.4f)\n",
	    $risetimea, $risetimeb, $risetimer2;
	printf OUT "    Falltime\t= %.4e + %.4e * Cload\t(r2=%.4f)\n",
	    $falltimea, $falltimeb, $falltimer2;
    }
}


1;
