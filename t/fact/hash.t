# Copyright (c) 2008 by Ricardo Signes. All rights reserved.
# Licensed under terms of Perl itself (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License was distributed with this file or you may obtain a 
# copy of the License from http://dev.perl.org/licenses/

use strict;
use warnings;

use Test::More;
use Test::Exception;
use JSON;

use lib 't/lib';

plan tests => 19;

require_ok( 'FactSubclasses.pm' );

#--------------------------------------------------------------------------#
# fixtures
#--------------------------------------------------------------------------#    

my ($obj, $err);

my $struct = {
  first => 'alpha',
  second => 'beta',
};

my $meta = {
  size => [ '//num' => 2 ],
};

my $args = {
  resource => "cpan:///distfile/JOHNDOE/Foo-Bar-1.23.tar.gz",
  content  => $struct,
};

my $test_args = {
  resource => $args->{resource},
  content => { },
};

throws_ok { $obj = FactFour->new( $test_args ) } qr/missing required keys.+?first/, 
  'missing required dies';

$test_args->{content}{first} = 1;

lives_ok{ $obj = FactFour->new( $test_args ) } 
    "new( <hashref> ) doesn't die";

$test_args->{content}{third} = 3;

throws_ok { $obj = FactFour->new( $test_args ) } qr/invalid keys.+?third/, 
  'invalid key dies';

isa_ok( $obj, 'Metabase::Fact::Hash' ); 

lives_ok{ $obj = FactFour->new( %$args ) } 
    "new( <list> ) doesn't die";

isa_ok( $obj, 'Metabase::Fact::Hash' );
is( $obj->type, "FactFour", "object type is correct" );
is( $obj->{metadata}{core}{type}, "FactFour", "object type is set internally" );

is( $obj->resource, $args->{resource}, "object refers to distribution" );
is_deeply( $obj->content_metadata, $meta, "object content_metadata() correct" );
is_deeply( $obj->content, $struct, "object content correct" );

my $want_struct = {
  content  => to_json($struct),
  metadata => {
    core    => {
      type           => 'FactFour'       ,
      schema_version => 1                ,
      guid           => $obj->guid       ,
      resource       => $args->{resource},
      valid          => 1                ,
    },
  }
};

my $have_struct = $obj->as_struct;
is( $have_struct->{metadata}{core}{updated_at},
    $have_struct->{metadata}{core}{created_at},
    "created_as equals updated_as"
);

my $created_at = delete $have_struct->{metadata}{core}{created_at};
like( $created_at, qr/\A\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\dZ\z/,
  'created_at is ISO 8601 Zulu',
);
delete $have_struct->{metadata}{core}{updated_at}; 

is_deeply($have_struct, $want_struct, "object as_struct correct"); 

my $creator_uri = 'metabase:user:351e99ea-1d21-11de-ab9c-3268421c7a0a';
$obj->set_creator($creator_uri);
$want_struct->{metadata}{core}{creator} = $creator_uri;

is_deeply($have_struct, $want_struct, "object as_struct correct w/creator"); 

$obj->set_valid(0);
$want_struct->{metadata}{core}{valid} = 0;
is_deeply($have_struct, $want_struct, "set_valid(0)"); 

$obj->set_valid(2);
$want_struct->{metadata}{core}{valid} = 1;
is_deeply($have_struct, $want_struct, "set_valid(2) normalized to '1'"); 

#--------------------------------------------------------------------------#

$obj = FactFour->new( %$args );
my $obj2 = FactFour->from_struct( $obj->as_struct );
is_deeply( $obj2, $obj, "roundtrip as->from struct" );

