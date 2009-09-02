#!/usr/bin/perl

use strict;
use warnings;

use lib qw( ../lib ../extlib lib extlib t/lib t/extlib);

use MT::Test;
use Test::More qw( no_plan );
use Encode;

require_ok('MT::Util::YAML');

my @classes = qw( MT::Util::YAML::Tiny MT::Util::YAML::Syck );
for my $class ( @classes ) {
    MT::Util::YAML::_find_module($class);
    my $data;
    ok(($data) = MT::Util::YAML::LoadFile('t/71-yaml.yaml'), "$class: Loadfile");
    ok( 'HASH' eq ref $data, "$class: returns HASHREF");
    ok( defined $data->{TITANS}, "$class: exists key 'TITANS'" ) and
    is( scalar @{ $data->{TITANS} }, 2, "$class: number of array" );
    is($data->{AEUG}{"Hyaku Shiki"}, "Quattro Bajeena", "$class: get hash value" );
    ok(Encode::is_utf8($data->{AEUG}{Methuss}), "$class: wide character is utf8");
    my $str;
    ok( $str = MT::Util::YAML::Dump( $data ), "$class: Dump" );
    ok( Encode::is_utf8($str), "$class: Output of Dump is utf-8");
}

