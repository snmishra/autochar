#	$Id: math.pl,v 1.7 1999/01/20 07:44:59 ryu Exp $

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

#   svlinreg --
#
#	Perform single variable linear regression.  Given lists @X and @Y,
#	calculate a, b, and r2 for the specified type of fit:
#		lin: y = a + b * x
#		exp: y = a * exp (b * x)
#		pow: y = a * x^b
#		log: y = a + b * ln(x)
#	Input is a concatenated list of data points ($type, \@X, \@Y);
#	Output is a list (a, b, r2);
#
sub svlinreg {

    local ($type, *X, *Y) = @_;

    my($x, $y, $sumx, $sumy, $sumxy, $sumx2, $sumy2, $N);
    my($a, $b, $r2);
    my($i);

    # init
    $sumx = 0.0;
    $sumy = 0.0;
    $sumxy = 0.0;
    $sumx2 = 0.0;
    $sumy2 = 0.0;

    $N = $#X;

    for ($i = 0; $i < $N; $i++) {
	if ($type eq 'lin') {
	    $x = $X[$i]; 
	    $y = $Y[$i]; 
	} elsif ($type eq 'exp') {
	    $x = $X[$i]; 
	    $y = log($Y[$i]); 
	} elsif ($type eq 'log') {
	    $x = log($X[$i]); 
	    $y = $Y[$i]; 
	} elsif ($type eq 'pow') {
	    $x = log($X[$i]); 
	    $y = log($Y[$i]); 
	} else {
	    printf STDERR "ERROR: unknown regression type '$type'.\n";
	    die;
	}

	$sumx += $x;
	$sumy += $y;
	$sumxy += ($x * $y);
	$sumx2 += ($x**2);
	$sumy2 += ($y**2);
    }

    # calculate a, b, r2
    $a = ($sumy*$sumx2 - $sumx*$sumxy) / ($N*$sumx2 - $sumx**2);
    $b = ($N*$sumxy - $sumx*$sumy) / ($N*$sumx2 - $sumx**2);
    $r2 = ($a*$sumy + $b*$sumxy - ($sumy**2)/$N) / ($sumy2 - ($sumy**2)/$N);

    return ($a, $b, $r2);
}


#
#    mvlinreg --
#
#	If the m multivariable dataset are give as:
#	
#	Independent variables:
#	    x1: x11, x12, ..., x1N
#	    x2: x21, x22, ..., x2N
#	    ...
#	    xM: xM1, xM2, ..., xMN
#
#	and the dependent variable:
#	    y: y1, y2, ..., yN
#
#	Then the generalized multivariable linear regression is:
#	    y = c0 + c1 x1 + c2 x2 + ... + cN xN
#
#	The inputs to this function are:
#	    ndata	= number of data points (N)
#	    nvar	= number of multivariables (M)
#	    X		= pointer to 2-dimensional array X[i][j],
#			  where (0 <= i < N) and (0 <= j < M).
#	    Y		= pointer to dependent variable Y[i], where
#			  (0 <= i < N).
#	Example:
#	    @X = (
#		[ 11, 21, 31, 41 ],	# datapoint 0
#		[ 12, 22, 32, 42 ],	# datapoint 1
#		[ 13, 23, 33, 43 ],	# datapoint 2
#		[ 14, 24, 34, 44 ],	# datapoint 3
#	    );
#
#	    @Y = (0, 1, 2, 3);
#
sub mvlinreg {

    local($ndata, $nvar, *X, *Y) = @_;
    local (@x, @y, @a, @b, @c);
    local ($i, $j, $k, $l);

    # place X[0:N-1][0:M-1] into x[1:N][1:M]
    for $i (1 .. $ndata) {
	for $j (1 .. $nvar) {
	    $x[$i][$j] = $X[$i-1][$j-1];
	} # j
    } # i
    for $i (1 .. $ndata)  {
	$x[$i][0]= 1.0;
    } # i

    # place Y[0:N-1] into y[1:N]
    for $i (1 .. $ndata) {
	$y[$i] = $Y[$i-1];
    } # i

    for $j (1 .. $nvar+1) {
	for $k (1 .. $nvar+1) {
	    $a[$j][$k] = 0.0;
	} # k
        $b[$j] = 0.0;
    } # j

    for $j (1 .. $nvar+1) {
	for $k ($j .. $nvar+1) {
	    for $i (1 .. $ndata) {
		$a[$j][$k] = $a[$j][$k] + ($x[$i][$j-1] * $x[$i][$k-1]);
	    } # i
	} # k
    } # j

    for $j (2 .. $nvar+1) {
	for $k (1 .. $j-1) {
	    $a[$j][$k] = $a[$k][$j];
	} # k
    } # j

    for $j (1 .. $nvar+1) {
	for $i (1 .. $ndata) {
	    $b[$j] = $b[$j] + ($x[$i][$j-1] * $y[$i]);
	} # i
    } # j

    &solve_mvlinreg( \@a, \@b, \@c, $nvar+1);

    return(@c);
}

sub solve_mvlinreg(a,b,c,n) {
    local(*a, *b, *c, $n) = @_;
    my ($i, $j, $k, $l);
    my ($ihold, $big, $hold, $fac, $sum);

    for $i (1 .. $n-1) {
	$big = abs($a[$i][$i]);
        $ihold = $i;
        for $j ($i+1 .. $n) {
	    if (abs($a[$j][$i]) > $big) {
		$big = abs($a[$j][$i]);
		$ihold = $j;
	    }
	} # j

	if ($ihold != $i) {
	    for $j ($i .. $n) {
		$hold = $a[$i][$j];
		$a[$i][$j] = $a[$ihold][$j];
		$a[$ihold][$j] = $hold;
	    } # j

	    $hold = $b[$i];
	    $b[$i] = $b[$ihold];
	    $b[$ihold] = $hold;
	}

	for $j ($i+1 .. $n) {
	    $fac = $a[$j][$i]/$a[$i][$i];
	    for $l (1 .. $n) {
		$a[$j][$l] = $a[$j][$l] - ($a[$i][$l] * $fac);
	    }
	    $b[$j] = $b[$j] - ($b[$i] * $fac);
	} # j 
    } # i

    for ($i=$n; $i>=1; $i--) {
	$sum = 0;
        for $l ($i+1 .. $n) {
	    $sum = $sum + ($a[$i][$l] * $c[$l]);
	} # l
        $c[$i] = ($b[$i]-$sum) / $a[$i][$i];
    } # i
}

#   is_even:
#	Returns 1 if scalar value is even.  0 otherwise.
#
sub is_even {
    my($i) = @_;
    return (($i % 2) == 0);
}


#   is_odd:
#	Returns 1 if scalar value is odd.  0 otherwise.
#
sub is_odd {
    my($i) = @_;
    return (($i % 2) == 1);
}


1;
