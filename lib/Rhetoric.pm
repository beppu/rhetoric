package Rhetoric;
use common::sense;
use Squatting;
use aliased 'Squatting::H';

# TODO - move to Rhetoric::Storage::File
use IO::All;
use File::Path::Tiny;
use File::Find::Rule;
use File::Basename;
use Method::Signatures::Simple;
use DateTime;

our $VERSION = '0.01';

# global config for our blogging app
our %CONFIG = (
  'theme'               => 'BrownStone',
  'time_format'         => '%b %e, %Y %I:%M%P',
  'posts_per_page'      => 8,
  'storage'             => 'File',  # or mysql or CouchDB or WHATEVER!!!
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
      mk("$root/menu");
      mk("$root/sidebar");
      # metadata
      io("$root/title")       < "Rhetoric"                                   unless (-e "$root/title");
      io("$root/subtitle")    < "Simple Blogging for Perl"                   unless (-e "$root/subtitle");
      # XXX - going to move description into a sidebar module
      io("$root/description") < "STOP MAKING SHIT SO GOD DAMNED COMPLICATED" unless (-e "$root/description");
      io("$root/pages")       < "about\nlinks\ncontact\n"                    unless (-e "$root/pages");
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
      my $dt   = DateTime->new(
        year   => $Y,
        month  => $M,
        day    => $D,
        hour   => $h,
        minute => $m,
        second => $s,
      );
      my $root = $CONFIG{'storage.file.path'};
      my $post_path = sprintf("$root/posts/%d/%02d/%02d/%02d/%02d/%02d", $Y, $M, $D, $h, $m, $s);
      mk($post_path);
      io("$post_path/title")  < $title;
      io("$post_path/slug")   < slug($title);
      io("$post_path/body")   < $body;
      io("$post_path/format") < $format;
      $post->slug(slug($title));
      $post->format($format);
      $post->year($Y);
      $post->month($M);
      $post->posted_on($dt);
      $post->author($ENV{USER});
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
        my ($Y, $M, $D, $h, $m, $s) = @s[-6 .. -1];
        my $posted_on = sprintf('%s-%s-%sT%s:%s:%s', $Y, $M, $D, $h, $m, $s);
        my $post = H->new({
          title     => $title,
          slug      => $slug,
          body      => $body,
          format    => $format,
          posted_on => $posted_on,
          year      => $Y,
          month     => $M,
          day       => $D,
          hour      => $h,
          minute    => $m,
          second    => $s,
          author    => ( getpwuid( (stat("$post_path/title"))[4] ) )[0],
        });
        #$post->comments($self->comments($post));
        return $post;
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
      my $root = $CONFIG{'storage.file.path'};
      my $post_path = sprintf('%s/posts/%s/%s/%s/%s/%s/%s',
        $root,
        $post->year, $post->month,  $post->day,
        $post->hour, $post->minute, $post->second,
      );
      my @comment_files = sort glob("$post_path/comments/*");
      my @comments = map {
        my ($name,$email,$url,@body) = io($_)->slurp;
        chomp($name, $email, $url);
        my $body = join('', @body);
        H->new({
          name  => $name,
          email => $email,
          url   => $url,
          body  => $body,
        });
      } @comment_files;
      \@comments;
    },

    new_comment => method($year, $month, $slug, $comment) {
      ref($comment) eq 'HASH' && H->bless($comment);
      my $post = $self->post($year, $month, $slug);
      my $root = $CONFIG{'storage.file.path'};
      my $post_path = sprintf('%s/posts/%s/%s/%s/%s/%s/%s',
        $root,
        $post->year, $post->month,  $post->day,
        $post->hour, $post->minute, $post->second,
      );
      warn("$post_path/comments");
      mk("$post_path/comments");
      my @comment_files = sort glob("$post_path/comments/*");
      my $index = '001';
      if (@comment_files) {
        warn "previous comments existed";
        my $last = (split('/', $comment_files[-1]))[-1];
        $last =~ s/^0*//;
        warn "last is $last";
        $index = sprintf('%03d', $last + 1);
      }
      warn $index;
      io("$post_path/comments/$index") <  $comment->name  . "\n";
      io("$post_path/comments/$index") << $comment->email . "\n";
      io("$post_path/comments/$index") << $comment->url   . "\n";
      io("$post_path/comments/$index") << $comment->body  . "\n";
      $comment->success(1);
      $comment;
    },

  });

}

#_____________________________________________________________________________
package Rhetoric::Controllers;
use common::sense;
use Method::Signatures::Simple;
use aliased 'Squatting::H';

our @C = (

  C(
    Home => [ '/', '/page/(\d+)' ],
    get => method($page) {
      my $v       = $self->v;
      my $storage = $v->storage;
      $v->{posts} = [ $storage->posts($CONFIG{posts_per_page}) ];
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
    }
  ),

  C(
    X => [ '/(.*)' ],
    get => method($path) {
      if ($path =~ /\.\./) {
        $self->status = 404;
        return "GTFO";
      }
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
