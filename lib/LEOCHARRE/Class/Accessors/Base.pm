package LEOCHARRE::Class::Accessors::Base;
use strict;
use Carp;
use warnings;
use LEOCHARRE::DEBUG;
use vars qw(@ISA @EXPORT $VERSION);
use Exporter;
@ISA = qw/ Exporter /;
@EXPORT = qw(
_make_accessor_single
_make_accessor_multi
_make_accessor_dual
_make_new
);
$VERSION = sprintf "%d.%02d", q$Revision: 1.3 $ =~ /(\d+)/g;

#$LEOCHARRE::Class::Accessors::Base::DEBUG=0;

#no warnings 'redefine';

#sub DEBUG : lvalue { $LEOCHARRE::Class::Accessors::Base::DEBUG }

sub _make_new {
   my $class = shift;

   # unless it is already defined!!!!
   no strict 'refs';

   # this wont work unless another new is defined beforehand, not in the calling code
   
   #but it should keep from redefining another predefined new

   if ( defined &{"$class\::new"} ){
      print STDERR" new defined already\n" if DEBUG;
      return;
   }
   #return if defined *{"$class\::new"}; # TODO is this ok??   

   *{"$class\::new"} = sub { 
      my ($class,$self) = @_;
      $self||={};
      bless $self, $class;
      return $self;
   };
   return;
}

# classic perl two way accessor, set and get
sub _make_accessor_dual {
   my $class = shift;
   my @names = @_;

   _make_accessor_data($class); # wont make two times

   for my $name (@names){
      no strict 'refs';

      print STDERR "$class\::$name\n" if DEBUG;
      
      *{"$class\::$name"}        = _make_accessor_setget($name);
      *{"$class\::$name\_set"}   = _make_accessor_single_set($name);
      *{"$class\::$name\_validate"}= _make_accessor_validate(); #meant to be redefined
      
      *{"$class\::$name\_get"}   = _make_accessor_single_get($name);
      *{"$class\::$name\_clear"} = _make_accessor_single_clear($name); 
      

      # i guess it SHOULD be in single, because what it does is the same... ?
      push @{"$class\::__accessors_single"}, $name;
      push @{"$class\::__accessors"}, $name, "$name\_set", "__$name\_set", "$name\_get", "$name\_clear", "$name\_validate";   
   }
   return;
}

sub _make_accessor_single {
   my $class = shift;
   my @names = @_;  

   _make_accessor_data($class); # wont make twice

   #my $caller = caller;
   #my $caller2 = caller(1);
   #print STDERR " caller1 [$caller] caller2 [$caller2]\n";
   
   for (@names){
      my $name = $_;
      no strict 'refs';

      print STDERR "$class\::$name\n" if DEBUG;      
      
      *{"$class\::$name\_set"}   = _make_accessor_single_set($name);
      *{"$class\::__$name\_set"} = _make_accessor_single_set($name);   
      *{"$class\::$name\_validate"} = _make_accessor_validate($name); 
      
      *{"$class\::$name\_get"}   = _make_accessor_single_get($name);
      *{"$class\::$name"}        = _make_accessor_single_get($name);    
      
      *{"$class\::$name\_clear"} = _make_accessor_single_clear($name); 
      
   
      push @{"$class\::__accessors_single"}, $name; # for later reference
      push @{"$class\::__accessors"}, $name, "$name\_set", "__$name\_set", "$name\_get", "$name\_clear";
      
   }
   
   return;
}




sub _make_accessor_multi {
   my $class = shift;
   my @names = @_;
   
   _make_accessor_data($class); # wont make twice
   
   for (@names){
      my $name = $_;  

      no strict 'refs';      
      print STDERR "$class\::$name" if DEBUG;      
      
      
      *{"$class\::$name"}                    = _make_accessor_arrayref($name); 
      *{"$class\::$name\_arrayref"}          = _make_accessor_arrayref($name);
      
      *{"$class\::$name\_arrayref_sorted"}   = _make_accessor_arrayref_sorted($name);
      *{"$class\::$name\_sorted"}            = _make_accessor_arrayref_sorted($name);
      
      *{"$class\::$name\_add"}               = _make_accessor_add($name); # i need a second one in caase iu want to override one
      *{"$class\::__$name\_add"}             = _make_accessor_add($name); # i need a second one in caase iu want to override one      
      *{"$class\::$name\_validate"}          = _make_accessor_validate($name); 
   
      *{"$class\::$name\_count"}             = _make_accessor_count($name);
      
      *{"$class\::$name\_delete"}            = _make_accessor_delete($name);
      
      *{"$class\::$name\_hashref"}           = _make_accessor_hashref($name);
   
      *{"$class\::$name\_clear"}             = _make_accessor_clear($name);
      
      *{"$class\::$name\_exists"}            = _make_accessor_exists($name);

   
      # simple array ref is the basic name, for example 'users' and users_arrayref'
      # should do the same thing      
      
      push @{"$class\::__accessors_multi"}, $name; # for later reference
      push @{"$class\::__accessors"}, $name, "$name\_arrayref", "$name\_arrayref_sorted", "$name\_add", 
         "__$name\_add", "$name\_count", "$name\_delete", "$name\_hashref", "$name\_clear", "$name\_exists";

   }


   
   return;
}





sub _make_accessor_hashref {
   my $attribute = shift;

   return sub {
      my $self = shift;
      $self->_instancedata->{$attribute} ||= {};
      return $self->_instancedata->{$attribute};
   };
}




sub _make_accessor_add {
   my $attribute = shift;
   
   my $method_validate = "$attribute\_validate"; # check if val is ok
   
   return sub {
      my $self = shift;      
      my @args = @_;
      scalar @args or confess("$attribute\_add() missing arguments");           

      VAL : for my $_arg ( @args ){
         defined $_arg or next VAL;
         # is this a val to validate?
         my $arg = $self->$method_validate($_arg);
         unless( defined $arg ){
            warn("val $arg does not validate");            
            next VAL;
         }
         
         # if it exists, increase count .. ok.. but dont push into sorted list
         if ( ! exists $self->_instancedata->{$attribute}->{$arg} ){
            push @{$self->_instancedata->{$attribute.'_ordered'}}, $arg;
         }         
         $self->_instancedata->{$attribute}->{$arg}++;
                 
         $arg = shift;  
      }
      
      return 1;  
   };   
}



sub _make_accessor_arrayref {
   my $attribute = shift;

   return sub {
      my $self = shift;
      $self->_instancedata->{$attribute.'_ordered'} ||=[];      
      return $self->_instancedata->{$attribute.'_ordered'}
   };
}

sub _make_accessor_arrayref_sorted {
   my $attribute = shift;

   return sub {
      my $self = shift;
      $self->_instancedata->{$attribute.'_ordered'} ||=[];
      my @a = sort @{ $self->_instancedata->{$attribute.'_ordered'} };
      return \@a;
   };

}


sub _make_accessor_delete {
   my $attribute = shift;
   
   return sub {
      my $self = shift;
      my $arg = shift;
      unless( defined $arg ){
         confess("$attribute\_delete() missing argument");
      }

      while( defined $arg ){
         if ( exists $self->_instancedata->{$attribute}->{$arg} ){

            # take out from ordered too!!!
            my @newlist=();
            ORDERED: for (@{$self->_instancedata->{$attribute.'_ordered'}}){
               #TODO might not work! TEST THIS!
               next ORDERED if $_ eq $arg;
               push @newlist, $_;               
            }
            $self->_instancedata->{$attribute.'_ordered'} = \@newlist;

            # take out of hash
            delete $self->_instancedata->{$attribute}->{$arg};            
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
      $self->_instancedata->{$attribute} = {};
      $self->_instancedata->{$attribute.'_ordered'} = [];      
      return 1;
   };
}

sub _make_accessor_count {
   my $attribute = shift;
   
   return sub {
      my $self = shift;
      exists $self->_instancedata->{$attribute} or return 0;
      keys %{$self->_instancedata->{$attribute}} or return 0;
      my @k = keys %{$self->_instancedata->{$attribute}};
      return scalar @k;
   };
}

sub _make_accessor_exists {
   my $attribute = shift;
   
   return sub {
      my $self = shift;
      my $arg = shift; 
      unless( defined $arg ){
         confess("$attribute\_exists() missing argument");
      }



      
      exists $self->_instancedata->{$attribute}->{$arg} or return 0;
      return 1;
   };
}



# dual 

sub _make_accessor_setget {
   my $attribute = shift;
   my $method_validate = "$attribute\_validate"; # check if val is ok

   return sub {
      my $self = shift;
      my $arg = $self->$method_validate(shift); # it's ok if returns undef

      if (defined $arg){         
         $self->_instancedata->{$attribute} = $arg;
      }
      defined $self->_instancedata->{$attribute} or return;
      return $self->_instancedata->{$attribute};   
   };
}









# singles




sub _make_accessor_single_set {
   my $attribute = shift;

   my $method_validate = "$attribute\_validate"; # check if val is ok

   return sub {
      my $self = shift;
            
      my $arg = $self->$method_validate(shift);
      defined $arg or die('bad or missing arg');
      
      $self->_instancedata->{$attribute} =$arg;
      return 1;
   };
}

sub _make_accessor_single_get {
   my $attribute = shift;
   
   return sub {
      my ($self) = @_;
      defined $self->_instancedata->{$attribute} or return;
      return $self->_instancedata->{$attribute};
   };
}

sub _make_accessor_single_clear {
   my $attribute = shift;
   
   return sub {
      my ($self) = @_;
      defined $self->_instancedata->{$attribute} or return 1;
      $self->_instancedata->{$attribute} = undef;
   };
}








# CAN BE FOR ALL
# set check , this can be redefined to check a value before it is set

sub _make_accessor_validate {
   # takes argument, returns argument
   # if result is false, returns undef
   
   #  a user can override this so that, if we expect the arg to be
   # a file on disk, we can check for that, etc before we blindly accept vals

   return sub {
      my ($self,$val) = @_;
      defined $val or return;
      return $val;
   };
}






# should be a variety of subs.. not just _instancedata
# CALL ONE TIME
sub _make_accessor_data {
   my $class = shift;
   no strict 'refs';
   
   if (defined &{"$class\::_instancedata"}){
      #print STDERR" already set _instancedata\n";
      return;

   }
   

   # for info later
   @{"$class\::__accessors_single"} = ();
   @{"$class\::__accessors_multi"} = ();
   @{"$class\::__accessors"} = ();

   *{"$class\::class_accessors_single"} = sub {
      my $self = shift;
      my @a = @{"$class\::__accessors_single"};
      return \@a;
   };

   *{"$class\::class_accessors"} = sub {
      my $self = shift;
      my @a = @{"$class\::__accessors"};
      return \@a;
   };
   
   *{"$class\::class_accessors_multi"} = sub {
      my $self = shift;
      my @a = @{"$class\::__accessors_multi"};
      return \@a;
   };

   *{"$class\::_instancedata"} = sub {
      my $self = shift;
      
      $self->{_instancedata_} ||={};
      return $self->{_instancedata_};   
   };
   
   push @{"$class\::__accessors"}, "_instancedata";
   return;
}








1;

=pod

=head1 NAME

LEOCHARRE::Class::Accessors::Base - particular setget methods

=head1 SYNOPSIS

   package Super::Hero;
   use LEOCHARRE::Class::Accessors::Base;

   __PACKAGE__->_make_new();
   __PACKAGE__->_make_accessor_single('name','age','force');
   __PACKAGE__->_make_accessor_multi('powers');
   __PACKAGE__->_make_accessor_dual('power');
   

   # or

   _make_new('Super::Hero');
   _make_accessor_single('Super::Hero','name','age','force');
   _make_accessor_multi('Super::Hero','powers');   
   _make_accessor_dual('Super::Hero','power_selected');
   
  
   

   1;

In script.pl:

   use Super::Hero;

   my $sm = new Super::Hero;

   # set methods
   
   $sm->name_set('Superman');         
   $sm->powers_add('flying','x ray vision');

   $sm->power_selected('punching');
   

   # multi get methods
   
   my $powers = $sm->powers; 
   my $powers = $sm->powers_arrayref;
   my $powers = $sm->powers_arrayref_sorted;
   my $powers = $sm->powers_sorted;
      
   # single get methods
   
   my $name = $sm->name;
   my $name = $sm->name_get;


   # more
   my $count_of_powers = $sm->powers_count;
   
   $sm->powers_exists('flying');
   $sm->powers_delete('flying');

   # get hash of all instance data this is managing
   my $instance_data = $sm->_instancedata;

   # what are the single methods?
   @Super::Hero::__accessors_single;
   
   # what are the multi methods?
   @Super::Hero::__accessors_multi;

   # what are all methods made?
   @Super::Hero::__accessors;
   
   # or
   
   $sm->class_accessors;
   $sm->class_accessors_multi;
   $sm->class_accessors_single;
   
   

=head1 DESCRIPTION

These are my personal set get methods.
There are two types of acessors, multi, and single.

getting a list of accessors set

@__PACKAGE__::__accessors_single;


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

=head2 dual accessors

these are the traditional setget methods, they both set and get
they always return the value


   $self->case or $self->case('papers');

=head1 DEBUG

   $LEOCHARRE::Class::Accessors::Base::DEBUG = 1;

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=cut
