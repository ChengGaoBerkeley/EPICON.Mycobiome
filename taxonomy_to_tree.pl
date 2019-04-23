#! /usr/bin/perl -w

#########################################################################
#                                                                       #
# taxonomy_to_tree.pl is a perl scrip that makes a tree from a taxonomy.#
# give the -h or --help switch to the program for further instructions. #
#                                                                       #
# Copyright (C) 2017  Martin Ryberg <martin.ryberg@ebc.uu.se>           #
#                                                                       #
# This program is free software: you can redistribute it and/or modify  #
# it under the terms of the GNU General Public License as published by  #
# the Free Software Foundation, either version 3 of the License, or     #
# (at your option) any later version.                                   #
#                                                                       #
# This program is distributed in the hope that it will be useful,       #
# but WITHOUT ANY WARRANTY; without even the implied warranty of        #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         # 
# GNU General Public License for more details.                          #
#                                                                       #
# You should have received a copy of the GNU General Public License     #
# along with this program. If not, see <http://www.gnu.org/licenses/>.  #
#                                                                       #
#########################################################################

use strict;

my $sep="\t";
my $filename;
my $INPUT = *STDIN;
my $branch_length = 60;
my $mearge_taxon_on_single_branch = 'n';

sub help {
    print "This script will make a phylogeny of a hirarchial taxonomy. Each terminal taxon\n";
    print "should be given on a row with the taxa it is nested in to its left. The\n";
    print "hirarchy for each taxon is assumed to be complete (i.e. the same taxon name\n";
    print "given in different position/column are considered to be different). Rows\n";
    print "starting with # will be ignored. Usage:\n\n";
    print "perl taxonomy_to_tree.pl [options] taxonomy_file.txt\n\n";
    print "Options:\n";
    print "-b/--branch_length [number/ will give the length of each branch in the tree\n";
    print "            no/file name/=] (default: 60). If no branch lengths are wanted give\n";
    print "                            'no'. Alternatively, give a file with the taxon name\n";
    print "                            in the first column and the branch length in the\n";
    print "                            second column. It is also possible to give a default\n";
    print "                            branch length by giving default in the first column\n";
    print "                            and the default branch length in the second. The\n";
    print "                            column separator should be the same as for the\n";
    print "                            taxonomy. If the file is set to the same name as the\n";
    print "                            taxonomy file (set by  -f or as last argument), or =\n";
    print "                            is given, branch length will be expected to be in\n";
    print "                            the column following the taxon in the taxon file,\n";
    print "                            e.g. Basidiomycota,1,Agaricomycetes,2,Agaricus,2,\n";
    print "                            Agaricus bisporus,1\n";
    print "-f/--file [file name]       will give the name of the input file (default:\n";
    print "                            STDIN)\n";
    print "-h/--help                   will print this help\n";
    print "-m/--mearge_monotypic       will give one branch instead of a series of branches\n";
    print "                            when taxa are monotypic\n";
    print "-s/--separator [string]     will give the separator between the ranks in the\n";
    print "                            hirarchy (default: tab [\\t])\n";
    exit;
}

# Go through arguments to pars switches, files, etc
for (my $i=0; $i < scalar @ARGV; ++ $i) {
    if ($ARGV[$i] eq '-s'|| $ARGV[$i] eq '--separator') {
	if ($i+1 < scalar @ARGV && defined($ARGV[$i+1])) {
	    $sep=$ARGV[++$i];
	}
	else { die "--separator/-s need a separator as next argument.\n"; }
    }
    elsif ($ARGV[$i] eq '-b' || $ARGV[$i] eq '--branch_length') {
	if ($i+1 < scalar @ARGV && !(!$filename && $i+2 == scalar @ARGV) && $ARGV[$i+1]=~ /^[^-]/) {
	    $branch_length = $ARGV[++$i];
	}
	#else { $branch_length = 60; }
	#else { die "--branch_length/-b need a number as next argument.\n"; }
    }
    elsif ($ARGV[$i] eq '-f' || $ARGV[$i] eq '--file') {
	if ($i+1 < scalar @ARGV && $ARGV[$i+1]=~ /^[^-]/) {
	    $filename = $ARGV[++$i];
	}
	else { die "--file/-f need a file name as next argument.\n"; }
    }
    elsif ($ARGV[$i] eq '-m'|| $ARGV[$i] eq '--mearge_monotypic') {
	$mearge_taxon_on_single_branch = 'y';
    }
    elsif ( $ARGV[$i] eq '-h' || $ARGV[$i] eq '--help') {
	&help();
    }
    elsif ( $i+1 == scalar @ARGV ) {
	$filename = $ARGV[$i];
    }
    else { die "Do not recognize argument $ARGV[$i].\n"; }
}
# Take care of special cases of branch lengths
if (defined($branch_length) && $branch_length =~ /^no$/i) { undef $branch_length; }
if (defined($branch_length) && $filename && $branch_length eq $filename) { $branch_length = '='; }

# If filename given open file (otherwise expect input from STDIN)
if ($filename) {
    open $INPUT, '<', $filename or die "Could not open $filename: $!.\n";
}
else {
    print STDERR "Expecting taxonomy through standard in.\n";
}

my %tree; # Save taxonomy as a tree based on a hash structure
my %taxon_branches; # Save branch lengths for the taxa

# Pars file
while (my $row = <$INPUT>) {
    chomp $row;
    if ($row =~ /^#/) { next; }
    my @columns = split /$sep/, $row;
    my $hash_ref = \%tree;
    for (my $i=0; $i < scalar @columns; ++$i) {
	$columns[$i] =~ s/^\s+//;
	$columns[$i] =~ s/\s+$//;
	if ($hash_ref->{$columns[$i]}) {
	    $hash_ref = \%{$hash_ref->{$columns[$i]}};
	}
	else { 
	    $hash_ref->{$columns[$i]} = {};
	    $hash_ref = \%{$hash_ref->{$columns[$i]}};
	}
	if (defined($branch_length) && $branch_length eq '=') { # If parsing branch lengths from same file
	    if (defined($columns[$i+1])) {
		if ($columns[$i+1] =~ /\D/) { print STDERR "WARNING!!! Branch length $columns[$i+1] for $columns[$i] contains non numeric value.\n"; }
		$taxon_branches{$columns[$i]} = $columns[$i+1];
	    }
	    ++$i;
	}
    }
}

# If branch lengths and branch lengths not number or parsed in taxonomy file
# treat it as a file and pars it, otherwise if defined and not parsed in
# taxonomy file treat it as a number
if (defined($branch_length) && $branch_length =~ /\D/ && $branch_length ne '=') {
    print STDERR "Will read taxon branch lengths from file $branch_length.\n";
    open LENGTHS, '<', $branch_length || die "Could not open $branch_length: $!.\n";
    while (my $row = <LENGTHS>) {
	if ($row =~ /^#/) { next; } # If starting with a hash treat it as a comment
	my @temp = split /$sep/, $row;
	$temp[0] =~ s/^\s+//;
	$temp[0] =~ s/\s+$//;
	if ($temp[0] =~ /default/i) { $temp[0] = lc $temp[0]; }
	if ($temp[0]) { $taxon_branches{$temp[0]} = $temp[1]; }
    }
}
elsif (defined($branch_length) && $branch_length ne '=') { $taxon_branches{'default'} = $branch_length; }

# If branch lengths and no default given, set default to 0
if (defined($branch_length) && !defined($taxon_branches{'default'})) { $taxon_branches{'default'} = 0; }

# $branch_length = \%taxon_branches;

# print tree
# print "N branches from root: ", scalar keys %tree, ".\n";
&print_hash_as_tree(\%tree, '', \%taxon_branches, 0, $mearge_taxon_on_single_branch);
print ";\n";
sub print_hash_as_tree {
    my $ref = shift; # reference to tree based on hash references
    my $taxon = shift; # the taxon being treated
    my $branch_length = shift; # hash ref to branch lengths for the different taxa
    my $extra_branch_length = shift; # branch length not yet printed due to monotypic taxa
    my $mearge_branches = shift; # Should monotypic taxa be kept on one branch?
    #print "$taxon\n";
    # For each descendant taxon
    my @keys = keys %{$ref};
    if (scalar @keys) { # If any descendants
	my $add_branch_length=0;
	if ($mearge_branches eq 'n' || scalar @keys > 1) { print '('; } # Unless monotypic and should be merged
	elsif (scalar keys %$branch_length > 0) { # Otherwise prepare to send branch length (if any) to descendant taxa
	    my $name = $taxon;
	    if (!defined($branch_length->{$taxon})) { $name = 'default'; }
	    if (defined($branch_length->{$name}) && !($branch_length->{$name} =~ /\D/)) {
		$add_branch_length = $extra_branch_length + $branch_length->{$name};
	    }
	}
	for (my $i=0; $i < scalar @keys; ++$i) { # Treat descendants
	    if ($i) { print ','; }
	    &print_hash_as_tree(\%{$ref->{$keys[$i]}},$keys[$i],$branch_length,$add_branch_length,$mearge_branches);
	}
	if ($mearge_branches eq 'n' || scalar @keys > 1) { # Unless monotypic and should be merged
	    print ")$taxon";
	    if (defined($branch_length) && (scalar keys %$branch_length > 0)) { # If branch lengths
		if (!defined($branch_length->{$taxon})) { $taxon = 'default'; } # If default should be used
		if ($branch_length->{$taxon} =~ /\D/) { print ':', $branch_length->{$taxon}; } # If branch lengths not numeric
		else { print ':', $branch_length->{$taxon}+$extra_branch_length; }
	    }
	}
    }
    else { # If tip
	print $taxon;
	if (defined($branch_length) && (scalar keys %$branch_length > 0)) { # If branch lengths
	    if (!defined($branch_length->{$taxon})) { $taxon = 'default'; } # If default should be used
	    if ($branch_length->{$taxon} =~ /\D/) { print ':', $branch_length->{$taxon}; } # If branch lengths not numeric
	    else { print ':', $branch_length->{$taxon}+$extra_branch_length; }
     	}
    }
}