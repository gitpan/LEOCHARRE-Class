package LEOCHARRE::Class;
use Carp;
use strict;
use warnings;
use vars qw(@ISA @EXPORT $VERSION);
@ISA = qw/ Exporter /;
@EXPORT = qw(
__init_from_hashref
__init_argument_to_constructor
);

$VERSION = sprintf "%d.%02d", q$Revision: 1.5 $ =~ /(\d+)/g;

# if a custom argument is provided, use that, or use default
sub __init_argument_to_constructor {
   my($self,$key,$default_value) = @_;   

   my $set_method = "$key\_set";
   
   if( defined $self->{$key}){
      $self->$set_method( $self->{$key} ); # arg to constructor
      return 1;
   }
   elsif ( defined $default_value ){
      $self->$set_method( $default_value );      
      return 1;
   }

   return 0;
}




# this one has no defaults.. 
sub __init_from_hashref {
   my $self = shift;
   my $arg = shift;   
   defined $arg or confess('missing arg');
   (ref $arg) and (ref $arg eq 'HASH') or confess('arg must be hash ref, it is: ['.ref($arg).']');
   
   my $is_required={};

   $is_required->{$_}++ for @_;


   
   if ( scalar (keys %$is_required) ){
      for(keys %$is_required){
         my $name = $_;
         defined $arg->{$name}
            or confess("Missing [$name] arg");          
      }
   }
   elsif ( ! scalar (keys %$arg) ){ # nothing in args? then just return
      return 1;
   }
   
   my ($_set_ok, $_set_fail) = (0,0);


   # SINGLES
   
   my $accessors_single = $self->class_accessors_single;
   SARG: for (@$accessors_single){
      my $name = $_;      
      my ($set,$get,$clear) = ("$name\_set","$name\_get","$name\_clear");

      

      my $val = $arg->{$name};
      
      # if value is not required and not present.. skip
      unless ( $is_required->{$name} ){         
         defined $val or next SARG;
         $self->$set($val) 
            ? $_set_ok++ 
            : ( warn("cant set [$name=$val]") and ++$_set_fail);
            
         next SARG; # regardless.
      }


      # otherwise... this is required, and a failed set is an exception
      defined $val or confess("missing required arg [$name]");
      $self->$set($val)
         ? ++$_set_ok
         : confess("cant set [$name=$val]");
         
      next SARG;
   }


   # MULTIS

   my $accessors_multi = $self->class_accessors_multi;
   MARG: for (@$accessors_multi){
      my $name = $_;      
      my ($set,$get,$clear) = ("$name\_add","$name\_arrayref","$name\_clear");
      
      # if value is in hashref.. try to set      
      # it MUST be an array ref!!!!!
      my $val = $arg->{$name};

      # simple if def.. must be arrayref, valid for both required or not

      if (defined $val){      
         (ref $val) and (ref $val eq 'ARRAY') or confess("argument [$name] must be array ref");
      }     
      
      
      # if not demanded..
      unless( $is_required->{$name} ){ # if not required.. then go easy
         
         defined $val or next MARG;
         
         for(@$val){
            $self->$set($_) 
               ? ++$_set_ok
               : ( warn("arg [$name] could not $set [$_]") and ++$_set_fail);
         }
      }




      # now we know it's req
      # we also know if it's defined.. it is an array ref
      defined $val or confess("required arg [$name] missing");
      
      for(@$val){ # if any fail, we freak out
         $self->$set($_)
            ? ++$_set_ok
            : confess("arg [$name] could not $set [$_]");
      }

      next MARG;      
   }

   # if there are any fails .. return undef
   if ($_set_fail){
      return;
   }

   # if anything was set at all.. return 1
   if ($_set_ok){
      return 1;
   }

   # otherwise return 0
   return 0;

}






1;

__END__
=pod

=head1 NAME

LEOCHARRE::Class - my class bases

=head1 METHODS


=head2 __init_from_hashref()

argument is a hash ref.
optional argument is a list of param names that MUST be present and must be set succesfully
if no args are present and none required, returns false
if args are required and not present or not set succesfully, confesses, throws exceptions
if args are present and all set works, returns true
if any set at all fails, returns undef after going through all 

we look up inside class_accessors_single, if any are present in the arg.. we set 


Example:

   package Circus; 
   use LEOCHARRE::Class;
   
   use LEOCHARRE::Class::Accessors 
      single => ['name', 'genre'],
      multi  => ['animals', 'employees'];   
  
   

   sub new {
      my($class,$arg) = @_;
      $arg ||= {};
      my $self = {};      
      bless $self, $class;
      
      $self->__init_from_hashref($arg);

      return $self;      
   }

   1;


   package main;
   use Circus;

   my $c = new Circus({
      name => 'Circo Poltergeist',
      animals => [qw(elephants tigers turtles cows chickens)],
   });
   

This will have the same effect as:

   package main;
   use Circus;

   my $c = new Circus;
   
   $c->animals_add(qw(elephants tigers turtles cows chickens));
   
   $c->name_set('Circo Poltergeist');

The cool thing you can do though... This is just one creative example

   sub load_from_yaml {
      my ($self,$abs) = @_;
      require YAML;

      my $arg = YAML::LoadFile($abs);

      $self->__init_from_hashref($arg) or die("some args were not good");
   
      my $self = shift;
   }

If you want to throw an exception with explanation if the constructor is missing
an argument.. Imagine your object MUST have 'abs_path' as argument to constructor..

   sub new {
      my($class,$arg) = @_;
      $arg ||= {};
      my $self = {};      
      bless $self, $class;
      
      $self->__init_from_hashref($arg, 'abs_path');

      return $self;      
   }
  


Init from hashref returns undef if any of the set methods fail.
It returns 0 if there was nothing that we tried to set in the arguments.
Otherwise returns true.




=head1 SEE ALSO

L<LEOCHARRE::Class::Accessors>
L<LEOCHARRE::Class::Accessors::Base>

=head1 AUTHOR

Leo Charre leocharre at cpan dot org


=cut

