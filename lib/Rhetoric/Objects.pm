package Rhetoric::Objects;
use common::sense;
use aliased 'Squatting::H';
use Method::Signatures::Simple;

our $Post = H->new({
  title     => '',
  format    => 'pod',
  body      => '',
  read_more => '',
});

our $Comment = H->new({
  name   => '',
  email  => '',
  format => '',
  body   => '',
});

1;

__END__

=head1 NAME

Rhetoric::Objects - templates for common objects

=head1 SYNOPSIS

Importing the objects

  use Rhetoric::Objects;
  *Post    = *Rhetoric::Objects::Post;
  *Comment = *Rhetoric::Objects::Comment;

Using the objects

  my $new_post = $Post->clone({ title => 'Something' });
  my $new_comment = $Comment->clone({ name => 'beppu', body => 'NICE' });

=head1 DESCRIPTION

All a class is is a template for an object.

Why can't an object be a template for an object?

=head1 API

=head2  Post Object

=head3    $post->title

=head3    $post->format

=head3    $post->body

=head3    $post->read_more

=head3    $post->comments

=head2  Comment Object

=head3    $comment->name

=head3    $comment->email

=head3    $comment->format

=head3    $comment->body

=head1 SEE ALSO

L<Squatting::H>,
L<Class::Classless>

=head1 AUTHOR

John BEPPU E<lt>beppu@cpan.orgE<gt>

=cut

# Local Variables: ***
# mode: cperl ***
# indent-tabs-mode: nil ***
# cperl-close-paren-offset: -2 ***
# cperl-continued-statement-offset: 2 ***
# cperl-indent-level: 2 ***
# cperl-indent-parens-as-block: t ***
# cperl-tab-always-indent: nil ***
# End: ***
# vim:tabstop=2 softtabstop=2 shiftwidth=2 shiftround expandtab
