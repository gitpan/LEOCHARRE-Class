package TestClassAccessorMulti;
use strict;
use warnings;
use LEOCHARRE::Class::Accessors 
   multi => [ qw(users clothes) ], 
   single => [qw(host correct_new)];


sub new {
   my ($class, $self) = @_;
   $self||={};
   bless $self,$class;
   $self->correct_new_set(1);
   return $self;
}



1;

