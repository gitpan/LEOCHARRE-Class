use ExtUtils::MakeMaker;
WriteMakefile(
 NAME => 'LEOCHARRE::Class',
 VERSION_FROM => 'lib/LEOCHARRE/Class.pm',
 PREREQ_PM => {
   Carp => 0,
   'LEOCHARRE::DEBUG' => '1.06',
   'Data::Dumper' => 0,
   'Test::Simple' => 0,
 }, 
);
