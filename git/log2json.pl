#!/usr/bin/perl 
use strict;


my $commit_list="[";
my @raw_commits=split(/COMMITLINEMARK/,$ARGV[0]);

sub clean_characters{
	my $commits = shift;
	$commits =~ s/\\//g;
	return $commits;
	
}

foreach my $raw_commit (@raw_commits){
	my $added;
	my $deleted;
	my $modified;
	my $other;
	
	if ($raw_commit =~ m/(\{[\S\s]+\})([\S\s]+)/){
		my $info_section = $1;
		my $file_section = $2;		
		while ($file_section =~ m/([ACDMRTUXB\*])\s+(\S+)/g){
			if ($1 eq "A"){
				$added = $added."\"".$2."\",";
			} elsif ( $1 eq "D"){
				$deleted = $deleted."\"".$2."\",";					
			} elsif ( $1 eq "M"){
				$modified = $modified."\"".$2."\",";
			} else {
				$other = $other."\"".$2."\",";
			}
		}
		chop $added;
		chop $deleted;
		chop $modified;
		chop $other;
		chop $info_section;
		$info_section= $info_section." , \"added\":[".$added."], \"modified\":[".$modified."], \"deleted\":[".$deleted."], \"other\":[".$other."]}";
		$commit_list=$commit_list.$info_section.",";
	}
}
chop $commit_list;
$commit_list = $commit_list."]";
print	clean_characters($commit_list);
