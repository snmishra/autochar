#	$Id: common.pl,v 1.10 1999/12/16 11:27:05 ryu Exp $

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

require 'ctime.pl';

#   lookup_input --
#	GIven a term, figure out if it makes reference to
#	another term, or how to tie it, either to high or low.
#	Modifies variables $term_no and @vcvs_list
sub lookup_input {

    local($term, *inlist, *reflist, $tie, @tie_list) = @_;
    my($expression, $str);
    my($i, $in, $refname);

    for ($i = 0; $i <= $#inlist; $i++) {
	$in = $inlist[$i];
	$refname = $reflist[$i];
	if ($equivalent{$term} eq $in) {
	    $str = sprintf ("e%s equiv_%s %s %s %s +1",
		$term_no, $term_no, $low_value, $refname, $low_value);
	    push(@vcvs_list, $str);
	    return ('equiv_' . $term_no++);
	}

	if ($differential{$term} eq $in) {
	    $str = sprintf ("e%s diff_%s %s %s %s -1",
		$term_no, $term_no, $low_value, $refname, $high_node);
	    push(@vcvs_list, $str);
	    return ('diff_' . $term_no++);
	}
    }

    foreach $expression (@tie_list) {
	if ($term =~ /$expression/) {
	    if ($tie eq 'tie_high') {
		return $high_node;
	    } else {
		return $low_node;
	    }
	}
    }

    # does not match any expression,
    # so tie it to the opposite
    if ($tie eq 'tie_high') {
	return $low_node;
    } elsif ($tie eq 'tie_low') {
	return $high_node;
    } elsif ($tie eq '') {
	return $low_node;
    } else {
	die "ERROR: unknown tie '$tie' specified.\n";
    }
}


#
#   lookup_output_load --
#	Modifies variables $term_no and @output_loads
#
sub lookup_output_load {

    my($term, $termname) = @_;
    my($lookup, $load_type, $load_value);
    my($inc, $str);

    $inc = 0;

    # give it a name, if not provided
    if ($termname eq '') {
	$inc = 1;
	$termname = 'out_' . $term_no;
    }

    # lookup the load value
    $lookup = $load{$term};
    if ($lookup eq '') {
	$lookup = $load{'default'};
    } 
    if ($lookup eq 'none') {
	$term_no++ if $inc;
	return ($termname);
    } else {
	($load_type, $load_value) = split(':', $lookup);
	if ($load_type eq 'cap') {
	    $str = sprintf ("c%s %s %s %s",
		$term_no, $termname, $low_value, $load_value);
	    push(@output_loads, $str);
	    $term_no++;
	    return ($termname);
	}
	if ($load_type eq 'res') {
	    $str = sprintf ("r%s %s %s %s",
		$term_no, $termname, $low_value, $load_value);
	    push(@output_loads, $str);
	    $term_no++;
	    return ($termname);
	}
	if ($load_type eq 'subckt') {
	    $str = sprintf ("x%s %s %s",
		$term_no, $termname, $load_value);
	    push(@output_loads, $str);
	    $term_no++;
	    return ($termname);
	}
    }
}


sub set_measure_values {
    local (
	*input_prop_r, *input_prop_f,
	*output_prop_r, *output_prop_f,
	*trans_r1, *trans_r2,
	*trans_f1, *trans_f2,
	*slew_r1, *slew_r2,
	*slew_f1, *slew_f2) = @_;

    # measure prop delays from inputs at these values
    $input_prop_r = $low_value . '+' . $input_prop_percent . '*' . $high_value;
    $input_prop_f = $low_value . '+(1-' . $input_prop_percent . ')*' . $high_value;

    # measure prop delays to outputs at these values
    $output_prop_r = $low_value . '+' . $output_prop_percent . '*' . $high_value;
    $output_prop_f = $low_value . '+(1-' . $output_prop_percent . ')*' . $high_value;

    # measure output rise transitions at these two points
    $trans_r1 = $low_value . '+' . $start_trans_percent . '*' . $high_value;
    $trans_r2 = $low_value . '+' . $end_trans_percent . '*' . $high_value;

    # measure output fall transitions at these two points
    $trans_f1 = $low_value . '+(1-' . $start_trans_percent . ')*' . $high_value;
    $trans_f2 = $low_value . '+(1-' . $end_trans_percent . ')*' . $high_value;

    # measure input rise slew transitions at these two points
    $slew_r1 = $low_value . '+' . $start_slew_percent . '*' . $high_value;
    $slew_r2 = $low_value . '+' . $end_slew_percent . '*' . $high_value;

    # measure output fall slew transitions at these two points
    $slew_f1 = $low_value . '+(1-' . $start_slew_percent . ')*' . $high_value;
    $slew_f2 = $low_value . '+(1-' . $end_slew_percent . ')*' . $high_value;
}


#   read_spice_terms --
#	Extract the terminal order and direction from the embedded comments
#	that may be found in the spice netlist
sub read_spice_terms {
    my($filename, $cellname) = @_;
    my(@tlist, %dirlist, $i);

    @tlist = &get_subckt_terms($filename, $cellname);
    %dirlist = &get_subckt_directions($filename, $cellname);

    for ($i = 0; $i <= $#tlist; $i++) {
	if ($dirlist{$tlist[$i]} eq 'input') {
	    $tlist[$i] = $tlist[$i] . ':i';
	} elsif ($dirlist{$tlist[$i]} eq 'output') {
	    $tlist[$i] = $tlist[$i] . ':o';
	} elsif ($dirlist{$tlist[$i]} eq '') {
	    printf STDERR
		"WARNING: unknown direction for terminal '$tlist[$i]'.\n";
	} else {
	    printf STDERR
		"WARNING: unknown direction '$dirlist{$tlist[$i]}' for terminal '$tlist[$i]'.\n";
	}
    }
    return @tlist;
}


#   get_subckt_directions --
#	Look for spice comments that indicate direction
sub get_subckt_directions {
    my($filename, $cellname) = @_;
    my($found_cell, $found_ports, $count, %tlist);

    open(FA, $filename) || die "ERROR: Cannot open spice file '$filename'.\n"; 

    $found_cell = 0;
    $found_ports = 0;
    $count = 0;

    while (<FA>) {
	if (/^.subckt\s+$cellname\s+(.*)/i) {
	    $found_cell = 1 ;
	    next;
	}
	if (/\* Begin port declarations/) {
	    $found_ports = 1 ;
	    next;
	}
	if ($found_cell && $found_ports) {
	    if (($direction, $term) = /\* port (input|output) ([<>\w]+)/) {
		#$term =~ tr/A-Z/a-z/;
		$tlist{$term} = $direction;
		$count++;
		next;
	    }
	    if (/\* End port declarations/) {
		last;
	    }
	}
    }
    if ($count == 0) {
	printf STDERR "WARNING: no terminal definitions found in spice netlist.\n";
    }
    return (%tlist);
}

#
#   get_subckt_terms --
#	Return a list of terminals from the subckt in the given file.
#
sub get_subckt_terms {
    my($filename, $cellname) = @_;
    my($found, @tlist);

    open(FA, $filename) || die "ERROR: Cannot open spice file '$filename'.\n"; 

    @tlist = ();
    $found = 0;

    while (<FA>) {
	if (($terms) = /^.subckt\s+$cellname\s+(.*)/i) {
	    $found = 1;
	    #$terms =~ tr/A-Z/a-z/;
	    @tlist = split(' ', $terms);
	    next;
	}

	if ($found) {
	    if (($terms) = /^\+(.*)/i) {
		#$terms =~ tr/A-Z/a-z/;
		push (@tlist, split(' ', $terms));
	    } elsif (/^\s*\*.*/) {
		# ignore comment
	    } else {
		last;
	    }
	}
    }
    if ($#tlist == -1) {
	printf STDERR "WARNING: no terminals found in spice netlist.\n";
    }
    return @tlist;
}

#   print_header:
#	Print out to the give $fname a standard header.  The 'comment'
#	argument is the character(s) used to denote the beginning of
#	a comment, typically the "#" or "*" character.
#
sub print_header {
    my($fname, $comment) = @_;
    my($user, $date);

    $user = $ENV{'USER'};
    $date = &ctime(time);

    # use select();
    printf $fname "$comment	\$\Id\$\n\n";
    printf $fname "$comment	DO NOT EDIT.  This file generated automagically.\n";
    printf $fname "$comment	Created: $date";
    printf $fname "$comment	User: $user\n\n";
}
#   uniq_run_file_name:
#	Removes any offensive characters that are not allowed in
#	unix filenames. Modifies $spice_run.
#
sub uniq_run_file_name {
    my($cellname, @items) = @_;
    my($name, $item);

    $name = $cellname;
    foreach $item (@items) {
	$name = $name . '.' . $item
    }

    $name = $name . '_' . $spice_run . '.sp'; 
    $spice_run++;

    # get rid of any illegal characters here.
    ($name = $name) =~ tr/\[\]/--/;
    ($name = $name) =~ tr/\<\>/--/;
    return $name;
}


#   run_file_name:
#
sub run_file_name {
    my($cellname, @items) = @_;
    my($tryname);

    # funny, this routine fails if you use $spice_run_list{'$tryname'}
    do {
	$tryname = &uniq_run_file_name($cellname, @items);
    } until $spice_run_list{$tryname} != 1;

    $spice_run_list{$tryname} = 1;
    return ($tryname);
}


sub run_spice {

    my($run_name) = @_;
    my($base,$dir,$type,$spiceout);

    ($base,$dir,$type) = fileparse($run_name, '\.sp');
    $spiceout = $base . '.out';

    # Run hspice
    if ($skip && (-e $spiceout)) {
	printf STDERR "Found \"%s\", skipping run.\n", $spiceout;
    } else {
	printf STDERR "Running %s on \"%s\" ...\n", $spice_cmd, $run_name;
	`$spice_cmd $run_name`;
    }
}


sub check_spice_run {
    if (/^\s*\*\*error\*\*/) {
	printf STDERR "ERROR: spice '$run_name' failed.\n";
	return;
    }
    if (/\*\*\*\*\* job aborted/) {
	printf STDERR "ERROR: spice '$run_name' failed.\n";
	return;
    }
}


sub trig_word {
    if ($spice_type eq 'smartspice') {
	return 'delay';
    } else {
	return 'trig=';
    }
}


1;
