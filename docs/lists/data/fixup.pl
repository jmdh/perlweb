#!/usr/bin/perl

use JSON;
use File::Slurp qw(slurp);
use strict;

# Helper script used to cleanup data
# can also use as a diff: diff -u lists.json <(./fixup.pl) 

my $data  = from_json(slurp("lists.json"));

for my $list (keys %{$data}) {
    if ($data->{$list}{archive} =~ / /) {
        my $oldarchive = $data->{$list}{archive};
        my @archives = split(" +(?=http://)",$oldarchive);
        $data->{$list}{archive} = [ @archives ];
    }

    if ($data->{$list}{nntp} && 
        !ref $data->{$list}{nntp} && $data->{$list}{nntp} !~ /^nntp:/) {
        my $nntp = $data->{$list}{nntp};
        my ($nntpgroup) = $nntp =~ m!group/(.+)$!;
        my $oldarchive = $data->{$list}{archive};
        $oldarchive = [$oldarchive] unless ref $oldarchive;
        $data->{$list}{archive} = [@$oldarchive,"http://www.nntp.perl.org/group/$nntpgroup"];
        $data->{$list}{nntp} = ["nntp://nntp.perl.org/$nntpgroup"];
    }

    my $rssfeed = $data->{$list}{rssfeed};
    if ($rssfeed =~ /nntp\.perl/ && !$data->{$list}{nntp}) {
        my ($nntpgroup) = $rssfeed =~ m!/rss/(.+).rdf$!;
        $data->{$list}{nntp} = ["nntp://nntp.perl.org/$nntpgroup"];
    }
}

# lowercase list names
for my $list (keys %{$data}) {
    if (lc $list ne $list) {
        $data->{lc $list} = $data->{$list};
        delete $data->{$list};
    }
    warn "$list has spaces in it\n" if $list =~ / /;
}

my $json = new JSON;
$json->canonical(1); # sort keys
print $json->pretty->encode($data);
