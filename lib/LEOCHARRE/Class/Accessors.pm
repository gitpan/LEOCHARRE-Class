package LEOCHARRE::Class::Accessors;
use strict;
use warnings;


sub DEBUG { return 0; }
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
   
   _make_new($caller);
   _make_accessor_data($caller);

   debug('started');
   
   if ( exists $method_type{multi} ){
      debug('multi present');
      for(@{$method_type{multi}}){
         _make_accessor_multi($caller, $_ );
      }
   }

   if ( exists $method_type{single} ){
      debug('single present');
      for(@{$method_type{single}}){
         _make_accessor_single( $caller, $_);
      }
   }   
}

sub _make_new {
   my $class = shift;
   no strict 'refs';

   *{"$class\::new"} = sub { 
      my ($class,$self) = @_;
      $self||={};
      bless $self, $class;
      return $self;
   };
}



sub _make_accessor_single {
   my ($class, $name) = @_;

   no strict 'refs';
   debug("$class\::$name");
   
   *{"$class\::$name\_set"} = _make_accessor_single_set($name);
   *{"$class\::$name\_get"} = _make_accessor_single_get($name);
   *{"$class\::$name"} = _make_accessor_single_get($name); 
   return;
}




sub _make_accessor_multi {
   my ($class, $name) = @_;

   no strict 'refs';
      
   debug("$class\::$name");      
      
   *{"$class\::$name\_add"}       = _make_accessor_add($name); # i need a second one in caase iu want to override one
   *{"$class\::__$name\_add"}       = _make_accessor_add($name); # i need a second one in caase iu want to override one
   
   *{"$class\::$name\_count"}     = _make_accessor_count($name);
   *{"$class\::$name\_delete"}    = _make_accessor_delete($name);
   *{"$class\::$name\_hashref"}   = _make_accessor_hashref($name);
   *{"$class\::$name\_arrayref"}  = _make_accessor_arrayref($name);
   *{"$class\::$name\_clear"}     = _make_accessor_clear($name);

   # simple array ref is the basic name, for example 'users' and users_arrayref'
   # should do the same thing
   *{"$class\::$name"}            = _make_accessor_arrayref($name); 
   return;
}




sub _make_accessor_add {
   my $attribute = shift;
   
   return sub {
      my $self = shift;
      my $arg = shift;
      while( defined $arg ){
         $self->{_instancedata_}->{$attribute}->{$arg}++;
         $arg = shift;
      } 
      return 1;  
   };   
}

sub _make_accessor_hashref {
   my $attribute = shift;

   return sub {
      my $self=shift;
      $self->{_instancedata_}->{$attribute} ||= {};
      return $self->{_instancedata_}->{$attribute};
   };
}

sub _make_accessor_arrayref {
   my $attribute = shift;

   return sub {
      my $self = shift;
      $self->{_instancedata_}->{$attribute} ||={};
      my @a = sort keys %{ $self->{_instancedata_}->{$attribute} };
      return \@a;
   };
}


sub _make_accessor_delete {
   my $attribute = shift;
   
   return sub {
      my $self = shift;
      my $arg = shift;
      while( defined $arg ){
         if ( exists $self->{_instancedata_}->{$attribute}->{$arg} ){
            delete $self->{_instancedata_}->{$attribute}->{$arg};
         }
         $arg = shift;
      }   
      return 1;
   };
}

sub _make_accessor_clear {
   my $attribute = shift;

   return sub {
      my $self = shift;
      $self->{_instancedata_}->{$attribute} = {};
      return 1;
   };
}

sub _make_accessor_count {
   my $attribute = shift;
   
   return sub {
      my $self = shift;
      exists $self->{_instancedata_}->{$attribute} or return 0;
      keys %{$self->{_instancedata_}->{$attribute}} or return 0;
      my @k = keys %{$self->{_instancedata_}->{$attribute}};
      return scalar @k;
   };
}




sub _make_accessor_single_set {
   my $attribute = shift;

   return sub {
      my $self = shift;
      my $arg = shift;
      defined $arg or die('missing arg');
      $self->{_instancedata_}->{$attribute} =$arg;
      return 1;
   };
}

sub _make_accessor_single_get {
   my $attribute = shift;
   
   return sub {
      my ($self) = @_;
      defined $self->{_instancedata_}->{$attribute} or return;
      return $self->{_instancedata_}->{$attribute};
   };
}




sub _make_accessor_data {
   my $class = shift;
   no strict 'refs';
   
   *{"$class\::_instancedata"} = sub {
      my $self = shift;
      
      $self->{_instancedata_} ||={};
      return $self->{_instancedata_};   
   };

}



1;

=pod

=head1 SYNOPSIS

   package Super::Hero;
   use LEOCHARRE::Class::Accessors
      multi => [qw(powers)],
      single => [qw(name)];

   1;

In script.pl:

   use Super::Hero;

   my $sm = new Super::Hero;


   # set methods   
   $sm->name_set('Superman');      
   $sm->powers_add('flying','x ray vision');
   

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

=head1 DESCRIPTION

These are my personal set get methods.
There are two types of acessors.

=head2 multi accesors

a multi accessor is a list of unique strings.
you can ask for a count of elements, add elements, delete them, test for the
existance of an element as well.
the accessor names should be plural, as we want to deal with a list.

if the accessor's name is 'jobs'
you are provided with 

   jobs - get array ref
   jobs_arrayref - get array ref
   
   jobs_hashref - get hashref, mostly unused other then internally
   jobs_count - returns number of elements
   
   jobs_add - add value, if you add the same twice, changes nothing
   __jobs_add - add value, if you add the same twice, changes nothing
   
   jobs_delete - take out value
   jobs_exists - if value is present or not

=head3 overriding add

you may want to write our  own add, this is how:

   sub jobs_add {
      my ($self,$val) = @_;
      $self->is_job($val) or return 0;
      $self->__jobs_add($val);
      return 1;
   }

=head2 single accessors

a single accessor is for one value within an object instance
instead of the common perl set and get
this is how I chose my method names.. if the accessor is named "age"
you are provided with 

   age - get method
   age_get - get method
   age_set - set method

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=cut
