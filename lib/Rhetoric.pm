package Rhetoric;
use common::sense;
use base 'Squatting';
use aliased 'Squatting::H';
use IO::All;
use File::Path::Tiny;
use File::Find::Rule;
use File::Basename;

# global config for our blogging app
our %CONFIG = (
  theme               => 'default',
  storage             => 'File',  # or mysql or CouchDB or WHATEVER!!!
  'storage-file-path' => '/tmp/rhetoric',
);

# shortcuts for File::Path::Tiny
*mk = *File::Path::Tiny::mk;

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
  $title =~ s/\s+/-/g;
  $title =~ s/\W//g;
  return $title;
}

# Return an object that handles the storage for blog data based on
# what $CONFIG{storage} dictates.
# XXX  - hard-coded File storage implementation
# TODO - move this to its own module
sub storage {

  return H->new({

    init => sub {
      my $root = $CONFIG{'storage-file-path'};
      mkdir "$root";
      mkdir "$root/posts";
      mkdir "$root/navigation";
      # metadata
      io("$root/title")       < "A Rhetoric Powered Blog"          unless (-e "$root/title");
      io("$root/subtitle")    < "The Art of Persuasion"            unless (-e "$root/subtitle");
      io("$root/description") < "A short description of this blog" unless (-e "$root/description");
      return 1;
    },

    metadata=> sub {
      my ($self, $k, $v) = @_;
      my $root = $CONFIG{'storage-file-path'};
      if (defined($v)) {
        io("$root/$k") < $v;
      } else {
        $v < io("$root/$k");
      }
      return $v;
    },

    new_post => sub {
      my ($self, $post) = @_;
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
      my $root = $CONFIG{'storage-file-path'};
      my $post_path = sprintf("$root/posts/%d/%02d/%02d/%02d/%02d/%02d", $Y, $M, $D, $h, $m, $s);
      mk($post_path);
      io("$post_path/title")  < $title;
      io("$post_path/slug")   < slug($title);
      io("$post_path/body")   < $body;
      io("$post_path/format") < $format;
      return $post;
    },

    # fetch a post
    post => sub {
      my ($self, $y, $m, $slug) = @_;
      my $root = $CONFIG{'storage-file-path'};
      my $partial_post_path = "$root/posts/$y/$m";
      my @files = File::Find::Rule
        ->file()
        ->name('slug')
        ->in($partial_post_path);
      my ($file) = grep { my $test_slug < io($_); $test_slug eq $slug } @files;
      warn $file;
      if ($file) {
        my $post_path = dirname($file);
        warn $post_path;
        my $title  < io("$post_path/title");
        my $body   < io("$post_path/body");
        my $format < io("$post_path/format");
        my @s = split('/', $post_path);
        my $schedule = join('/', @s[-6 .. -1]);
        return H->new({
          title    => $title,
          slug     => $slug,
          body     => $body,
          format   => $format,
          schedule => $schedule,
        });
      } else {
        return undef;
      }
    },

    recent_posts => sub {
      []
    },

    category_posts => sub {
      []
    },

    category_list => sub {
      []
    },

    comments => sub {
      []
    },

  });

}

#_____________________________________________________________________________
package Rhetoric::Controllers;
use Squatting ':controllers';

our @C = (

  C(
    Home => [ '/', '/page/(\d+)' ],
    get => sub {
      my ($self, $page) = @_;
      my $storage = Rhetoric::storage();
      'no worky yet';
    },
  ),

  C(
    Post => [ '/(\d+)/(\d+)/(\w+)' ],
    get => sub {
      my ($self, $year, $month, $title_slug) = @_;
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
    Category => [ '/category/(\w+)' ],
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
use Template;

our @V = (
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
