package Rhetoric::Theme::BrownStone;
use common::sense;
use Squatting::View;
use Method::Signatures::Simple;

our $VERSION = '0.01';

our $view = Squatting::View->new(
  'BrownStone',
  _init => method($include_path) {
    $self->{tt} = Template->new({
      INCLUDE_PATH => $include_path,
      POST_CHOMP   => 1,
    });
  },
  layout => method($v, $content) {
    my $output;
    $v->{R}       = \&Rhetoric::Views::R;
    $v->{content} = $content;
    $self->{tt}->process('layout.html', $v, \$output);
    $output;
  },
  _ => method($v) {
    my $file = "$self->{template}.html";
    my $output;
    $v->{R} = \&Rhetoric::Views::R;
    my $r   = $self->{tt}->process($file, $v, \$output);
    warn $r unless ($r);
    $output;
  },
);

sub view { $view }

1;

__END__

=head1 NAME

Rhetoric::Theme::BrownStone - the default theme for Rhetoric blogs

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 API

=head2 View Object

=head3 $view->init()

=head3 $view->layout($v, $content)

=head3 $view->_($v)

=head1 SEE ALSO

L<Squatting::View>

=head1 AUTHOR

L<http://freecsstemplates.com/>

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
