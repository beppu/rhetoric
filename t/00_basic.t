use common::sense;
use Test::More;

my @tests = (
  sub {
    use_ok('Rhetoric');
  },
);

plan tests => scalar(@tests);
$_->() for (@tests);
