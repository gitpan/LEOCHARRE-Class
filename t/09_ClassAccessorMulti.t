use Test::Simple 'no_plan';
use lib './t';
use lib './lib';
use strict;
use Data::Dumper 'Dumper';
use TestClassAccessorMulti;
my $DEBUG = 1;

my $o = new TestClassAccessorMulti;

ok( ref $o,'object instantiated');

ok( $o->correct_new, 'correct new');


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

$o->host_clear;
my $hnow = $o->host;
ok( ! defined $hnow);

$o->host_set('localhost');


my $data = $o->_instancedata;
print STDERR " get object instance data: ".Dumper($data) ."\n\n";





my $unam = 'errol_morris';

ok( $o->users_add($unam), "added $unam");

my $users_ = $o->users;

ok( _array_contains( $users_,$unam), "array contains $unam");

ok( $o->users_delete($unam), "deleted $unam");
$users_ = $o->users;

ok( ! _array_contains( $users_,$unam), "array does not contain $unam anymore");


$o->users_clear;

my $_cb = $o->users_count;

$o->users_add('barbie','aussie','cobra','zelma');

ok( ($_cb +4 )== $o->users_count );

ok( $o->users_count == 4);

$o->users_delete('barbie','cobra');
ok( $o->users_count == 2);

$o->users_clear;
ok( ! $o->users_count );



$o->users_add(qw(x y z a b c));

my @ordered = @{$o->users};
ok( "@ordered" eq 'x y z a b c', "ordered [@ordered]");

my @sorted  = @{$o->users_sorted};
ok( "@sorted"  eq 'a b c x y z', "sorted  [@sorted]");

# ok.. now if we move things around a little.. should still work...

$o->users_delete(qw(c x z));

my @ordered2 = @{$o->users};
ok( "@ordered2" eq 'y a b', "ordered [@ordered2]");

my @sorted2  = @{$o->users_sorted};
ok( "@sorted2"  eq 'a b y', "sorted  [@sorted2]");



# try numbers
$o->users_clear;
$o->users_add(qw(2 3 4 9 8 7 6 5 1 0));

ok($o->users_count == 10,'10 count, trying numbers..');

ok( $o->users_exists(0),' does user "0" exist.. should.. ');
ok( $o->users_delete(0),' user 0 deleted');
ok( ! $o->users_exists(0),' does user "0" now does not exist ');



# what if i make funny callse
ok( ( eval { $o->users_delete(7) } ) , 'calling users_delete with arg');
ok( ( eval { $o->users_add(7)    } ) , 'calling users_add with arg');
ok( ( eval { $o->users_exists(7) } ) , 'calling users_exists with arg');

ok( !( eval { $o->users_delete   } ) , 'calling users_delete with no arg fails');
ok( !( eval { $o->users_exists   } ) , 'calling users_exists with no arg fails');
ok( !( eval { $o->users_add      } ) , 'calling users_add with no arg fails');

sub _array_contains {
   my($arrayref,$element) = @_;
   defined $arrayref and defined $element or die;
   ref $arrayref eq 'ARRAY' or die('not array arg');
   
   for (@$arrayref){
      print STDERR "$_ ?= $element\n" if $DEBUG;
      if ($_ eq $element){
         return 1;
      }
   }
   return 0;
}
