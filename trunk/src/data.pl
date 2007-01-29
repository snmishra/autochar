#	$Id: data.pl,v 1.20 2000/02/01 04:24:26 ryu Exp $

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


#	celldata format:
#
#	    <cellname>:load_delay:
#		load_delay characterization data
#	    <cellname>:input_cap:
#		input_cap characterization data
#	    <cellname>:clock_q:
#		clock_q characterization data
#	    <cellname>:setup_hold:
#		setup_hold characterization data
#	    <cellname>:clock_enable:
#		clock_enable characterization data
#
#	    <cellname>:cellprop:<propname>:
#		cell properties
#	    <cellname>:termprop:<termname>:<propname>
#		term properties


sub read_db {
    my($dbname) = @_;
    (-e $dbname) || die "ERROR:  Cannot read db file '$dbname'.\n";
    require $dbname;
}


sub write_db {
    my($dbname) = @_;
    my ($key, $i);

    open(DB, "> $dbname") || die "ERROR:  Cannot create db file '$dbname'.\n";

    #printf DB "#!/usr/local/bin/perl\n\n";
    &print_header (DB, '#');

    foreach $key (sort keys(%celldata)) {
	if ($celldata{$key}[0]) {
	    printf DB "\$celldata{\"$key\"} = [\n";
	    for $i (0 .. $#{@celldata{$key}}) {
		printf DB "    $celldata{$key}[$i],\n";
	    }
	    printf DB "    ] ;\n";
	} else {
	    printf DB "\$celldata{\"$key\"} = q/$celldata{$key}/ ;\n";
	}
    }
    close(DB);
    printf STDERR "Created '$dbname'.\n";
}

### SAVE DATA #############################################################################

sub ic_save_data {
    my($cellname, $in, $cscaled) = @_;

    $celldata{"$cellname:input_cap:$in"} = $cscaled;
}


#
#   cq_save_data --
#
sub cq_save_data {
    local($cellname, $clk, $clkout, $clktype,
	*creal, *clk_q_lh, *clk_q_hl, *risetime, *falltime) = @_;

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

    $celldata{"$cellname:clock_q:$clk:$clkout"} = 1;
    $celldata{"$cellname:clock_q:$clk:$clkout:clktype"} = $clktype;
    $celldata{"$cellname:clock_q:$clk:$clkout:clk_q_lha"} = $clk_q_lha; 
    $celldata{"$cellname:clock_q:$clk:$clkout:clk_q_lhb"} = $clk_q_lhb; 
    $celldata{"$cellname:clock_q:$clk:$clkout:clk_q_hla"} = $clk_q_hla; 
    $celldata{"$cellname:clock_q:$clk:$clkout:clk_q_hlb"} = $clk_q_hlb; 
    $celldata{"$cellname:clock_q:$clk:$clkout:risetimea"} = $risetimea; 
    $celldata{"$cellname:clock_q:$clk:$clkout:risetimeb"} = $risetimeb; 
    $celldata{"$cellname:clock_q:$clk:$clkout:falltimea"} = $falltimea; 
    $celldata{"$cellname:clock_q:$clk:$clkout:falltimeb"} = $falltimeb; 

    # save raw data
    $celldata{"$cellname:clock_q:$clk:$clkout:lu_table"} = $lu_table_name;
    $celldata{"$cellname:clock_q:$clk:$clkout:clk_q_lh"} = [ @clk_q_lh ]; 
    $celldata{"$cellname:clock_q:$clk:$clkout:clk_q_hl"} = [ @clk_q_hl ]; 
    $celldata{"$cellname:clock_q:$clk:$clkout:risetime"} = [ @risetime ]; 
    $celldata{"$cellname:clock_q:$clk:$clkout:falltime"} = [ @falltime ]; 
}


#
#   ld_save_data --
#
sub ld_save_data {
    local ($cellname, $type, $in, $out, *creal,
	*tplh, *tphl, *risetime, *falltime, *inputrise, *inputfall) = @_;

    my($risetimea, $risetimeb, $risetimer2);
    my($falltimea, $falltimeb, $falltimer2);
    my($tplha, $tplhb, $tplhr2);
    my($tphla, $tphlb, $tphlr2);

    $celldata{"$cellname:load_delay:$in:$out"} = 1;
    $celldata{"$cellname:load_delay:$in:$out:type"} = $type;

    if ($#slewrate == -1) {

	# do single value linear regression
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

	$celldata{"$cellname:load_delay:$in:$out:tplha"} = $tplha; 
	$celldata{"$cellname:load_delay:$in:$out:tplhb"} = $tplhb; 
	$celldata{"$cellname:load_delay:$in:$out:tphla"} = $tphla; 
	$celldata{"$cellname:load_delay:$in:$out:tphlb"} = $tphlb; 
	$celldata{"$cellname:load_delay:$in:$out:risetimea"} = $risetimea; 
	$celldata{"$cellname:load_delay:$in:$out:risetimeb"} = $risetimeb; 
	$celldata{"$cellname:load_delay:$in:$out:falltimea"} = $falltimea; 
	$celldata{"$cellname:load_delay:$in:$out:falltimeb"} = $falltimeb; 

    }

    # always save raw data
    $celldata{"$cellname:load_delay:$in:$out:lu_table"} = $lu_table_name;
    $celldata{"$cellname:load_delay:$in:$out:tplh"} = [ @tplh ]; 
    $celldata{"$cellname:load_delay:$in:$out:tphl"} = [ @tphl ]; 
    $celldata{"$cellname:load_delay:$in:$out:risetime"} = [ @risetime ]; 
    $celldata{"$cellname:load_delay:$in:$out:falltime"} = [ @falltime ]; 
    $celldata{"$cellname:load_delay:$in:$out:inputrise"} = [ @inputrise ]; 
    $celldata{"$cellname:load_delay:$in:$out:inputfall"} = [ @inputfall ]; 
}


sub s_save_data {
    local ($cellname, $d, $clk, $clktype, $trans, *value) = @_;

    $celldata{"$cellname:setup_hold:$d:$clk:lu_table"} = $lu_table_name;
    $celldata{"$cellname:setup_hold:$d:$clk:setup"} = 1;
    $celldata{"$cellname:setup_hold:$d:$clk:clktype"} = $clktype;
    $celldata{"$cellname:setup_hold:$d:$clk:$trans"} = [ @value ];
}

sub h_save_data {
    local ($cellname, $d, $clk, $clktype, $trans, *value) = @_;

    $celldata{"$cellname:setup_hold:$d:$clk:lu_table"} = $lu_table_name;
    $celldata{"$cellname:setup_hold:$d:$clk:hold"} = 1;
    $celldata{"$cellname:setup_hold:$d:$clk:clktype"} = $clktype;
    $celldata{"$cellname:setup_hold:$d:$clk:$trans"} = [ @value ];
}

sub ces_save_data {
    local ($cellname, $ce, $cetype, $clk, $clktype, $trans, *value) = @_;

    $celldata{"$cellname:clock_enable:$ce:$clk:lu_table"} = $lu_table_name;
    $celldata{"$cellname:clock_enable:$ce:$clk:setup"} = 1;
    $celldata{"$cellname:clock_enable:$ce:$clk:clktype"} = $clktype;
    $celldata{"$cellname:clock_enable:$ce:$clk:cetype"} = $cetype;
    $celldata{"$cellname:clock_enable:$ce:$clk:$trans"} = [ @value ];
}

sub ceh_save_data {
    local ($cellname, $ce, $cetype, $clk, $clktype, $trans, *value) = @_;

    $celldata{"$cellname:clock_enable:$ce:$clk:lu_table"} = $lu_table_name;
    $celldata{"$cellname:clock_enable:$ce:$clk:hold"} = 1;
    $celldata{"$cellname:clock_enable:$ce:$clk:clktype"} = $clktype;
    $celldata{"$cellname:clock_enable:$ce:$clk:cetype"} = $cetype;
    $celldata{"$cellname:clock_enable:$ce:$clk:$trans"} = [ @value ];
}

sub cgs_save_data {
    local ($cellname, $ce, $cetype, $clk, $clktype, $trans, *value) = @_;

    $celldata{"$cellname:clock_gate:$ce:$clk:lu_table"} = $lu_table_name;
    $celldata{"$cellname:clock_gate:$ce:$clk:setup"} = 1;
    $celldata{"$cellname:clock_gate:$ce:$clk:clktype"} = $clktype;
    $celldata{"$cellname:clock_gate:$ce:$clk:cetype"} = $cetype;
    $celldata{"$cellname:clock_gate:$ce:$clk:$trans"} = [ @value ];
}

sub cgh_save_data {
    local ($cellname, $ce, $cetype, $clk, $clktype, $trans, *value) = @_;

    $celldata{"$cellname:clock_gate:$ce:$clk:lu_table"} = $lu_table_name;
    $celldata{"$cellname:clock_gate:$ce:$clk:hold"} = 1;
    $celldata{"$cellname:clock_gate:$ce:$clk:clktype"} = $clktype;
    $celldata{"$cellname:clock_gate:$ce:$clk:cetype"} = $cetype;
    $celldata{"$cellname:clock_gate:$ce:$clk:$trans"} = [ @value ];
}


### COPY DATA #############################################################################

sub ld_copy_data {
    my($cellname, $in, $out, $refin, $refout) = @_;

    if ($celldata{"$cellname:load_delay:$refin:$refout"}) {

	$celldata{"$cellname:load_delay:$in:$out"} = 1;
	$celldata{"$cellname:load_delay:$in:$out:type"} =
	    $celldata{"$cellname:load_delay:$refin:$refout:type"};

	if ($#slewrate == -1) {
	    $celldata{"$cellname:load_delay:$in:$out:tplha"} =
		$celldata{"$cellname:load_delay:$refin:$refout:tplha"};
	    $celldata{"$cellname:load_delay:$in:$out:tplhb"} =
		$celldata{"$cellname:load_delay:$refin:$refout:tplhb"};
	    $celldata{"$cellname:load_delay:$in:$out:tphla"} =
		$celldata{"$cellname:load_delay:$refin:$refout:tphla"};
	    $celldata{"$cellname:load_delay:$in:$out:tphlb"} =
		$celldata{"$cellname:load_delay:$refin:$refout:tphlb"};
	    $celldata{"$cellname:load_delay:$in:$out:risetimea"} =
		$celldata{"$cellname:load_delay:$refin:$refout:risetimea"};
	    $celldata{"$cellname:load_delay:$in:$out:risetimeb"} =
		$celldata{"$cellname:load_delay:$refin:$refout:risetimeb"};
	    $celldata{"$cellname:load_delay:$in:$out:falltimea"} =
		$celldata{"$cellname:load_delay:$refin:$refout:falltimea"};
	    $celldata{"$cellname:load_delay:$in:$out:falltimeb"} =
		$celldata{"$cellname:load_delay:$refin:$refout:falltimeb"};
	}

	$celldata{"$cellname:load_delay:$in:$out:lu_table"} =
	    $celldata{"$cellname:load_delay:$refin:$refout:lu_table"};
	$celldata{"$cellname:load_delay:$in:$out:tplh"} =
	    $celldata{"$cellname:load_delay:$refin:$refout:tplh"};
	$celldata{"$cellname:load_delay:$in:$out:tplh"} =
	    $celldata{"$cellname:load_delay:$refin:$refout:tplh"};
	$celldata{"$cellname:load_delay:$in:$out:tphl"} =
	    $celldata{"$cellname:load_delay:$refin:$refout:tphl"};
	$celldata{"$cellname:load_delay:$in:$out:risetime"} =
	    $celldata{"$cellname:load_delay:$refin:$refout:risetime"};
	$celldata{"$cellname:load_delay:$in:$out:falltime"} =
	    $celldata{"$cellname:load_delay:$refin:$refout:falltime"};
	$celldata{"$cellname:load_delay:$in:$out:inputrise"} =
	    $celldata{"$cellname:load_delay:$refin:$refout:inputrise"};
	$celldata{"$cellname:load_delay:$in:$out:inputfall"} =
	    $celldata{"$cellname:load_delay:$refin:$refout:inputfall"};

    } else {
	printf STDERR "WARNING: No load_delay data associated with \"$refin\" to \"$refout\".\n";
    }
}


sub ic_copy_data {
    my($cellname, $in, $refin) = @_;

    $celldata{"$cellname:input_cap:$in"} =
	$celldata{"$cellname:input_cap:$refin"};
}


sub cq_copy_data {
    local($cellname, $clktype, $clk, $clkout, $refclk, $refq) = @_;

    if ($celldata{"$cellname:clock_q:$refclk:$refq"}) {
	$celldata{"$cellname:clock_q:$clk:$clkout"} = 1;
	$celldata{"$cellname:clock_q:$clk:$clkout:clktype"} = $clktype;
	$celldata{"$cellname:clock_q:$clk:$clkout:clk_q_lha"} =
	    $celldata{"$cellname:clock_q:$refclk:$refq:clk_q_lha"};
	$celldata{"$cellname:clock_q:$clk:$clkout:clk_q_lhb"} =
	    $celldata{"$cellname:clock_q:$refclk:$refq:clk_q_lhb"};
	$celldata{"$cellname:clock_q:$clk:$clkout:clk_q_hla"} =
	    $celldata{"$cellname:clock_q:$refclk:$refq:clk_q_hla"};
	$celldata{"$cellname:clock_q:$clk:$clkout:clk_q_hlb"} =
	    $celldata{"$cellname:clock_q:$refclk:$refq:clk_q_hlb"};
	$celldata{"$cellname:clock_q:$clk:$clkout:risetimea"} =
	    $celldata{"$cellname:clock_q:$refclk:$refq:risetimea"};
	$celldata{"$cellname:clock_q:$clk:$clkout:risetimea"} =
	    $celldata{"$cellname:clock_q:$refclk:$refq:risetimea"};
	$celldata{"$cellname:clock_q:$clk:$clkout:risetimeb"} =
	    $celldata{"$cellname:clock_q:$refclk:$refq:risetimeb"};
	$celldata{"$cellname:clock_q:$clk:$clkout:falltimea"} =
	    $celldata{"$cellname:clock_q:$refclk:$refq:falltimea"};
	$celldata{"$cellname:clock_q:$clk:$clkout:falltimeb"} =
	    $celldata{"$cellname:clock_q:$refclk:$refq:falltimeb"};

	$celldata{"$cellname:clock_q:$clk:$clkout:lu_table"} =
	    $celldata{"$cellname:clock_q:$refclk:$refq:lu_table"};
	$celldata{"$cellname:clock_q:$clk:$clkout:clk_q_lh"} =
	    $celldata{"$cellname:clock_q:$refclk:$refq:clk_q_lh"};
	$celldata{"$cellname:clock_q:$clk:$clkout:clk_q_hl"} =
	    $celldata{"$cellname:clock_q:$refclk:$refq:clk_q_hl"};
	$celldata{"$cellname:clock_q:$clk:$clkout:risetime"} =
	    $celldata{"$cellname:clock_q:$refclk:$refq:risetime"};
	$celldata{"$cellname:clock_q:$clk:$clkout:falltime"} =
	    $celldata{"$cellname:clock_q:$refclk:$refq:falltime"};

    } else {
	printf STDERR "WARNING: No clock-clkout data associated with \"$refclk\" to \"$refq\".\n";
    }
}


sub sh_copy_data {
    my ($cellname, $d, $clktype, $clk, $refd, $refclk) = @_;

    $celldata{"$cellname:setup_hold:$d:$clk:setup"} = 1;
    $celldata{"$cellname:setup_hold:$d:$clk:hold"} = 1;
    $celldata{"$cellname:setup_hold:$d:$clk:clktype"} = $clktype;
    $celldata{"$cellname:setup_hold:$d:$clk:lu_table"} =
	$celldata{"$cellname:setup_hold:$refd:$refclk:lu_table"};

    $celldata{"$cellname:setup_hold:$d:$clk:setup_lh"} =
	$celldata{"$cellname:setup_hold:$refd:$refclk:setup_lh"};
    $celldata{"$cellname:setup_hold:$d:$clk:setup_hl"} =
	$celldata{"$cellname:setup_hold:$refd:$refclk:setup_hl"};

    $celldata{"$cellname:setup_hold:$d:$clk:hold_lh"} =
	$celldata{"$cellname:setup_hold:$refd:$refclk:hold_lh"};
    $celldata{"$cellname:setup_hold:$d:$clk:hold_hl"} =
	$celldata{"$cellname:setup_hold:$refd:$refclk:hold_hl"};
}

sub ce_copy_data {
    my ($cellname, $cetype, $ce, $clktype, $clk, $refce, $refclk) = @_;

    $celldata{"$cellname:clock_enable:$ce:$clk:setup"} = 1;
    $celldata{"$cellname:clock_enable:$ce:$clk:hold"} = 1;
    $celldata{"$cellname:clock_enable:$ce:$clk:clktype"} = $clktype;
    $celldata{"$cellname:clock_enable:$ce:$clk:cetype"} = $cetype;
    $celldata{"$cellname:clock_enable:$ce:$clk:lu_table"} =
	$celldata{"$cellname:clock_enable:$refce:$refclk:lu_table"};

    $celldata{"$cellname:clock_enable:$ce:$clk:setup_lh"} =
	$celldata{"$cellname:clock_enable:$refce:$refclk:setup_lh"};
    $celldata{"$cellname:clock_enable:$ce:$clk:setup_hl"} =
	$celldata{"$cellname:clock_enable:$refce:$refclk:setup_hl"};

    $celldata{"$cellname:clock_enable:$ce:$clk:hold_lh"} =
	$celldata{"$cellname:clock_enable:$refce:$refclk:hold_lh"};
    $celldata{"$cellname:clock_enable:$ce:$clk:hold_hl"} =
	$celldata{"$cellname:clock_enable:$refce:$refclk:hold_hl"};
}

sub cg_copy_data {
    my ($cellname, $cetype, $ce, $clktype, $clk, $refce, $refclk) = @_;

    $celldata{"$cellname:clock_gate:$ce:$clk:setup"} = 1;
    $celldata{"$cellname:clock_gate:$ce:$clk:hold"} = 1;
    $celldata{"$cellname:clock_gate:$ce:$clk:clktype"} = $clktype;
    $celldata{"$cellname:clock_gate:$ce:$clk:cetype"} = $cetype;
    $celldata{"$cellname:clock_gate:$ce:$clk:lu_table"} =
	$celldata{"$cellname:clock_gate:$refce:$refclk:lu_table"};

    $celldata{"$cellname:clock_gate:$ce:$clk:setup_lh"} =
	$celldata{"$cellname:clock_gate:$refce:$refclk:setup_lh"};
    $celldata{"$cellname:clock_gate:$ce:$clk:setup_hl"} =
	$celldata{"$cellname:clock_gate:$refce:$refclk:setup_hl"};

    $celldata{"$cellname:clock_gate:$ce:$clk:hold_lh"} =
	$celldata{"$cellname:clock_gate:$refce:$refclk:hold_lh"};
    $celldata{"$cellname:clock_gate:$ce:$clk:hold_hl"} =
	$celldata{"$cellname:clock_gate:$refce:$refclk:hold_hl"};
}



1;

