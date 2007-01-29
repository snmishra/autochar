#	$Id: stdcells.spec,v 1.4 1999/01/29 07:32:13 ryu Exp $

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

#	Given a cellname, lookup the spec to use.

$specpath = $ENV{'AUTOCHAR'} . '/example/specs';

%specmap = (
    "and2_1x"		=> "${specpath}/and2.spec",
    "and2_2x"		=> "${specpath}/and2.spec",
    "and2_4x"		=> "${specpath}/and2.spec",
    "and2_6x"		=> "${specpath}/and2.spec",

    "and3_2x"		=> "${specpath}/and3.spec",
    "and3_4x"		=> "${specpath}/and3.spec",

    "and4_2x"		=> "${specpath}/and4.spec",
    "and4_4x"		=> "${specpath}/and4.spec",

    "aoi21_1x"		=> "${specpath}/aoi21.spec",
    "aoi21_2x"		=> "${specpath}/aoi21.spec",
    "aoi21_4x"		=> "${specpath}/aoi21.spec",

    "aoi22_1x"		=> "${specpath}/aoi22.spec",
    "aoi22_2x"		=> "${specpath}/aoi22.spec",
    "aoi22_4x"		=> "${specpath}/aoi22.spec",

    "buf_3x"		=> "${specpath}/buf.spec",
    "buf_4x"		=> "${specpath}/buf.spec",
    "buf_6x"		=> "${specpath}/buf.spec",
    "buf_8x"		=> "${specpath}/buf.spec",
    "buf_10x"		=> "${specpath}/buf.spec",
    "buf_12x"		=> "${specpath}/buf.spec",

    "dff_2x"		=> "${specpath}/dff.spec",
    "dffce_2x"		=> "${specpath}/dffce.spec",

    "inv_1x"		=> "${specpath}/inv.spec",
    "inv_2x"		=> "${specpath}/inv.spec",
    "inv_3x"		=> "${specpath}/inv.spec",
    "inv_4x"		=> "${specpath}/inv.spec",
    "inv_6x"		=> "${specpath}/inv.spec",
    "inv_8x"		=> "${specpath}/inv.spec",
    "inv_10x"		=> "${specpath}/inv.spec",
    "inv_12x"		=> "${specpath}/inv.spec",
    "inv_16x"		=> "${specpath}/inv.spec",
    "inv_18x"		=> "${specpath}/inv.spec",

    "mux2i_2x"		=> "${specpath}/mux2.spec",
    "mux2i_4x"		=> "${specpath}/mux2.spec",
    "mux2i_6x"		=> "${specpath}/mux2.spec",

    "nand2_1x"		=> "${specpath}/nand2.spec",
    "nand2_2x"		=> "${specpath}/nand2.spec",
    "nand2_4x"		=> "${specpath}/nand2.spec",
    "nand2_6x"		=> "${specpath}/nand2.spec",
    "nand2_8x"		=> "${specpath}/nand2.spec",

    "nand3_1x"		=> "${specpath}/nand3.spec",
    "nand3_2x"		=> "${specpath}/nand3.spec",
    "nand3_4x"		=> "${specpath}/nand3.spec",
    "nand3_6x"		=> "${specpath}/nand3.spec",

    "nor2_1x"		=> "${specpath}/nor2.spec",
    "nor2_2x"		=> "${specpath}/nor2.spec",
    "nor2_4x"		=> "${specpath}/nor2.spec",
    "nor2_6x"		=> "${specpath}/nor2.spec",
    "nor2_8x"		=> "${specpath}/nor2.spec",

    "nor3_1x"		=> "${specpath}/nor3.spec",
    "nor3_2x"		=> "${specpath}/nor3.spec",
    "nor3_4x"		=> "${specpath}/nor3.spec",
    "nor3_6x"		=> "${specpath}/nor3.spec",

    "oai21_1x"		=> "${specpath}/oai21.spec",
    "oai21_2x"		=> "${specpath}/oai21.spec",
    "oai21_4x"		=> "${specpath}/oai21.spec",

    "oai22_1x"		=> "${specpath}/oai22.spec",
    "oai22_2x"		=> "${specpath}/oai22.spec",
    "oai22_4x"		=> "${specpath}/oai22.spec",

    "or2_2x"		=> "${specpath}/or2.spec",
    "or2_4x"		=> "${specpath}/or2.spec",
    "or2_6x"		=> "${specpath}/or2.spec",

    "or3_2x"		=> "${specpath}/or3.spec",
    "or3_4x"		=> "${specpath}/or3.spec",
    "or3_6x"		=> "${specpath}/or3.spec",

    "ph1latch_2x"	=> "${specpath}/ph1latch.spec",
    "ph1latch_4x"	=> "${specpath}/ph1latch.spec",
    "ph1latch_6x"	=> "${specpath}/ph1latch_6x.spec",

    "ph2slatch_2x"	=> "${specpath}/ph2slatch.spec",
    "ph2slatch_4x"	=> "${specpath}/ph2slatch.spec",
    "ph2slatch_6x"	=> "${specpath}/ph2slatch.spec",

    "xnor2_2x"		=> "${specpath}/xnor2.spec",
    "xnor2_4x"		=> "${specpath}/xnor2.spec",

    "xor2_2x"		=> "${specpath}/xor2.spec",
    "xor2_4x"		=> "${specpath}/xor2.spec",
    "xor2_6x"		=> "${specpath}/xor2.spec",
);

printf STDERR "Evaluating $specmap{$cellname} ...\n";
require "${specpath}/common.spec";
require $specmap{$cellname};

# output
&print_model('synopsys', $cellname . '.lib');
&write_db($cellname . '.db');

1;
