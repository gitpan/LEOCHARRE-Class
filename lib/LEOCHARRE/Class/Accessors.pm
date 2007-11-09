package LEOCHARRE::Class::Accessors;
use LEOCHARRE::Class::Accessors::Base;
use strict;
use warnings;
use Carp;
our $VERSION = sprintf "%d.%02d", q$Revision: 1.12 $ =~ /(\d+)/g;


$LEOCHARRE::Class::Accessors::DEBUG=0;
sub DEBUG : lvalue { $LEOCHARRE::Class::Accessors::DEBUG }


sub debug {
   DEBUG or return 1;
   my $msg= shift;
   $msg ||='';
   my @c = caller(1);
   my $s = $c[3];
   $s=~s/^.+:://;
   
   print STDERR " $s() $msg\n";
   return 1;
}

sub import {
   my $class = shift;
   my $caller = caller;
   my %method_type = @_;
   
   debug('started');

   unless( defined $method_type{constructor} ){
      $method_type{constructor} = 1; #'normal';
   }
   
   if ( $method_type{constructor} ){
      _make_new($caller);
   }   
   
   
   if ( exists $method_type{multi} ){
      debug('multi present');      
      _make_accessor_multi( $caller, @{$method_type{multi}} );      
   }
   

   if ( exists $method_type{single} ){
      debug('single present');      
      _make_accessor_single( $caller, @{$method_type{single}} );  
   }  

   if ( exists $method_type{dual} ){
      debug('dual present');      
      _make_accessor_dual( $caller, @{$method_type{dual}} );  
   }  
   
}




1;

=pod

=head1 NAME

LEOCHARRE::Class::Accessors - particular setget methods

=head1 SYNOPSIS

   package Super::Hero;
   use LEOCHARRE::Class::Accessors
      multi => [qw(powers)],
      single => [qw(name)],
      dual  => [qw(step)],

   1;

In script.pl:

   use Super::Hero;

   my $sm = new Super::Hero;


   # set methods   
   $sm->name_set('Superman');      
   $sm->powers_add('flying','x ray vision');
   
   # using the traditional dual setget method type:
   $sm->step or $sm->step = 1;


   # get methods
   
   my $powers = $sm->powers; 
   #or
   my $powers = $sm->powers_arrayref;
      
   my $name = $sm->name;
   #or
   my $name = $sm->name_get;


   # more
   my $count_of_powers = $sm->powers_count;
   
   $sm->powers_exists('flying');
   $sm->powers_delete('flying');

   # get hash of all instance data this is managing
   my $instance_data = $sm->_instancedata;

=head1 DESCRIPTION

These are my personal set get methods.
There are two types of acessors, multi, and single.
This is an interface to LEOCHARRE::Class::Accessors::Base

=head2 multi accesors

a multi accessor is a list of unique strings.
you can ask for a count of elements, add elements, delete them, test for the
existance of an element in the list as well.
the accessor names should be plural, as we want to deal with a list.

if the accessor's name is 'jobs'
you are provided with 

   jobs                     - get array ref, in the order they were added
   jobs_arrayref            - same as jobs
   __jobs_arrayref          - if you want to redefine jobs and or jobs_arrayref   
   
   jobs_arrayref_sorted     - just like jobs, but returns in alphanum order
   jobs_sorted              - same as jobs_arrayref_sorted
   
   jobs_hashref             - get hashref, mostly unused other then internally
   jobs_count               - returns number of elements
   
   jobs_add                 - add value, if you add the same twice, changes nothing
   __jobs_add               - if you want to redefine jobs_add
   
   jobs_delete              - take out value
   jobs_exists              - if value is present or not

   jobs_clear               - clear the values added

=head3 overriding

you may want to write our own add, this is how:

   sub jobs_add {
      my ($self,$val) = @_;
      $self->is_job($val) or return 0;
      $self->__jobs_add($val);
      return 1;
   }
   
We are not really overriding anything, we are really redefining, that is why you cannot
use SUPER. Beacause using LEOCHARRE::Class::Accessors creates methods 
in the namespace of the caller. 

=head2 single accessors

a single accessor is for one value within an object instance
instead of the common perl set and get
this is how I chose my method names.. if the accessor is named "age"
you are provided with 

   age         - get method   
   age_get     - get method  
   age_set     - set method
   __age_set   - if you want to redefine age_set
   age_clear   - undef the value

=head3 Example Overriding Single

You may want to override(really defefine) the set method.. but still want access to it.
Maybe you want to verify the data..

   no warnings 'redefine';
   sub age_set {
      my ($self,$val) = @_;     
      $self->_agevalok($val) or return 0;
      
      $self->__age_set($val);
      return 1;
   }

=head1 NO new() 

use LEOCHARRE::Class::Accessors single => [qw(abs_tmp api api_name)], constructor => 0;

Expecially useful for CGI::Application

=head1 SEE ALSO

LEOCHARRE::Class:Accessors::Base

=head1 DEBUG

   $LEOCHARRE::Class::Accessors::DEBUG = 1;


=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=cut
