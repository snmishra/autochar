#	$Id: utils.pl,v 1.33 2000/04/19 19:02:12 ryu Exp $

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

#   dump_list:
#	Prints out to STDERR the contents of a given list.
#	For debugging.
#
sub dump_list {
    my($name, @l) = @_;
    my($i);

    printf STDERR "dump_list: @%s = (", $name;
    foreach $i (@l) {
	printf STDERR " '$i',";
    }
    printf STDERR ");\n";
}


#   dump_hash:
#	Prints out to STDERR the contents of a given hash list.
#	For debugging.
#
sub dump_hash {
    my($name, %l) = @_;
    my($key);

    printf STDERR "dump_hash: %%%s = (\n", $name;
    foreach $key (keys(%l)) {
	printf STDERR "    $key => $l{$key},\n";
    }
    printf STDERR ");\n";
}


#   vary_list:
#
sub vary_list {
    my($start, $incr, $N, $units) = @_;
    my($i, @list, $value);

    for ($i = 0; $i <= $N; $i++) {
	$value = $start+$i*$incr . $units;
	push(@list, $value);
    }
    return @list;
}

sub convert_spice_values {
    my(@list) = @_;
    my(@newlist, $value);

    foreach $value (@list) {
	push(@newlist, &spice2float($value));
    }
    return (@newlist);
}


sub spice2float {
    my($value) = @_;
    my($number, $units);

    ($number, $units) = $value =~ /([\d\.]+)([a-zA-Z]+)/;
    $units =~ tr/a-z/A-Z/;
    if ($units eq 'AF') {
	$number *= 1e-18;
	return ($number);
    }
    if ($units eq 'FF') {
	$number *= 1e-15;
	return ($number);
    }
    if ($units eq 'PF') {
	$number *= 1e-12;
	return ($number);
    }
    if ($units eq 'PS') {
	$number *= 1e-12;
	return ($number);
    }
    if ($units eq 'NS') {
	$number *= 1e-9;
	return ($number);
    }
    if ($units eq 'K') {
	$number *= 1e3;
	return ($number);
    }
    return ($value);
}


sub mult_list {
    my($scale, @oldvalues) = @_;
    my($v, @newvalues);

    if ($scale == 1) {
	return(@oldvalues);
    }
    foreach $v (@oldvalues) {
	push(@newvalues, $v*$scale);
    }
    return (@newvalues);
}

sub div_list {
    my($scale, @oldvalues) = @_;
    my($v, @newvalues);

    if ($scale == 0) {
	die "ERROR: cannot scale by 0.\n";
    }
    if ($scale == 1) {
	return(@oldvalues);
    }
    foreach $v (@oldvalues) {
	push(@newvalues, $v/$scale);
    }
    return (@newvalues);
}


sub halve_list {
    my(@oldlist) = @_;
    my($i, @newlist);

    for ($i = 0; (2 * $i) <= $#oldlist; $i++) {
	push (@newlist, @oldlist[(2*$i)]);
    }
    return (@newlist);
}

sub avg_list {
    my(@list) = @_;
    my($i, $sum);

    if ($#list == 0) {
	return (0);
    }

    $sum = 0;
    for ($i = 0; $i <= $#list; $i++) {
	$sum += $list[$i];
    }
    return ($sum/(1 + $#list));
}

sub max {
    my ($a, $b) = @_;

    return ($a) if ($a > $b); 
    return ($b);
}


sub bigger_avg_list {
    local(*list1, *list2) = @_;
    my($avg1, $avg2);

    $avg1 = &avg_list(@list1);
    $avg2 = &avg_list(@list2);

    if ($avg1 > $avg2) {
	return (@list1);
    } else {
	return (@list2);
    }
}

1;
