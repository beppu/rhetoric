package Rhetoric::Helpers;
use base 'Exporter';
use common::sense;
use aliased 'Squatting::H';

our @EXPORT_OK   = qw(now slug $Exception $E);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

{
  package Rhetoric::Exception;
  use base 'Squatting::H';
  use overload '""' => \&STR;
  use Method::Signatures::Simple;

  # TODO - use Devel::StackTrace or one of its variants
  method set($message) {
    $self->message($message);
    $self->stack_trace([]);
    $self;
  }

  method STR {
    $self->message;
  }
}

our $Exception = Rhetoric::Exception->new({
  type    => 'Exception',
  message => 'BOOM!?!#@@',
});
our $E = $Exception;

# y m d h m s
sub now {
  my @d = localtime;
  return (
    $d[5]+1900,
    $d[4]+1,
    $d[3],
    $d[2],
    $d[1],
    $d[0]
  );
}

# make a url-friendly slug out of a post title
sub slug {
  my $title = shift;
  $title =~ s/^\W+//;
  $title =~ s/\W+$//;
  $title =~ s/\W+/-/g;
  return $title;
}

1;
