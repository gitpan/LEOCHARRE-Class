use Test::Simple 'no_plan';
use lib './t';
use lib './lib';
use strict;
use Data::Dumper 'Dumper';

use TestClassAccessorMulti;

my $o = new TestClassAccessorMulti;

ok( ref $o,'object instantiated');

ok( $o->users_add('mike','jimmy','babe'), 'added 3 users');
ok( $o->clothes_add('red bikini','blue hat'), 'added 2 clothes');

my $c = $o->users_count;
my $cc = $o->clothes_count;

ok( $c == 3, 'users count now 3');
ok($cc == 2, 'clothes count now 2');

ok($o->users_delete('babe'));
ok($o->users_count == 2 );

my $a = $o->users_hashref;
ok( ref $a eq 'HASH', 'users_hashref returns hash ref') or die;

my $ar = $o->users_arrayref;
ok( ref $ar eq 'ARRAY', 'users_arrayref returns array ref') or die;

my $ucn = $o->users_count;
ok( $ucn=~/^\d+$/, 'users_count returns digit(s)') or die;

print STDERR " hashref method: ".Dumper($a) ."\n\n";


ok( $o->host_set('localhost') );
ok( $o->host eq 'localhost'  );
ok( $o->host_get eq 'localhost' );

my $data = $o->_instancedata;
print STDERR " get object instance data: ".Dumper($data) ."\n\n";


