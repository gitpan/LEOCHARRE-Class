package TestFile;
use strict;
use LEOCHARRE::Class::Accessors single => [qw(filename abs_path abs_loc ext)];
use Cwd;

sub new {
   my ($class,$_abs) = @_; 
   defined $_abs or die();
   my $self= { _abs => $_abs };
   bless $self,$class;
   
   my $abs = Cwd::abs_path($_abs) or return;
   
   $self->abs_path_set($abs);   
   $self->abs_path =~/^(.+)\/([^\/]+)$/ or die;
   $self->abs_loc_set($1);
   $self->filename_set($2);
   if($self->filename=~/.+\.(\w{1,5})$/){
      $self->ext_set($1);
   }
   
   return $self; 
}

1;

