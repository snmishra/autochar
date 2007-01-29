#	$Id: model.pl,v 1.37 2000/02/03 00:47:09 ryu Exp ryu $

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

sub print_model {
    my($format, $modelname) = @_;

    open(MODEL, "> $modelname") || die "ERROR:  Cannot create file '$modelname'.\n";

    if ($format eq 'synopsys') {
	&print_synopsys(MODEL);
    } elsif ($format eq 'pearl') {
	&print_pearl(MODEL);
    } elsif ($format eq 'tlf') {
	&print_tlf(MODEL);
    } else {
	die "ERROR: unknown model format type '$format'.\n";
    }
    close(MODEL);
    printf STDERR "Created '$modelname'.\n";
}

sub format_model {
    my($type, $src, $dest, $edge) = @_;
    return ($type . "_" . $src . "_" . $dest . "_" . $edge);
}

### SYNOPSYS ############################################################################

sub print_synopsys_cellprops {
    my($fp) = @_;
    my ($key, $cell, $type, $propname);

    foreach $key (keys(%celldata)) {
	($cell, $type, $propname) = split(':', $key);
	if (($cell eq $cellname) && ($type eq 'cellprop')) {
	    # treat 'section' properties differently
	    if ($propname eq 'section') {
		printf $fp "\t%s\n",
		    $celldata{"$cellname:cellprop:$propname"};
		next;
	    }
	    
	    # print out only those recognized by synopsys
	    if (($propname eq 'area') || ($propname eq 'cell_footprint')) {
		printf $fp "\t%s : %s ;\n",
		    $propname, $celldata{"$cellname:cellprop:$propname"};
		next;
	    }
	}
    }
}

sub print_synopsys_termprops {
    my($fp, $refterm) = @_;
    my ($key, $cell, $type, $termname, $propname);

    foreach $key (keys(%celldata)) {
	($cell, $type, $termname, $propname) = split(':', $key);
	if (($cell eq $cellname) && ($type eq 'termprop') && ($termname eq $refterm)) {

	    # explicit
	    if (($propname eq 'max_capacitance') || ($propname eq 'max_fanout')) {
		printf $fp "\t    %s : %s ;\n",
		    $propname, $celldata{"$cellname:termprop:$termname:$propname"};
	    }
	    if ($propname eq 'function') {
		printf $fp "\t    %s : \"%s\" ;\n",
		    $propname, $celldata{"$cellname:termprop:$termname:$propname"};
	    }

	}
    }
}


sub print_synopsys {
    my ($fp) = @_;
    my ($term);
    my ($termname, $termtype);

    printf $fp "/*\n";
    &print_header($fp, ' *');
    printf $fp " */\n\n";

    printf $fp "    cell( \"$cellname\" ) {\n";

    &print_synopsys_cellprops($fp);

    # print terms
    foreach $term (@termlist) {
	($termname, $termtype) = split(':', $term);

	printf $fp "\tpin( \"$termname\" ) {\n";
	&print_synopsys_termprops($fp, $termname);

	if ($termtype eq 'i') {
	    printf $fp "\t    direction : input ;\n";
	    printf $fp "\t    capacitance : %.4e ;\n",
		$celldata{"$cellname:input_cap:$termname"}
		if $celldata{"$cellname:input_cap:$termname"};
	    &print_synopsys_input_timing($fp, $termname);
	    printf $fp "\t}\n";
	    next;
	}
	if ($termtype eq 'o') {
	    printf $fp "\t    direction : output ;\n";
	    &print_synopsys_output_timing($fp, $termname);
	    printf $fp "\t}\n";
	    next;
	}
    }

    printf $fp "    }\n";
}


sub print_synopsys_input_timing {
    my($fp, $input) = @_;
    my ($term);
    my ($clock, $termtype);
    my ($i, @wcvalue);

    foreach $term (@termlist) {
	($clock, $termtype) = split(':', $term);
	if ($termtype eq 'i') {

	    # D SETUP
	    if ($celldata{"$cellname:setup_hold:$input:$clock:setup"}) {
		printf $fp "\t    timing () {\n";
		printf $fp "\t\trelated_pin : \"$clock\" ;\n";

		if ($celldata{"$cellname:setup_hold:$input:$clock:clktype"} eq 'rising') {
		    printf $fp "\t\ttiming_type : setup_rising ;\n";
		} elsif ($celldata{"$cellname:setup_hold:$input:$clock:clktype"} eq 'falling') {
		    printf $fp "\t\ttiming_type : setup_falling ;\n";
		} else {
		    printf STDERR "WARNING: unknown clock type '$clktype'.\n";
		}

		if ($#slewrate == -1) {
		    # only one value
		    printf $fp "\t\tintrinsic_rise : %.4e ;\n",
			$celldata{"$cellname:setup_hold:$input:$clock:setup_lh[0]"}
			if $celldata{"$cellname:setup_hold:$input:$clock:setup_lh[0]"};
		    printf $fp "\t\tintrinsic_fall : %.4e ;\n",
			$celldata{"$cellname:setup_hold:$input:$clock:setup_hl"}[0]
			if $celldata{"$cellname:setup_hold:$input:$clock:setup_hl"}[0];
		    printf $fp "\t    }\n";
		} else {
		    # all values
		    printf $fp "\t\trise_constraint (%s) {\n",
			$celldata{"$cellname:setup_hold:$input:$clock:lu_table"};
		    printf $fp "\t\t    values (\"";
		    for ($i = 0; $i <= $#slewrate; $i++) {
			printf $fp "%.4e", $celldata{"$cellname:setup_hold:$input:$clock:setup_lh"}[$i];
			printf $fp ", " unless ($i == $#slewrate);
		    }
		    printf $fp "\")\n\t\t}\n";

		    printf $fp "\t\tfall_constraint (%s) {\n",
			$celldata{"$cellname:setup_hold:$input:$clock:lu_table"};
		    printf $fp "\t\t    values (\"";
		    for ($i = 0; $i <= $#slewrate; $i++) {
			printf $fp "%.4e", $celldata{"$cellname:setup_hold:$input:$clock:setup_hl"}[$i];
			printf $fp ", " unless ($i == $#slewrate);
		    }
		    printf $fp "\")\n\t\t}\n";
		    printf $fp "\t    }\n";
		}
	    }

	    # D HOLD
	    if ($celldata{"$cellname:setup_hold:$input:$clock:hold"}) {
		printf $fp "\t    timing () {\n";
		printf $fp "\t\trelated_pin : \"$clock\" ;\n";

		if ($celldata{"$cellname:setup_hold:$input:$clock:clktype"} eq 'rising') {
		    printf $fp "\t\ttiming_type : hold_rising ;\n";
		} elsif ($celldata{"$cellname:setup_hold:$input:$clock:clktype"} eq 'falling') {
		    printf $fp "\t\ttiming_type : hold_falling ;\n";
		} else {
		    printf STDERR "WARNING: unknown clock type '$clktype'.\n";
		}

		if ($#slewrate == -1) {
		    # only one value
		    printf $fp "\t\tintrinsic_rise : %.4e ;\n",
			$celldata{"$cellname:setup_hold:$input:$clock:hold_lh[0]"}
			if $celldata{"$cellname:setup_hold:$input:$clock:hold_lh[0]"};
		    printf $fp "\t\tintrinsic_fall : %.4e ;\n",
		    $celldata{"$cellname:setup_hold:$input:$clock:hold_hl[0]"}
			if $celldata{"$cellname:setup_hold:$input:$clock:hold_hl[0]"};
		    printf $fp "\t    }\n";
		} else {
		    # all values
		    printf $fp "\t\trise_constraint (%s) {\n",
			$celldata{"$cellname:setup_hold:$input:$clock:lu_table"};
		    printf $fp "\t\t    values (\"";
		    for ($i = 0; $i <= $#slewrate; $i++) {
			printf $fp "%.4e", $celldata{"$cellname:setup_hold:$input:$clock:hold_lh"}[$i];
			printf $fp ", " unless ($i == $#slewrate);
		    }
		    printf $fp "\")\n\t\t}\n";

		    printf $fp "\t\tfall_constraint (%s) {\n",
			$celldata{"$cellname:setup_hold:$input:$clock:lu_table"};
		    printf $fp "\t\t    values (\"";
		    for ($i = 0; $i <= $#slewrate; $i++) {
			printf $fp "%.4e", $celldata{"$cellname:setup_hold:$input:$clock:hold_hl"}[$i];
			printf $fp ", " unless ($i == $#slewrate);
		    }
		    printf $fp "\")\n\t\t}\n";
		    printf $fp "\t    }\n";
		}
	    }

	    # CE SETUP
	    if ($celldata{"$cellname:clock_enable:$input:$clock:setup"}) {
		printf $fp "\t    timing () {\n";
		printf $fp "\t\trelated_pin : \"$clock\" ;\n";

		if ($celldata{"$cellname:clock_enable:$input:$clock:clktype"} eq 'rising') {
		    printf $fp "\t\ttiming_type : setup_rising ;\n";
		} elsif ($celldata{"$cellname:clock_enable:$input:$clock:clktype"} eq 'falling') {
		    printf $fp "\t\ttiming_type : setup_falling ;\n";
		} else {
		    printf STDERR "WARNING: unknown clock type '$clktype'.\n";
		}

		if ($#slewrate == -1) {
		    # only one value
		    if ($celldata{"$cellname:clock_enable:$input:$clock:cetype"} eq 'active_high') {
			printf $fp "\t\tintrinsic_rise : ";
		    } elsif ($celldata{"$cellname:clock_enable:$input:$clock:cetype"} eq 'active_low') {
			printf $fp "\t\tintrinsic_fall : ";
		    } else {
			printf STDERR "WARNING: unknown ce type '$cetype'.\n";
		    }
		    printf $fp "%.4e ;\n",
			&max($celldata{"$cellname:clock_enable:$input:$clock:setup_lh[0]"},
			     $celldata{"$cellname:clock_enable:$input:$clock:setup_hl[0]"});
		    printf $fp "\t    }\n";
		} else {
		    # all values
		    @wcvalue = &bigger_avg_list(
			$celldata{"$cellname:clock_enable:$input:$clock:setup_lh"},
			$celldata{"$cellname:clock_enable:$input:$clock:setup_hl"});

		    if ($celldata{"$cellname:clock_enable:$input:$clock:cetype"} eq 'active_high') {
			printf $fp "\t\trise_constraint (%s) {\n",
			    $celldata{"$cellname:clock_enable:$input:$clock:lu_table"};
		    } elsif ($celldata{"$cellname:clock_enable:$input:$clock:cetype"} eq 'active_low') {
			printf $fp "\t\tfall_constraint (%s) {\n",
			    $celldata{"$cellname:clock_enable:$input:$clock:lu_table"};
		    } else {
			printf STDERR "WARNING: unknown ce type '$cetype'.\n";
		    }

		    printf $fp "\t\t    values (\"";
		    for ($i = 0; $i <= $#slewrate; $i++) {
			printf $fp "%.4e", $wcvalue[$i];
			printf $fp ", " unless ($i == $#slewrate);
		    }
		    printf $fp "\")\n\t\t}\n";
		    printf $fp "\t    }\n";
		}
	    }

	    # CE HOLD
	    if ($celldata{"$cellname:clock_enable:$input:$clock:hold"}) {
		printf $fp "\t    timing () {\n";
		printf $fp "\t\trelated_pin : \"$clock\" ;\n";

		if ($celldata{"$cellname:clock_enable:$input:$clock:clktype"} eq 'rising') {
		    printf $fp "\t\ttiming_type : hold_rising ;\n";
		} elsif ($celldata{"$cellname:clock_enable:$input:$clock:clktype"} eq 'falling') {
		    printf $fp "\t\ttiming_type : hold_falling ;\n";
		} else {
		    printf STDERR "WARNING: unknown clock type '$clktype'.\n";
		}

		if ($#slewrate == -1) {
		    # only one value
		    if ($celldata{"$cellname:clock_enable:$input:$clock:cetype"} eq 'active_high') {
			printf $fp "\t\tintrinsic_rise : ";
		    } elsif ($celldata{"$cellname:clock_enable:$input:$clock:cetype"} eq 'active_low') {
			printf $fp "\t\tintrinsic_fall : ";
		    } else {
			printf STDERR "WARNING: unknown ce type '$cetype'.\n";
		    }
		    printf $fp "%.4e ;\n",
			&max($celldata{"$cellname:clock_enable:$input:$clock:hold_lh"},
			     $celldata{"$cellname:clock_enable:$input:$clock:hold_hl"});
		    printf $fp "\t    }\n";
		} else {
		    # all values
		    @wcvalue = &bigger_avg_list(
			$celldata{"$cellname:clock_enable:$input:$clock:hold_lh"},
			$celldata{"$cellname:clock_enable:$input:$clock:hold_hl"});

		    if ($celldata{"$cellname:clock_enable:$input:$clock:cetype"} eq 'active_high') {
			printf $fp "\t\trise_constraint (%s) {\n",
			    $celldata{"$cellname:clock_enable:$input:$clock:lu_table"};
		    } elsif ($celldata{"$cellname:clock_enable:$input:$clock:cetype"} eq 'active_low') {
			printf $fp "\t\tfall_constraint (%s) {\n",
			    $celldata{"$cellname:clock_enable:$input:$clock:lu_table"};
		    } else {
			printf STDERR "WARNING: unknown ce type '$cetype'.\n";
		    }

		    printf $fp "\t\t    values (\"";
		    for ($i = 0; $i <= $#slewrate; $i++) {
			printf $fp "%.4e", $wcvalue[$i];
			printf $fp ", " unless ($i == $#slewrate);
		    }
		    printf $fp "\")\n\t\t}\n";
		    printf $fp "\t    }\n";
		}
	    }

	    # CG SETUP
	    if ($celldata{"$cellname:clock_gate:$input:$clock:setup"}) {
		printf $fp "\t    timing () {\n";
		printf $fp "\t\trelated_pin : \"$clock\" ;\n";

		if ($celldata{"$cellname:clock_gate:$input:$clock:clktype"} eq 'rising') {
		    printf $fp "\t\ttiming_type : setup_rising ;\n";
		} elsif ($celldata{"$cellname:clock_gate:$input:$clock:clktype"} eq 'falling') {
		    printf $fp "\t\ttiming_type : setup_falling ;\n";
		} else {
		    printf STDERR "WARNING: unknown clock type '$clktype'.\n";
		}

		if ($#slewrate == -1) {
		    # only one value
		    if ($celldata{"$cellname:clock_gate:$input:$clock:cetype"} eq 'active_high') {
			printf $fp "\t\tintrinsic_rise : ";
		    } elsif ($celldata{"$cellname:clock_gate:$input:$clock:cetype"} eq 'active_low') {
			printf $fp "\t\tintrinsic_fall : ";
		    } else {
			printf STDERR "WARNING: unknown ce type '$cetype'.\n";
		    }
		    printf $fp "%.4e ;\n",
			&max($celldata{"$cellname:clock_gate:$input:$clock:setup_lh[0]"},
			     $celldata{"$cellname:clock_gate:$input:$clock:setup_hl[0]"});
		    printf $fp "\t    }\n";
		} else {
		    # all values
		    @wcvalue = &bigger_avg_list(
			$celldata{"$cellname:clock_gate:$input:$clock:setup_lh"},
			$celldata{"$cellname:clock_gate:$input:$clock:setup_hl"});

		    if ($celldata{"$cellname:clock_gate:$input:$clock:cetype"} eq 'active_high') {
			printf $fp "\t\trise_constraint (%s) {\n",
			    $celldata{"$cellname:clock_gate:$input:$clock:lu_table"};
		    } elsif ($celldata{"$cellname:clock_gate:$input:$clock:cetype"} eq 'active_low') {
			printf $fp "\t\tfall_constraint (%s) {\n",
			    $celldata{"$cellname:clock_gate:$input:$clock:lu_table"};
		    } else {
			printf STDERR "WARNING: unknown ce type '$cetype'.\n";
		    }

		    printf $fp "\t\t    values (\"";
		    for ($i = 0; $i <= $#slewrate; $i++) {
			printf $fp "%.4e", $wcvalue[$i];
			printf $fp ", " unless ($i == $#slewrate);
		    }
		    printf $fp "\")\n\t\t}\n";
		    printf $fp "\t    }\n";
		}
	    }

	    # CG HOLD
	    if ($celldata{"$cellname:clock_gate:$input:$clock:hold"}) {
		printf $fp "\t    timing () {\n";
		printf $fp "\t\trelated_pin : \"$clock\" ;\n";

		if ($celldata{"$cellname:clock_gate:$input:$clock:clktype"} eq 'rising') {
		    printf $fp "\t\ttiming_type : hold_rising ;\n";
		} elsif ($celldata{"$cellname:clock_gate:$input:$clock:clktype"} eq 'falling') {
		    printf $fp "\t\ttiming_type : hold_falling ;\n";
		} else {
		    printf STDERR "WARNING: unknown clock type '$clktype'.\n";
		}

		if ($#slewrate == -1) {
		    # only one value
		    if ($celldata{"$cellname:clock_gate:$input:$clock:cetype"} eq 'active_high') {
			printf $fp "\t\tintrinsic_rise : ";
		    } elsif ($celldata{"$cellname:clock_gate:$input:$clock:cetype"} eq 'active_low') {
			printf $fp "\t\tintrinsic_fall : ";
		    } else {
			printf STDERR "WARNING: unknown ce type '$cetype'.\n";
		    }
		    printf $fp "%.4e ;\n",
			&max($celldata{"$cellname:clock_gate:$input:$clock:hold_lh"},
			     $celldata{"$cellname:clock_gate:$input:$clock:hold_hl"});
		    printf $fp "\t    }\n";
		} else {
		    # all values
		    @wcvalue = &bigger_avg_list(
			$celldata{"$cellname:clock_gate:$input:$clock:hold_lh"},
			$celldata{"$cellname:clock_gate:$input:$clock:hold_hl"});

		    if ($celldata{"$cellname:clock_gate:$input:$clock:cetype"} eq 'active_high') {
			printf $fp "\t\trise_constraint (%s) {\n",
			    $celldata{"$cellname:clock_gate:$input:$clock:lu_table"};
		    } elsif ($celldata{"$cellname:clock_gate:$input:$clock:cetype"} eq 'active_low') {
			printf $fp "\t\tfall_constraint (%s) {\n",
			    $celldata{"$cellname:clock_gate:$input:$clock:lu_table"};
		    } else {
			printf STDERR "WARNING: unknown ce type '$cetype'.\n";
		    }

		    printf $fp "\t\t    values (\"";
		    for ($i = 0; $i <= $#slewrate; $i++) {
			printf $fp "%.4e", $wcvalue[$i];
			printf $fp ", " unless ($i == $#slewrate);
		    }
		    printf $fp "\")\n\t\t}\n";
		    printf $fp "\t    }\n";
		}
	    }
	}
    }
}


sub print_synopsys_output_timing {
    my ($fp, $output) = @_;
    my ($term);
    my ($input, $termtype);
    my ($i, $j, $k);

    foreach $term (@termlist) {
	($input, $termtype) = split(':', $term);
	if ($termtype eq 'i') {

	    # LOAD DELAY
	    if ($celldata{"$cellname:load_delay:$input:$output"}) {

		printf $fp "\t    timing () {\n";
		printf $fp "\t\trelated_pin : \"$input\" ;\n";
		if ($#slewrate == -1) {

		    # linear model
		    printf $fp "\t\tintrinsic_rise : %.4e ;\n",
			$celldata{"$cellname:load_delay:$input:$output:tplha"}
			if $celldata{"$cellname:load_delay:$input:$output:tplha"};
		    printf $fp "\t\tintrinsic_fall : %.4e ;\n",
			$celldata{"$cellname:load_delay:$input:$output:tphla"}
			if $celldata{"$cellname:load_delay:$input:$output:tphla"};
		    printf $fp "\t\trise_resistance : %.4e ;\n",
			$celldata{"$cellname:load_delay:$input:$output:tplhb"}
			if $celldata{"$cellname:load_delay:$input:$output:tplhb"};
		    printf $fp "\t\tfall_resistance : %.4e ;\n",
			$celldata{"$cellname:load_delay:$input:$output:tphlb"}
			if $celldata{"$cellname:load_delay:$input:$output:tphlb"};

		} else {

		    # nonlinear model
		    printf $fp "\t\ttiming_type : combinational ;\n";

		    if ($celldata{"$cellname:load_delay:$input:$output:tplh"}) {
			printf $fp "\t\trise_propagation (%s) {",
			    $celldata{"$cellname:load_delay:$input:$output:lu_table"};

			if ($output_prop_percent == 0.50) {
			    printf $fp "\n\t\t    /* Actual measurement values:";
			}

			printf $fp "\n\t\t    values ( \\";
			$k = 0;
			for ($j = 0; $j <= $#slewrate; $j++) {
			    printf $fp "\n\t\t\t\"";
			    for ($i = 0; $i <= $#cload; $i++) {
				printf $fp "%.4e",
				    $celldata{"$cellname:load_delay:$input:$output:tplh"}[$k++];
				printf $fp " " unless ($i == $#cload);
			    }
			    printf $fp "\"";
			    printf $fp "," unless ($j == $#slewrate);
			    printf $fp " \\";
			}
			printf $fp "\n\t\t    )";

			if ($output_prop_percent == 0.50) {
			    printf $fp "\n\t\t    */";

			    printf $fp "\n\t\t    /* Propagation minus rise transition delay: */";
			    printf $fp "\n\t\t    values ( \\";
			    $k = 0;
			    for ($j = 0; $j <= $#slewrate; $j++) {
				printf $fp "\n\t\t\t\"";
				for ($i = 0; $i <= $#cload; $i++) {
				    # subtract the risetime from tplh
				    printf $fp "%.4e",
					($celldata{"$cellname:load_delay:$input:$output:tplh"}[$k] -
					 $celldata{"$cellname:load_delay:$input:$output:risetime"}[$k]);
				    $k++;
				    printf $fp " " unless ($i == $#cload);
				}
				printf $fp "\"";
				printf $fp "," unless ($j == $#slewrate);
				printf $fp " \\";
			    }
			    printf $fp "\n\t\t    )";
			}

			printf $fp "\n\t\t}\n";
		    }

		    if ($celldata{"$cellname:load_delay:$input:$output:tphl"}) {
			printf $fp "\t\tfall_propagation (%s) {",
			    $celldata{"$cellname:load_delay:$input:$output:lu_table"};

			if ($output_prop_percent == 0.50) {
			    printf $fp "\n\t\t    /* Actual measurement values:";
			}

			printf $fp "\n\t\t    values ( \\";
			$k = 0;
			for ($j = 0; $j <= $#slewrate; $j++) {
			    printf $fp "\n\t\t\t\"";
			    for ($i = 0; $i <= $#cload; $i++) {
				printf $fp "%.4e",
				    $celldata{"$cellname:load_delay:$input:$output:tphl"}[$k++];
				printf $fp " " unless ($i == $#cload);
			    }
			    printf $fp "\"";
			    printf $fp "," unless ($j == $#slewrate);
			    printf $fp " \\";
			}
			printf $fp "\n\t\t    )";

			if ($output_prop_percent == 0.50) {
			    printf $fp "\n\t\t    */";

			    printf $fp "\n\t\t    /* Propagation minus fall transition delay: */";
			    printf $fp "\n\t\t    values ( \\";
			    $k = 0;
			    for ($j = 0; $j <= $#slewrate; $j++) {
				printf $fp "\n\t\t\t\"";
				for ($i = 0; $i <= $#cload; $i++) {
				    printf $fp "%.4e",
					($celldata{"$cellname:load_delay:$input:$output:tphl"}[$k] -
					 $celldata{"$cellname:load_delay:$input:$output:falltime"}[$k]);
				    $k++;
				    printf $fp " " unless ($i == $#cload);
				}
				printf $fp "\"";
				printf $fp "," unless ($j == $#slewrate);
				printf $fp " \\";
			    }
			    printf $fp "\n\t\t    )";
			}

			printf $fp "\n\t\t}\n";
		    }

		    if ($celldata{"$cellname:load_delay:$input:$output:risetime"}) {
			printf $fp "\t\trise_transition (%s) {\n",
			    $celldata{"$cellname:load_delay:$input:$output:lu_table"};
			printf $fp "\t\t    values ( \\";

			$k = 0;
			for ($j = 0; $j <= $#slewrate; $j++) {
			    printf $fp "\n\t\t\t\"";
			    for ($i = 0; $i <= $#cload; $i++) {
				printf $fp "%.4e",
				    $celldata{"$cellname:load_delay:$input:$output:risetime"}[$k++];
				printf $fp " " unless ($i == $#cload);
			    }
			    printf $fp "\"";
			    printf $fp "," unless ($j == $#slewrate);
			    printf $fp " \\";
			}
			printf $fp "\n\t\t    )";
			printf $fp "\n\t\t}\n";
		    }

		    if ($celldata{"$cellname:load_delay:$input:$output:falltime"}) {
			printf $fp "\t\tfall_transition (%s) {\n",
			    $celldata{"$cellname:load_delay:$input:$output:lu_table"};
			printf $fp "\t\t    values ( \\";

			$k = 0;
			for ($j = 0; $j <= $#slewrate; $j++) {
			    printf $fp "\n\t\t\t\"";
			    for ($i = 0; $i <= $#cload; $i++) {
				printf $fp "%.4e",
				    $celldata{"$cellname:load_delay:$input:$output:falltime"}[$k++];
				printf $fp " " unless ($i == $#cload);
			    }
			    printf $fp "\"";
			    printf $fp "," unless ($j == $#slewrate);
			    printf $fp " \\";
			}
			printf $fp "\n\t\t    )";
			printf $fp "\n\t\t}\n";
		    }
		}

		printf $fp "\t    }\n";
	    }

	    # CLOCK Q
	    if ($celldata{"$cellname:clock_q:$input:$output"}) {
		printf $fp "\t    timing () {\n";
		printf $fp "\t\trelated_pin : \"$input\" ;\n";

		if ($celldata{"$cellname:clock_q:$input:$output:clktype"} eq 'rising') {
		    printf $fp "\t\ttiming_type : rising_edge ;\n";
		} elsif ($celldata{"$cellname:clock_q:$input:$output:clktype"} eq 'falling') {
		    printf $fp "\t\ttiming_type : falling_edge ;\n";
		} else {
		    printf STDERR "WARNING: unknown clock type '$clktype'.\n";
		}

		if ($timing_model eq 'linear') {

		    printf $fp "\t\tintrinsic_rise : %.4e ;\n",
			$celldata{"$cellname:clock_q:$input:$output:clk_q_lha"}
			if $celldata{"$cellname:clock_q:$input:$output:clk_q_lha"};
		    printf $fp "\t\tintrinsic_fall : %.4e ;\n",
			$celldata{"$cellname:clock_q:$input:$output:clk_q_hla"}
			if $celldata{"$cellname:clock_q:$input:$output:clk_q_hla"};
		    printf $fp "\t\trise_resistance : %.4e ;\n",
			$celldata{"$cellname:clock_q:$input:$output:clk_q_lhb"}
			if $celldata{"$cellname:clock_q:$input:$output:clk_q_lhb"};
		    printf $fp "\t\tfall_resistance : %.4e ;\n",
			$celldata{"$cellname:clock_q:$input:$output:clk_q_hlb"}
			if $celldata{"$cellname:clock_q:$input:$output:clk_q_hlb"};
		    printf $fp "\t    }\n";

		} elsif ($timing_model eq 'non_linear') {

		    printf $fp "\t\trise_propagation (%s) {\n",
			$celldata{"$cellname:clock_q:$input:$output:lu_table"};
		    if ($output_prop_percent == 0.50) {
			printf $fp "\t\t    /* Actual measurement values:\n";
		    }
		    printf $fp "\t\t    values (\"";
		    for ($i = 0; $i <= $#cload; $i++) {
			printf $fp "%.4e", $celldata{"$cellname:clock_q:$input:$output:clk_q_lh"}[$i];
			printf $fp ", " unless ($i == $#cload);
		    }
		    printf $fp "\")\n";
		    if ($output_prop_percent == 0.50) {
			printf $fp "\t\t    */\n";
			printf $fp "\t\t    /* Propagation minus rise transition delay: */\n";
			printf $fp "\t\t    values (\"";
			for ($i = 0; $i <= $#cload; $i++) {
			    printf $fp "%.4e",
				($celldata{"$cellname:clock_q:$input:$output:clk_q_lh"}[$i] -
				$celldata{"$cellname:clock_q:$input:$output:risetime"}[$i]);
			    printf $fp ", " unless ($i == $#cload);
			}
			printf $fp "\")\n";
		    }
		    printf $fp "\t\t}\n";

		    printf $fp "\t\trise_transition (%s) {\n",
			$celldata{"$cellname:clock_q:$input:$output:lu_table"};
		    printf $fp "\t\t    values (\"";
		    for ($i = 0; $i <= $#cload; $i++) {
			printf $fp "%.4e", $celldata{"$cellname:clock_q:$input:$output:risetime"}[$i];
			printf $fp ", " unless ($i == $#cload);
		    }
		    printf $fp "\")\n\t\t}\n";

		    printf $fp "\t\tfall_propagation (%s) {\n",
			$celldata{"$cellname:clock_q:$input:$output:lu_table"};
		    if ($output_prop_percent == 0.50) {
			printf $fp "\t\t    /* Actual measurement values:\n";
		    }
		    printf $fp "\t\t    values (\"";
		    for ($i = 0; $i <= $#cload; $i++) {
			printf $fp "%.4e", $celldata{"$cellname:clock_q:$input:$output:clk_q_hl"}[$i];
			printf $fp ", " unless ($i == $#cload);
		    }
		    printf $fp "\")\n";
		    if ($output_prop_percent == 0.50) {
			printf $fp "\t\t    */\n";
			printf $fp "\t\t    /* Propagation minus rise transition delay: */\n";
			printf $fp "\t\t    values (\"";
			for ($i = 0; $i <= $#cload; $i++) {
			    printf $fp "%.4e",
				($celldata{"$cellname:clock_q:$input:$output:clk_q_hl"}[$i] -
				$celldata{"$cellname:clock_q:$input:$output:falltime"}[$i]);
			    printf $fp ", " unless ($i == $#cload);
			}
			printf $fp "\")\n";
		    }
		    printf $fp "\t\t}\n";

		    printf $fp "\t\tfall_transition (%s) {\n",
			$celldata{"$cellname:clock_q:$input:$output:lu_table"};
		    printf $fp "\t\t    values (\"";
		    for ($i = 0; $i <= $#cload; $i++) {
			printf $fp "%.4e", $celldata{"$cellname:clock_q:$input:$output:falltime"}[$i];
			printf $fp ", " unless ($i == $#cload);
		    }
		    printf $fp "\")\n\t\t}\n";
		    printf $fp "\t    }\n";

		} else {
		    printf STDERR "WARNING: unknown timing model type '$timing_model'.\n";
		}
	    }
	}
    }
}

### TLF ################################################################################

sub print_tlf_cellprops {
    my($fp) = @_;
    my ($key, $cell, $type, $propname);

    # order counts
    foreach $key (keys(%celldata)) {
	($cell, $type, $propname) = split(':', $key);
	if (($cell eq $cellname) && ($type eq 'cellprop')) {
	    if ($propname eq 'celltype') {
		printf $fp "\t%s(%s)\n",
		    $propname, $celldata{"$cellname:cellprop:$propname"};
		next;
	    }
	}
    }
    foreach $key (keys(%celldata)) {
	($cell, $type, $propname) = split(':', $key);
	if (($cell eq $cellname) && ($type eq 'cellprop')) {
	    if ($propname eq 'area') {
		printf $fp "\ttiming_props (\n\t    Area (%s)\n\t)\n",
		    $celldata{"$cellname:cellprop:$propname"};
		next;
	    }
	}
    }

    # others here
}

sub print_tlf_termprops {
    my($fp, $refterm, $termtype) = @_;
    my ($key, $cell, $type, $termname, $propname);

    # tlf order is important, so gotta loop in the correct order
    foreach $key (keys(%celldata)) {
	($cell, $type, $termname, $propname) = split(':', $key);
	if (($cell eq $cellname) && ($type eq 'termprop') && ($termname eq $refterm)) {
	    if ($propname eq 'pintype') {
		printf $fp "\t    %s(%s)\n",
		    $propname, $celldata{"$cellname:termprop:$termname:$propname"};
	    }
	}
    }
    foreach $key (keys(%celldata)) {
	($cell, $type, $termname, $propname) = split(':', $key);
	if (($cell eq $cellname) && ($type eq 'termprop') && ($termname eq $refterm)) {
	    if ($propname eq 'function') {
		printf $fp "\t    Function(%s)\n",
		    $celldata{"$cellname:termprop:$termname:$propname"};
	    }
	}
    }
    foreach $key (keys(%celldata)) {
	($cell, $type, $termname, $propname) = split(':', $key);
	if (($cell eq $cellname) && ($type eq 'termprop') && ($termname eq $refterm)) {
	    if ($propname eq 'load_limit') {
		printf $fp "\t    timing_props(load_limit(warn(%s) error(~)))\n",
		    $celldata{"$cellname:termprop:$termname:$propname"};
	    }
	}
    }
    # others here

    if ($termtype eq 'i') {
	printf $fp "\t    pindir(input)\n";
    } elsif ($termtype eq 'o') {
	printf $fp "\t    pindir(output)\n";
    } else {
	printf $fp "\t    pindir(UNKNOWN)\n";
    }
}


sub print_tlf {
    my ($fp) = @_;
    my ($term);
    my ($termname, $termtype);

    printf $fp "/* WARNING: TLF incomplete.  Manual hacking required.  */\n\n";

    printf $fp "/*\n";
    &print_header($fp, ' *');
    printf $fp " */\n\n";

    printf $fp "    cell($cellname \n";

    printf $fp "\n\t/* cell properties */\n";
    &print_tlf_cellprops($fp);

    printf $fp "\n\t/* constraint models */\n";

    printf $fp "\n\t/* delay models */\n";
    foreach $term (@termlist) {
	($termname, $termtype) = split(':', $term);

	if ($termtype eq 'i') {
	    &print_tlf_input_timing($fp, $termname);
	}
	if ($termtype eq 'o') {
	    &print_tlf_output_timing($fp, $termname);
	}
    }

    printf $fp "\n\t/* pin definitions */\n";
    foreach $term (@termlist) {
	($termname, $termtype) = split(':', $term);

	printf $fp "\tpin($termname \n";
	&print_tlf_termprops($fp, $termname, $termtype);

	if ($termtype eq 'i') {
	    printf $fp "\t    timing_props(pin_cap(%.4e))\n",
		$celldata{"$cellname:input_cap:$termname"}
		if $celldata{"$cellname:input_cap:$termname"};
	    printf $fp "\t)\n";
	    next;
	}
	if ($termtype eq 'o') {
	    printf $fp "\t    timing_props(pin_cap(0.0))\n";
	    printf $fp "\t)\n";
	    next;
	}
    }

    printf $fp "\n\t/* register/latch definitions */\n";
    if ($celldata{"$cellname:cellprop:reg_def"}) {
	printf $fp "%s\n", $celldata{"$cellname:cellprop:reg_def"};
    }

    printf $fp "\n\t/* path definitions */\n";
    &print_tlf_path ($fp);

    printf $fp "    )\n";
}



sub print_tlf_path {
    my($fp) = @_;
    my ($key, $cell, $module, $name, $propname, $type, $delay, $slew);
    my ($cltype, $cetype, $model);

    foreach $key (keys(%celldata)) {
	($cell, $module, $src, $dest, $name) = split(':', $key);

	# load delay
	if (($cell eq $cellname) && ($module eq 'load_delay') && ($name eq 'type')) {
	    $type = $celldata{$key};
	    if ($type eq 'inverting') {
		$delay = &format_model ("dly", $src, $dest, "rise");
		$slew = &format_model ("slew", $src, $dest, "rise");
		printf $fp "\tpath($src => $dest 10 01 delay(${delay}) slew(${slew}))\n";

		$delay = &format_model ("dly", $src, $dest, "fall");
		$slew = &format_model ("slew", $src, $dest, "fall");
		printf $fp "\tpath($src => $dest 01 10 delay(${delay}) slew(${slew}))\n";
	    }
	    if ($type eq 'non_inverting') {
		$delay = &format_model ("dly", $src, $dest, "rise");
		$slew = &format_model ("slew", $src, $dest, "rise");
		printf $fp "\tpath($src => $dest 01 01 delay(${delay}) slew(${slew}))\n";

		$delay = &format_model ("dly", $src, $dest, "fall");
		$slew = &format_model ("slew", $src, $dest, "fall");
		printf $fp "\tpath($src => $dest 10 10 delay(${delay}) slew(${slew}))\n";
	    }
	    if ($type eq 'hh') {
		$delay = &format_model ("dly", $src, $dest, "rise");
		$slew = &format_model ("slew", $src, $dest, "rise");
		printf $fp "\tpath($src => $dest 01 01 delay(${delay}) slew(${slew}))\n";
	    }
	    if ($type eq 'hl') {
		$delay = &format_model ("dly", $src, $dest, "fall");
		$slew = &format_model ("slew", $src, $dest, "fall");
		printf $fp "\tpath($src => $dest 10 10 delay(${delay}) slew(${slew}))\n";
	    }
	    if ($type eq 'lh') {
		$delay = &format_model ("dly", $src, $dest, "rise");
		$slew = &format_model ("slew", $src, $dest, "rise");
		printf $fp "\tpath($src => $dest 10 01 delay(${delay}) slew(${slew}))\n";
	    }
	    if ($type eq 'll') {
		$delay = &format_model ("dly", $src, $dest, "fall");
		$slew = &format_model ("slew", $src, $dest, "fall");
		printf $fp "\tpath($src => $dest 10 10 delay(${delay}) slew(${slew}))\n";
	    }
	}

	# clock gate
	if (($cell eq $cellname) && ($module eq 'clock_gate') && ($name eq 'clktype')) {
	    $clktype = $celldata{$key};
	    if ($clktype eq 'rising') {
		$model = &format_model ("setup", $src, $dest, "rise");
		printf $fp "\tsetup($src => $dest 01 posedge $model)\n";
		$model = &format_model ("setup", $src, $dest, "fall");
		printf $fp "\tsetup($src => $dest 10 posedge $model)\n";

		$model = &format_model ("hold", $src, $dest, "rise");
		printf $fp "\thold($src => $dest 01 posedge $model)\n";
		$model = &format_model ("setup", $src, $dest, "fall");
		printf $fp "\thold($src => $dest 10 posedge $model)\n";
	    }
	    if ($clktype eq 'falling') {
		$model = &format_model ("setup", $src, $dest, "rise");
		printf $fp "\tsetup($src => $dest 01 negedge $model)\n";
		$model = &format_model ("setup", $src, $dest, "fall");
		printf $fp "\tsetup($src => $dest 10 negedge $model)\n";

		$model = &format_model ("hold", $src, $dest, "rise");
		printf $fp "\thold($src => $dest 01 negedge $model)\n";
		$model = &format_model ("setup", $src, $dest, "fall");
		printf $fp "\thold($src => $dest 10 negedge $model)\n";
	    }
	}

	# other modules here
    }
}


sub print_tlf_spline {
    my ($fp, $cl) = @_;
    my ($i);

    printf $fp "\t    (spline\n";
    printf $fp "\t\t(input_slew_axis";
    for ($i = 0; $i <= $#slewrate; $i++) {
	printf $fp " %.4e", $slewrate[$i] / $scale_delay;
    }
    printf $fp ")\n";

    if ($cl == 1) {
	printf $fp "\t\t(load_axis";
	for ($i = 0; $i <= $#cload; $i++) {
	    printf $fp " %.4e", $cload[$i] / $scale_cload;
	}
	printf $fp ")\n";
    }
}


sub print_tlf_input_timing {
    my($fp, $input) = @_;
    my ($term);
    my ($clock, $termtype);
    my ($i, @wcvalue);

    foreach $term (@termlist) {
	($clock, $termtype) = split(':', $term);
	if ($termtype eq 'i') {

	    # TO DO: D setup/hold, CE setup/hold

	    # CG SETUP
	    if ($celldata{"$cellname:clock_gate:$input:$clock:setup"}) {

		if ($#slewrate == -1) {
		    # only one value
		    printf $fp "\t/* unsupported single-value model */\n";
		} else {
		    # all values
		    $model = &format_model("setup", $input, $clock, "rise");
		    printf $fp "\tmodel(%s\n", $model;
		    &print_tlf_spline($fp, 0);

		    printf $fp "\t\t(\n\t\t    (";
		    for ($i = 0; $i <= $#slewrate; $i++) {
			printf $fp "%.4e", $celldata{"$cellname:clock_gate:$input:$clock:setup_lh"}[$i];
			printf $fp " " unless ($i == $#slewrate);
		    }
		    printf $fp ")\n\t\t)\n\t    )\n\t)\n";

		    $model = &format_model("setup", $input, $clock, "fall");
		    printf $fp "\tmodel(%s\n", $model;
		    &print_tlf_spline($fp, 0);

		    printf $fp "\t\t(\n\t\t    (";
		    for ($i = 0; $i <= $#slewrate; $i++) {
			printf $fp "%.4e", $celldata{"$cellname:clock_gate:$input:$clock:setup_hl"}[$i];
			printf $fp " " unless ($i == $#slewrate);
		    }
		    printf $fp ")\n\t\t)\n\t    )\n\t)\n";
		}
	    }

	    # CG HOLD
	    if ($celldata{"$cellname:clock_gate:$input:$clock:hold"}) {

		if ($#slewrate == -1) {
		    # only one value
		    printf $fp "\t/* unsupported single-value model */\n";
		} else {
		    # all values
		    $model = &format_model("hold", $input, $clock, "rise");
		    printf $fp "\tmodel(%s\n", $model;
		    &print_tlf_spline($fp, 0);

		    printf $fp "\t\t(\n\t\t    (";
		    for ($i = 0; $i <= $#slewrate; $i++) {
			printf $fp "%.4e", $celldata{"$cellname:clock_gate:$input:$clock:hold_lh"}[$i];
			printf $fp " " unless ($i == $#slewrate);
		    }
		    printf $fp ")\n\t\t)\n\t    )\n\t)\n";

		    $model = &format_model("hold", $input, $clock, "fall");
		    printf $fp "\tmodel(%s\n", $model;
		    &print_tlf_spline($fp, 0);

		    printf $fp "\t\t(\n\t\t    (";
		    for ($i = 0; $i <= $#slewrate; $i++) {
			printf $fp "%.4e", $celldata{"$cellname:clock_gate:$input:$clock:hold_hl"}[$i];
			printf $fp " " unless ($i == $#slewrate);
		    }
		    printf $fp ")\n\t\t)\n\t    )\n\t)\n";
		}
	    }
	}
    }
}


sub print_tlf_output_timing {
    my ($fp, $output) = @_;
    my ($term);
    my ($input, $termtype, $model);
    my ($i, $j, $k);

    foreach $term (@termlist) {
	($input, $termtype) = split(':', $term);
	if ($termtype eq 'i') {

	    # LOAD DELAY
	    if ($celldata{"$cellname:load_delay:$input:$output"}) {

		if ($#slewrate == -1) {

		    # linear model
		    printf $fp "\t/* unsupported linear model */\n";

		} else {

		    # nonlinear model

		    if ($celldata{"$cellname:load_delay:$input:$output:tplh"}) {

			$model = &format_model("dly", $input, $output, "rise");

			printf $fp "\tmodel(%s\n", $model;
			&print_tlf_spline($fp, 1);

			printf $fp "\t\t(";
			$k = 0;
			for ($j = 0; $j <= $#slewrate; $j++) {
			    printf $fp "\n\t\t    (";
			    for ($i = 0; $i <= $#cload; $i++) {
				printf $fp "%.4e",
				    $celldata{"$cellname:load_delay:$input:$output:tplh"}[$k++];
				printf $fp " " unless ($i == $#cload);
			    }
			    printf $fp ")";
			}
			printf $fp "\n\t\t)\n\t    )\n\t)\n";
		    }

		    if ($celldata{"$cellname:load_delay:$input:$output:tphl"}) {

			$model = &format_model("dly", $input, $output, "fall");

			printf $fp "\tmodel(%s\n", $model;
			&print_tlf_spline($fp, 1);

			printf $fp "\t\t(";
			$k = 0;
			for ($j = 0; $j <= $#slewrate; $j++) {
			    printf $fp "\n\t\t    (";
			    for ($i = 0; $i <= $#cload; $i++) {
				printf $fp "%.4e",
				    $celldata{"$cellname:load_delay:$input:$output:tphl"}[$k++];
				printf $fp " " unless ($i == $#cload);
			    }
			    printf $fp ")";
			}
			printf $fp "\n\t\t)\n\t    )\n\t)\n";
		    }

		    if ($celldata{"$cellname:load_delay:$input:$output:risetime"}) {

			$model = &format_model("slew", $input, $output, "rise");

			printf $fp "\tmodel(%s\n", $model;
			&print_tlf_spline($fp, 1);

			printf $fp "\t\t(";
			$k = 0;
			for ($j = 0; $j <= $#slewrate; $j++) {
			    printf $fp "\n\t\t    (";
			    for ($i = 0; $i <= $#cload; $i++) {
				printf $fp "%.4e",
				    $celldata{"$cellname:load_delay:$input:$output:risetime"}[$k++];
				printf $fp " " unless ($i == $#cload);
			    }
			    printf $fp ")";
			}
			printf $fp "\n\t\t)\n\t    )\n\t)\n";
		    }

		    if ($celldata{"$cellname:load_delay:$input:$output:falltime"}) {

			$model = &format_model("slew", $input, $output, "fall");

			printf $fp "\tmodel(%s\n", $model;
			&print_tlf_spline($fp, 1);

			printf $fp "\t\t(";
			$k = 0;
			for ($j = 0; $j <= $#slewrate; $j++) {
			    printf $fp "\n\t\t    (";
			    for ($i = 0; $i <= $#cload; $i++) {
				printf $fp "%.4e",
				    $celldata{"$cellname:load_delay:$input:$output:falltime"}[$k++];
				printf $fp " " unless ($i == $#cload);
			    }
			    printf $fp ")";
			}
			printf $fp "\n\t\t)\n\t    )\n\t)\n";
		    }
		}
	    }
	}
    }
}

1;

