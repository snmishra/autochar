#	$Id: input_cap.pl,v 1.27 2000/02/11 00:07:23 ryu Exp $

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
#   ic_run --
#	Top-level function to input cap characterization.
#	Generate the spice netlists, run hspice, and extract
#	data.
#
sub ic_run {

    local($inexp, $tie, @tie_list) = @_;
    local($term, $termname, $termtype);

    printf OUT "### INPUT CAP ##############################################################\n\n";
    printf OUT "Cellname:\t\"$cellname\"\n";
    printf OUT "\n";
    printf OUT "    Input\tCeff\t\tCeff\t\tTerror\n";
    printf OUT "    \t\t[F]\t\t[scaled]\t[s]\n";
    printf OUT "    ----------\t----------\t----------\t----------\n";

    foreach $term (@termlist) {
	($termname, $termtype) = split(':', $term);
	if (($termtype eq 'i') && ($termname =~ /$inexp/)) {
	    &ic_char($termname, $tie, @tie_list);
	}
    }
    printf OUT "\n\n";
}


sub ic_char {

    my($in, $tie, @tie_list) = @_;
    my($run_name);
    local($optmod, $optparam, $optmeasure);

    # give names to these puppies
    $optmod = 'optmod';
    $optparam = 'optcap';
    $optmeasure = 'opterror';

    $run_name = &run_file_name($cellname, $in, 'ic');
    open(SPICEIN,">$run_name") || die "ERROR:  Cannot open file '$run_name'.";

    # Create the hspice netlist(s)
    &print_header(SPICEIN, '*');
    printf SPICEIN "*	Char:	Input Capacitance Characterization\n";
    printf SPICEIN "*	Input:	\"$in\"\n";

    &ic_print_setup (SPICEIN);
    &ic_print_source (SPICEIN);
    &ic_print_dut (SPICEIN, $in, $tie, @tie_list);
    &ic_print_measure (SPICEIN);
    &ic_print_trans (SPICEIN);

    printf SPICEIN ".end\n";
    close(SPICEIN);

    &run_spice($run_name);

    &ic_report_spice($in, $run_name);
}


sub ic_print_setup {

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
	printf $fp ".param ceq = '$cstart'\n" ;
    } else {
	printf $fp "$optim_options\n";
	printf $fp ".model $optmod opt\n";
	printf $fp ".param ceq = $optparam('$cstart', '$cmin', '$cmax')\n" ;
    }
}


sub ic_print_source {

    my ($fp) = @_;

    printf $fp "\n*--- INPUTS --------------------------------------------------\n";
    printf $fp "vin0 in0 $low_value pulse (
+	'$low_value'
+	'$high_value'
+	'$trans_delay'
+	'$trans_risetime'
+	'$trans_falltime'
+	'$trans_pulse_width'
+	'$trans_period')\n";

    # put two of them, in the future, integrate
    # the current going out of the source to
    # figure the charge, if no buffers are used.
    printf $fp "vin1 in1 $low_value pulse (
+	'$low_value'
+	'$high_value'
+	'$trans_delay'
+	'$trans_risetime'
+	'$trans_falltime'
+	'$trans_pulse_width'
+	'$trans_period')\n";

}


sub ic_print_dut {

    my($fp, $in, $tie, $tie_list) = @_;
    my($term, $termname, $termtype);
    my($buf, $outload);
    my($vcvs, @inlist, @reflist);
    local($term_no, @vcvs_list, @output_loads);

    $term_no = 0;

    if ($buffer{$in} ne '') {
	$buf = $buffer{$in};
    } else {
	$buf = $buffer{'default'};
    }

    printf $fp "\n*--- TEST CIRCUIT --------------------------------------------\n";

    @inlist = ($in);
    @reflist = ('input0');

    if ($buf eq 'none') {
	die "ERROR:  You must specify a buffer type to characterize input capacitance.\n";
    } else {
	printf $fp "xbuf0 in0 input0 $buf\n";
	printf $fp "xbuf1 in1 input1 $buf\n";
    }

    printf $fp "xdut0\n";
    foreach $term (@termlist) {
	($termname, $termtype) = split(':', $term);
	if ($termname eq $in) {
	    printf $fp "+\tinput0\t\$ $term\n";
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

    # print the matching cap
    printf $fp "ceff input1 $low_value ceq\n";

}


sub ic_print_measure {

    my($fp) = @_;

    printf $fp "\n*--- MEASURE -------------------------------------------------\n";
    printf $fp ".option autostop\n";

    if ($spice_type eq 'smartspice') {
	printf $fp ".measure tran dut_r delay v(in0) val='$midpoint_value' rise=1\n";
    } else {
	printf $fp ".measure tran dut_r trig=v(in0) val='$midpoint_value' rise=1\n";
    }
    printf $fp "+\ttarg=v(input0) val='$midpoint_value' rise=1\n";

    if ($spice_type eq 'smartspice') {
	printf $fp ".measure tran dut_f delay v(in0) val='$midpoint_value' fall=1\n";
    } else {
	printf $fp ".measure tran dut_f trig=v(in0) val='$midpoint_value' fall=1\n";
    }
    printf $fp "+\ttarg=v(input0) val='$midpoint_value' fall=1\n";
    printf $fp ".measure tran dut_delay param='(dut_r + dut_f)/2.0'\n";

    if ($spice_type eq 'smartspice') {
	printf $fp ".measure tran cap_r delay v(in1) val='$midpoint_value' rise=1\n";
    } else {
	printf $fp ".measure tran cap_r trig=v(in1) val='$midpoint_value' rise=1\n";
    }
    printf $fp "+\ttarg=v(input1) val='$midpoint_value' rise=1\n";

    if ($spice_type eq 'smartspice') {
	printf $fp ".measure tran cap_f delay v(in1) val='$midpoint_value' fall=1\n";
    } else {
	printf $fp ".measure tran cap_f trig=v(in1) val='$midpoint_value' fall=1\n";
    }
    printf $fp "+\ttarg=v(input1) val='$midpoint_value' fall=1\n";
    printf $fp ".measure tran cap_delay param='(cap_r + cap_f)/2.0'\n";

    if ($spice_type eq 'smartspice') {
	printf $fp ".measure tran $optmeasure param='abs(dut_delay - cap_delay)'\n";
    } else {
	printf $fp ".measure tran $optmeasure param='abs(dut_delay - cap_delay)' goal=0\n";
    }
}


sub ic_print_trans {

    my($fp) = @_;

    printf $fp "\n*--- TRANSIENT -----------------------------------------------\n";

    if ($spice_type eq 'smartspice') {
	printf $fp ".trans $trans_timestep '$trans_timestop'\n";
	printf $fp ".modif proff prtbl
+	optimize ceq=opt('$cmin' '$cmax' '$cstart')
+	targets opterror=1e-15
+	options avg=0.001\n";
    } else {
	printf $fp ".trans $trans_timestep '$trans_timestop' sweep
+	optimize=$optparam
+	results=$optmeasure
+	model=$optmod\n";

	printf $fp "\n\n* Final value:\n";
	printf $fp ".alter\n";
	printf $fp ".trans $trans_timestep '$trans_timestop'\n";
	printf $fp ".measure tran ceff param='ceq'\n";
    }
}


sub ic_report_spice {

    my($in, $run_name) = @_;
    my($base,$dir,$ext,$spiceout);
    my($ceq, $cscaled, $cerror);

    ($base,$dir,$ext) = fileparse($run_name, '\.sp');
    $spiceout = $base . '.out';

    printf STDERR "Extracting results from '$spiceout' ...\n";

    open(SPICEOUT, $spiceout) || die "ERROR: Cannot find '$spiceout'.\n";

    if ($spice_type eq 'smartspice') {
	while (<SPICEOUT>) {
	    if (($name, $value) = /^(ceq) *=\s+([0-9\+\-eE\.]+)/) {
		$ceq = $value;
	    }
	    if (($name, $value) = /^(opterror) *=\s+([0-9\+\-eE\.]+)/) {
		$cerror = $value;
	    }
	}
    } else {
	while (<SPICEOUT>) {
	    if (($name, $value) = /^ +(ceff) *= +([0-9\+\-eE\.]+)/) {
		$ceq = $value;
	    }
	    if (($name, $value) = /^ +($optmeasure) *= +([0-9\+\-eE\.]+)/) {
		$cerror = $value;
	    }
	}
    }

    $cscaled = $ceq / $scale_cload;
    printf OUT "    %10s\t%.4e\t%.4e\t%.4e\n",
	$in, $ceq, $cscaled, $cerror;

    &ic_save_data($cellname, $in, $cscaled);

    close SPICEOUT;
}


1;
