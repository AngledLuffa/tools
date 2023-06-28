#!/usr/bin/env perl
# Reads all UD treebanks in the UD folder, counts regular nodes (i.e. syntactic
# words/tokens) in all of them. Skips treebanks that do not contain the under-
# lying texts. Prints the counts grouped by language family.
# Copyright © 2023 Dan Zeman <zeman@ufal.mff.cuni.cz>
# License: GNU GPL

use utf8;
use open ':utf8';
binmode(STDIN, ':utf8');
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');
use Getopt::Long;
use udlib;

sub usage
{
    print STDERR ("Usage: $0 --udpath /data/udreleases/2.12\n");
}

#my $udpath = 'C:/Users/Dan/Documents/Lingvistika/Projekty/universal-dependencies';
my $udpath = '/net/data/universal-dependencies-2.12';
GetOptions
(
    'udpath=s' => \$udpath
);

my $languages = udlib::get_language_hash("$udpath/docs-automation/codes_and_flags.yaml");
my @folders = udlib::list_ud_folders($udpath);
my %family_words;
my $nwords = 0;
foreach my $folder (@folders)
{
    my ($language, $treebank) = udlib::decompose_repo_name($folder);
    if(!exists($languages->{$language}))
    {
        print STDERR ("Skipping $folder because language $language is unknown.\n");
        next;
    }
    my $metadata = udlib::read_readme($folder, $udpath);
    if($metadata->{'Includes text'} !~ m/^y/i)
    {
        print STDERR ("Skipping $folder because it lacks underlying text.\n");
        next;
    }
    print STDERR ("Reading $folder...\n");
    my $ltcode = udlib::get_ltcode_from_repo_name($folder, $languages);
    my $stats = udlib::collect_statistics_about_ud_treebank("$udpath/$folder", $ltcode);
    my $family = $languages->{$language}{family};
    $family =~ s/,.*//;
    $family = 'Indo-European' if($family eq 'IE');
    $family_words{$family} += $stats->{nword};
    $nwords += $stats->{nword};
}
# Print the statistics.
my @families = sort {$family_words{$b} <=> $family_words{$a}} (keys(%family_words));
foreach my $family (@families)
{
    printf("%s\t%d\t%d %%\n", $family, $family_words{$family}, $family_words{$family}/$nwords*100+0.5);
}
