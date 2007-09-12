package TestClassAccessorMulti;
use strict;
use LEOCHARRE::Class::Accessors 
   multi => [ qw(users clothes) ], 
   single => [qw(host)];




1;

