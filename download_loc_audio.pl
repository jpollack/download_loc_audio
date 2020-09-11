#!/usr/bin/perl

use strict;
use warnings;
use LWP::Curl;
use HTML::TreeBuilder::XPath;
use JSON;

sub curlget
{
    my $curl = LWP::Curl->new();
    my $url = shift;
    return $curl->get ($url);
}

sub spit
{
    my $fname = shift;
    my $data = shift;
    open (my $fh, ">", $fname);
    print $fh $data;
    close ($fh);
}

sub slurp
{
    my $fname = shift;
    open (my $fh, "<", $fname);
    my $str;

{
    local $/;
    $str = <$fh>;
}

    close ($fh);
    return $str;
}

sub dlresults {
    my $reso = shift;
    my $jcoder = JSON->new->utf8->canonical;
    my $numres = $#{$reso};

    print STDERR "Saving metadata...";
    for my $ri (0..$numres)
    {
	my $ro = $reso->[$ri];
	my $name = (split (/\//, $ro->{id}))[-1];
	mkdir ("${name}");
	spit ("${name}/metadata.json", $jcoder->encode($ro));
    }
    print STDERR "Done (" . ($numres + 1) . " entries)\n";

    for my $ri (0..$numres)
    {
	my $ro = $reso->[$ri];
	my $name = (split (/\//, $ro->{id}))[-1];

	print STDERR "${name}\t\t[$ri / $numres]...";

	unless ((-e "${name}/audio.wav")
		    and (-e "${name}/transcript.xml"))
	{

	    my $html = HTML::TreeBuilder::XPath->new (ignore_unknown => 0);
	    $html->parse_content (curlget($ro->{id}))
		or die "Error Parsing HTML: $!";

	    my $wavurl = (grep { $_ =~ m{\.wav$} } map { $_->attr('content') } @{$html->findnodes('//meta[@property="og:audio"]')})[0];
	    my $transurl = (map { $_->attr('href') } @{$html->findnodes('//link[@type="application/xml"]')})[0];

	    spit ("${name}/audio.wav", curlget ($wavurl));
	    spit ("${name}/transcript.xml", curlget ($transurl));
	}

	print STDERR "Done!\n";
    }
}

sub main {

    my $ddir = shift;
    my $url = shift;

    mkdir ($ddir);

    unless (-e "${ddir}/all_results.json")
    {
	spit ("${ddir}/all_results.json", curlget($url));
    }

    my $jcoder = JSON->new->utf8->canonical;
    my $obj = $jcoder->decode(slurp ("${ddir}/all_results.json"));

    chdir ($ddir);
    dlresults ($obj->{results});
}

if ($#ARGV < 0)
{
    die "Usage: $0 URL [output_directory]\n";
}

my $url = shift;
my $outdir = shift;

unless ($url =~ m{fo=json})
{
    die "URL must contain 'fo=json'\n";
}

unless (length ($outdir)) {
    $outdir = "data";
}

main ($outdir, $url); # 'https://www.loc.gov/audio/?c=150&fa=subject:slave+narratives&fo=json'
