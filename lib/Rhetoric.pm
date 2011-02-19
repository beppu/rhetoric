package Rhetoric;
use common::sense;
use aliased 'Squatting::H';
use Squatting;
use Try::Tiny;
use Rhetoric::Helpers ':all';

our $VERSION = '0.01';

# global config for our blogging app
our %CONFIG = (
  'theme'               => 'BrownStone',          # Rhetoric::Theme::____
  'time_format'         => '%b %e, %Y %I:%M%P',
  'posts_per_page'      => 8,
  'storage'             => 'File',                # Rhetoric::Storage::____
  'storage.file.path'   => '/tmp/rhetoric',
);

# TODO - divorce Continuity
# TODO - marry   Plack
sub continue {
  my $app = shift;
  $app->next::method(
    docroot => "./share/theme/brownstone", 
    staticp => sub { $_[0]->url =~ m/\.(jpg|jpeg|gif|png|css|ico|js|swf)$/ },
    @_
  );
}

# service() is run on every request (just like in Camping).
sub service {
  my ($class, $c, @args) = @_;
  my $v = $c->v;
  my $s = $v->{storage} = storage();
  H->bless($v);
  H->bless($c->input);
  $v->{title}        = $s->meta('title');
  $v->{subtitle}     = $s->meta('subtitle');
  $v->{description}  = $s->meta('description');
  $v->{menu}         = $s->menu;
  $v->{request_path} = $c->env->{REQUEST_PATH};
  $class->next::method($c, @args);
}

# Return an object that handles the storage for blog data based on
# what $CONFIG{storage} dictates.
sub storage {
  no strict 'refs';
  my $impl    = shift || $Rhetoric::CONFIG{'storage'};
  my $path    = "Rhetoric/Storage/$impl.pm";
  my $package = "Rhetoric::Storage::$impl";
  try {
    require($path);
  } catch {
    warn "$package could not be loaded: $_";
  };
  return ${"${package}::storage"};
}

#_____________________________________________________________________________
package Rhetoric::Controllers;
use common::sense;
use aliased 'Squatting::H';
use Method::Signatures::Simple;
use Rhetoric::Helpers ':all';

our @C = (

  C(
    Home => [ '/', '/page/(\d+)' ],
    get => method($page) {
      my $v       = $self->v;
      my $storage = $v->storage;
      $v->{posts} = $storage->posts($CONFIG{posts_per_page});
      $self->render('index');
    },
  ),

  C(
    Post => [ '/(\d+)/(\d+)/([\w-]+)' ],
    get => method($year, $month, $slug) {
      my $v          = $self->v;
      my $storage    = $v->storage;
      $v->{post}     = $storage->post($year, $month, $slug);
      $v->{comments} = $storage->comments($v->{post});
      $self->render('post');
    },
    post => method($year, $month, $slug) {
      my $v       = $self->v;
      my $storage = $v->storage;
      my $post    = $v->{post} = $storage->post($year, $month, $slug);
      # XXX - modify post and redirect
    }
  ),

  # Need to be able to create posts from a form too, right?!
  C(
    NewPost => [ '/post' ],
    get => method {
      $self->render('new_post');
    },
    post => method {
    },
  ),

  C(
    NewComment => [ '/comment' ],
    post => method {
      my $input   = $self->input;
      my $year    = $input->{year};
      my $month   = $input->{month};
      my $slug    = $input->{slug};
      my $name    = $input->{name};
      my $email   = $input->{email};
      my $url     = $input->{url};
      my $body    = $input->{body};
      my $storage = $self->v->storage;
      my $result  = $storage->new_comment($year, $month, $slug, {
        name      => $name,
        email     => $email,
        url       => $url,
        body      => $body
      });
      if ($result->success) {
        $self->redirect(R('Post', $year, $month, $slug));
      } else {
        # TODO - put errors in session
        $self->redirect(R('Post', $year, $month, $slug));
      }
    }
  ),

  C(
    Category => [ '/category/([\w-]+)' ],
    get => method($category) {
      my $storage = Rhetoric::storage();
      my $v = $self->v;
      $v->posts = $storage->category_posts($category);
      $self->render('category');
    }
  ),

  C(
    Env => [ '/env' ],
    get => method {
      use Data::Dump 'pp';
      $self->headers->{'Content-Type'} = 'text/plain';
      return pp($self->env);
    }
  ),

  # Everything else that's not static is a page to be rendered through the view.
  C(
    Page => [ '/(.*)' ],
    get => method($path) {
      if ($path =~ /\.\./) {
        $self->status = 404;
        return "GTFO";
      }
      my $v = $self->v;
      $self->render($path);
    }
  ),

);

#_____________________________________________________________________________
package Rhetoric::Views;
use Method::Signatures::Simple;
use Template;
use Data::Dump 'pp';

our $tt = Template->new({
  INCLUDE_PATH => './share/theme/BrownStone',
  POST_CHOMP   => 1,
});

our @V = (
  V(
    'tt',
    layout => method($v, $content) {
      my $output;
      $v->{R} = \&R;
      $v->{content} = $content;
      $tt->process('layout.html', $v, \$output);
      $output;
    },
    _ => method($v) {
      my $file = "$self->{template}.html";
      my $output;
      $v->{R} = \&R;
      my $r = $tt->process($file, $v, \$output);
      warn $r unless ($r);
      $output;
    },
  )
);

1;

=head1 NAME

Rhetoric - a simple blogging system for perl

=head1 SYNOPSIS

Running a blog

  $ squatting Rhetoric

Playing with the interactive console

  $ squatting -C Rhetoric
    \%Rhetoric::CONFIG
    $s = Rhetoric::storage()
    $s->metadata('title');
    $s->recent_posts()


=head1 DESCRIPTION

A simple and straight-forward blogging system for Perl.

=head1 API

=head2 Home

/

/page/(\d+)

=head3 get


=head2 Post

/(\d+)/(\d+)/(\w+)

=head3 get



=head2 NewPost

/post

=head3 get

=head3 post



=head2 Comment

/comment

=head3 post



=head2 Category

/category/(\w+)

=head3 get



=head2 EverythingElse

/(.*)

=head3 get



=head1 AUTHOR

John BEPPU E<lt>beppu@cpan.orgE<gt>


=head1 COPYRIGHT

GPL

=cut
