use Test::Simple 'no_plan';
use strict;
use lib './t';
use lib './lib';
use TestFile;
use Cwd;
ok(1);

my $f = new TestFile( cwd().'/t/0.t');


ok($f, 'object instanced');
printf STDERR "
abs path %s
abs loc %s
filename %s
ext %s
",
$f->abs_path,
$f->abs_loc,
$f->filename,
($f->ext or 'none'),
;


