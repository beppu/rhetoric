package Rhetoric;
use common::sense;
use base 'Squatting';
use aliased 'Squatting::H';

# TODO - move to Rhetoric::Storage::File
use IO::All;
use File::Path::Tiny;
use File::Find::Rule;
use File::Basename;
use Method::Signatures::Simple;

# global config for our blogging app
our %CONFIG = (
  theme               => 'default',
  storage             => 'File',  # or mysql or CouchDB or WHATEVER!!!
  posts_per_page      => 4,
  'storage.file.path' => '/tmp/rhetoric',
);

# XXX - divorce from Continuity
# TODO - Make squatting a good citizen in the Plack universe
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
  $v->{title}       = $s->meta('title');
  $v->{subtitle}    = $s->meta('subtitle');
  $v->{description} = $s->meta('description');
  $class->next::method($c, @args);
}

# shortcuts for File::Path::Tiny
# TODO - move to Rhetoric::Storage::File
*mk = *File::Path::Tiny::mk;

# y m d h m s
# TODO - move to Rhetoric::Helpers
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
# TODO - move to Rhetoric::Helpers
sub slug {
  my $title = shift;
  $title =~ s/\W+/-/g;
  return $title;
}

# Return an object that handles the storage for blog data based on
# what $CONFIG{storage} dictates.
# XXX  - hard-coded File storage implementation
# TODO - move to Rhetoric::Storage::File
sub storage {

  return H->new({

    init => method {
      my $root = $CONFIG{'storage.file.path'};
      mk("$root/posts");
      mk("$root/navigation");
      # metadata
      io("$root/title")       < "A Rhetoric Powered Blog"          unless (-e "$root/title");
      io("$root/subtitle")    < "The Art of Persuasion"            unless (-e "$root/subtitle");
      io("$root/description") < "A short description of this blog" unless (-e "$root/description");
      return 1;
    },

    meta => method($k, $v) {
      my $root = $CONFIG{'storage.file.path'};
      if (defined($v)) {
        io("$root/$k") < $v;
      } else {
        $v < io("$root/$k");
      }
      return $v;
    },

    new_post => method($post) {
      ref($post) eq 'HASH' && H->bless($post);
      my ($title, $body, $format, $schedule);
      $title = $post->title;
      $body  = $post->body;
      $format //= 'pod';
      my ($Y, $M, $D, $h, $m, $s);
      if ($schedule) {
        ($Y, $M, $D, $h, $m, $s) = split('/', $schedule);
      } else {
        ($Y, $M, $D, $h, $m, $s) = now();
      }
      my $root = $CONFIG{'storage.file.path'};
      my $post_path = sprintf("$root/posts/%d/%02d/%02d/%02d/%02d/%02d", $Y, $M, $D, $h, $m, $s);
      mk($post_path);
      io("$post_path/title")  < $title;
      io("$post_path/slug")   < slug($title);
      io("$post_path/body")   < $body;
      io("$post_path/format") < $format;
      return $post;
    },

    # fetch a post
    post => method($y, $m, $slug) {
      my $root = $CONFIG{'storage.file.path'};
      my $partial_post_path = "$root/posts/$y/$m";
      my @files = File::Find::Rule
        ->file()
        ->name('slug')
        ->in($partial_post_path);
      my ($file) = grep { my $test_slug < io($_); $test_slug eq $slug } @files;
      if ($file) {
        my $post_path = dirname($file);
        my $title  < io("$post_path/title");
        my $body   < io("$post_path/body");
        my $format < io("$post_path/format");
        my @s = split('/', $post_path);
        my $posted_on = sprintf('%s-%s-%sT%s:%s:%s', @s[-6 .. -1]);
        return H->new({
          title     => $title,
          slug      => $slug,
          body      => $body,
          format    => $format,
          posted_on => $posted_on,
        });
      } else {
        return undef;
      }
    },

    # FIXME - This implementation is not efficient,
    # FIXME - because it scans the entire post history every time.
    posts => method($count, $after) {
      my $root = $CONFIG{'storage.file.path'};
      my @all_posts = reverse sort (
        File::Find::Rule
          ->file()
          ->name('slug')
          ->in("$root/posts")
      );
      $count = (@all_posts < $count) ? scalar(@all_posts) : $count;
      my @posts = map {
        my @d = (split('/', $_))[-7 .. -1]; # d for directory
        my $slug < io($_);
        my ($y, $m) = ($d[0], $d[1]);
        $self->post($y, $m, $slug);
      } @all_posts[0 .. ($count - 1)];
    },

    # TODO - figure out how I should store category information
    categories => method {
      []
    },

    category_posts => method($category) {
      []
    },

    #
    archives => method {
      my $root = $CONFIG{'storage.file.path'};
      my $post_path = "$root/posts";
      my @d = reverse sort (
        File::Find::Rule
          ->directory()
          ->maxdepth(2)
          ->in($post_path)
      );
      my @ad = grep { scalar(@$_) == 2 } map {
        my $path = $_;
        $path =~ s/^$post_path\///;
        [ split('/', $path) ]
      } @d;
      @ad;
    },

    archive_posts => method($y, $m) {
      my $root = $CONFIG{'storage.file.path'};
      my @all_posts = reverse sort (
        File::Find::Rule
          ->file()
          ->name('slug')
          ->in("$root/posts/$y/$m")
      );
      my @posts = map {
        my @d = (split('/', $_))[-7 .. -1]; # d for directory
        my $slug < io($_);
        my ($y, $m) = ($d[0], $d[1]);
        $self->post($y, $m, $slug);
      } @all_posts;
    },

    comments => method($post) {
      []
    },

    new_comment => method($comment) {
      1;
    },

  });

}

#_____________________________________________________________________________
package Rhetoric::Controllers;
use Squatting ':controllers';
use Method::Signatures::Simple;
use aliased 'Squatting::H';

our @C = (

  C(
    Home => [ '/', '/page/(\d+)' ],
    get => method($page) {
      my $storage = Rhetoric::storage();
      my $posts   = $storage->posts($Rhetoric::CONFIG{posts_per_page});
      my $v = H->bless($self->v);
      $v->title($storage->meta('title'));
      $v->subtitle($storage->meta('subtitle'));
      $v->description($storage->meta('description'));
      $v->posts([ $storage->posts(10) ]);
      $self->render('index');
    },
  ),

  C(
    Post => [ '/(\d+)/(\d+)/([\w-]+)' ],
    get => sub {
      my ($self, $year, $month, $title_slug) = @_;
      my $v = $self->v;
      my $storage = Rhetoric::storage();
      $v->{post} = $storage->post($year, $month, $title_slug);
      $self->render('post');
    },
  ),

  C(
    NewPost => [ '/post' ],
    get => sub {
    },
    post => sub {
    },
  ),

  C(
    Comment => [ '/comment' ],
    post => sub {
    }
  ),

  C(
    Category => [ '/category/([\w-]+)' ],
    get => sub {
      my ($self, $category) = @_;
    }
  ),

  C(
    EverythingElse => [ '/(.*)' ],
    get => sub {
    }
  ),

);

#_____________________________________________________________________________
package Rhetoric::Views;
use Squatting ':views';
use Method::Signatures::Simple;
use Template;
use Data::Dump 'pp';

our $tt = Template->new({
  INCLUDE_PATH => './share/theme/brownstone',
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
      $tt->process($file, $v, \$output);
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


=cut
