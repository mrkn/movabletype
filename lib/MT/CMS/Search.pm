# Movable Type (r) Open Source (C) 2001-2009 Six Apart, Ltd.
# This program is distributed under the terms of the
# GNU General Public License, version 2.
#
# $Id$
package MT::CMS::Search;

use strict;
use MT::Util qw( is_valid_date );

sub core_search_apis {
    my $app = shift;
    my $q       = $app->param;
    my $blog_id = $q->param('blog_id');
    my $author  = $app->user;
    my @perms;
    if ( !$blog_id ) {
        if ( !$author->is_superuser() ) {
            require MT::Permission;
            @perms = MT::Permission->load( { author_id => $author->id } );
        }
    }
    else {
        @perms = ( $app->permissions )
          or return $app->error( $app->translate("No permissions") );
    }
    my $types = {
        'entry' => {
            'order' => 100,
            'permission' => 'create_post,publish_post,edit_all_posts',
            'handler' => '$Core::MT::CMS::Entry::build_entry_table',
            'label' => 'Entries',
            'perm_check' => sub {
                grep { $_->can_edit_entry( $_[0], $author ) } @perms;
            },
            'search_cols' => {
                'title' => sub { $app->translate('Title') },
                'text' => sub { $app->translate('Entry Body') },
                'text_more' => sub { $app->translate('Extended Entry') },
                'keywords' => sub { $app->translate('Keywords') },
                'excerpt' => sub { $app->translate('Excerpt') },
                'basename' => sub { $app->translate('Basename') },
            },
            'replace_cols'       => [qw(title text text_more keywords excerpt)],
            'can_replace'        => 1,
            'can_search_by_date' => 1,
            'date_column'        => 'authored_on',
        },
        'comment' => {
            'order' => 200,
            'permission' => 'publish_post,create_post,edit_all_posts,manage_feedback',
            'handler' => '$Core::MT::CMS::Comment::build_comment_table',
            'label' => 'Comments',
            'perm_check' => sub {
                require MT::Entry;
                my $entry = MT::Entry->load( $_[0]->entry_id );
                grep { $_->can_edit_entry( $entry, $author ) } @perms;
            },
            'search_cols' => {
                'url' => sub { $app->translate('URL') },
                'text' => sub { $app->translate('Comment Text') },
                'email' => sub { $app->translate('Email Address') },
                'ip' => sub { $app->translate('IP Address') },
                'author' => sub { $app->translate('Name') },
            },
            'replace_cols'       => [qw(text)],
            'can_replace'        => 1,
            'can_search_by_date' => 1,
        },
        'ping' => {
            'order' => 300,
            'permission' => 'create_post,publish_post,edit_all_posts,manage_feedback',
            'label' => 'TrackBacks',
            'handler' => '$Core::MT::CMS::TrackBack::build_ping_table',
            'perm_check' => sub {
                my $ping = shift;
                my $tb   = MT::Trackback->load( $ping->tb_id )
                    or return undef;
                if ( $tb->entry_id ) {
                    require MT::Entry;
                    my $entry = MT::Entry->load( $tb->entry_id );
                    return
                      grep { $_->can_edit_entry( $entry, $author ) } @perms;
                }
                elsif ( $tb->category_id ) {
                    return grep { $_->can_do('search_category_trackbacks') } @perms;
                }
            },
            'search_cols' => {
                'title' => sub { $app->translate('Title') },
                'excerpt' => sub { $app->translate('Excerpt') },
                'source_url' => sub { $app->translate('Source URL') },
                'ip' => sub { $app->translate('IP Address') },
                'blog_name' => sub { $app->translate('Blog Name') },
            },
            'replace_cols'       => [qw(title excerpt)],
            'can_replace'        => 1,
            'can_search_by_date' => 1,
        },
        'page' => {
            'order' => 400,
            'permission' => 'manage_pages',
            'label' => 'Pages',
            'handler' => '$Core::MT::CMS::Entry::build_entry_table',
            'perm_check' => sub {
                grep { $_->can_manage_pages( $_[0], $author ) } @perms;
            },
            'search_cols' => {
                'title' => sub { $app->translate('Title') },
                'text' => sub { $app->translate('Page Body') },
                'text_more' => sub { $app->translate('Extended Page') },
                'keywords' => sub { $app->translate('Keywords') },
                'excerpt' => sub { $app->translate('Excerpt') },
                'basename' => sub { $app->translate('Basename') },
            },
            'replace_cols'       => [qw(title text text_more keywords excerpt)],
            'can_replace'        => 1,
            'can_search_by_date' => 1,
            'date_column'        => 'authored_on',
            'results_table_template' => '<mt:include name="include/entry_table.tmpl">',
        },
        'template' => {
            'order'             => 500,
            'permission'        => 'edit_templates',
            'system_permission' => 'edit_templates',
            'handler' => '$Core::MT::CMS::Template::build_template_table',
            'label'         => 'Templates',
            'perm_check' => sub {
                my ($obj) = @_;

                # are there any perms that match this object and
                # allow template editing?
                my @check = grep {
                         $_->blog_id == $obj->blog_id
                      && $_->can_do('search_templates')
                } @perms;
                return @check;

            },
            'search_cols' => {
                'name' => sub { $app->translate('Template Name') },
                'text' => sub { $app->translate('Text') },
                'linked_file' => sub { $app->translate('Linked Filename') },
                'outfile' => sub { $app->translate('Output Filename') },
            },
            'replace_cols'       => [qw(name text linked_file outfile)],
            'can_replace'        => 1,
            'can_search_by_date' => 0,
        },
        'asset' => {
            'order' => 600,
            'permission' => 'edit_assets',
            'label' => 'Assets',
            'handler' => '$Core::MT::CMS::Asset::build_asset_table',
            'perm_check' => sub {
                my ($obj) = @_;
                my $perm = $author->permissions( $obj->blog_id );
                return $perm->can_do('search_assets');
            },
            'search_cols' => {
                'file_name' => sub { $app->translate('Filename') },
                'description' => sub { $app->translate('Description') },
                'label' => sub { $app->translate('Label') },
            },
            'replace_cols'       => [],
            'can_replace'        => 0,
            'can_search_by_date' => 1,
            'setup_terms_args'   => sub {
                my ($terms, $args, $blog_id) = @_;
                $terms->{class}
                    = ( $app->param('filter') 
                        && $app->param('filter_val')
                        && $app->param('filter') eq 'class'
                        && $app->param('filter_val') eq 'image' ) ? 'image' : '*';
                $terms->{blog_id} = $blog_id if $blog_id;
            }
        },
        'log' => {
            'order' => 700,
            'permission'        => "view_blog_log",
            'system_permission' => "view_log",
            'handler' => '$Core::MT::CMS::Log::build_log_table',
            'label' => 'Activity Log',
            'perm_check' => sub {
                my ($obj) = @_;
                return 1 if $author->can_do('search_log');
                my $perm = $author->permissions( $obj->blog_id );
                return $perm->can_do('search_blog_log');
            },
            'search_cols' => {
                'ip' => sub { $app->translate('Log Message') },
                'message' => sub { $app->translate('IP Address') },
            },
            'can_replace'        => 0,
            'can_search_by_date' => 1,
            'setup_terms_args'   => sub {
                my ($terms, $args, $blog_id) = @_;
                $terms->{class} = '*';
                $terms->{blog_id} = $blog_id if $blog_id;
            }
        },
        'author' => {
            'order' => 800,
            'system_permission' => 'administer',
            'permission' => 'administer_blog',
            'label' => 'Users',
            'handler' => '$Core::MT::CMS::User::build_author_table',
            'perm_check' => sub {
                return 1 if $author->is_superuser;
                if ($blog_id) {
                    my $perm = $author->permissions($blog_id);
                    return $perm->can_do('search_authors');
                }
                return 0;
            },
            'search_cols' => {
                'name'     => sub { $app->translate('Username') },
                'nickname' => sub { $app->translate('Display Name') },
                'email'    => sub { $app->translate('Email Address') },
                'url'      => sub { $app->translate('URL') },
            },
            'can_replace'        => 0,
            'can_search_by_date' => 0,
            'setup_terms_args'   => sub {
                my ($terms, $args, $blog_id) = @_;
                if ($blog_id) {
                    $args->{'join'} =
                      MT::Permission->join_on( 'author_id',
                        { blog_id => $blog_id } );
                }
                else {
                    $terms->{'type'} = MT::Author::AUTHOR();
                }
            },
            'results_table_template' => '
<mt:if name="blog_id">
    <mt:include name="include/member_table.tmpl">
<mt:else>
    <mt:include name="include/author_table.tmpl">
</mt:if>',
        },
        'blog' => {
            'order' => 900,
            'label' => 'Blogs',
            'handler' => '$Core::MT::CMS::Blog::build_blog_table',
            'perm_check' => sub {
                return 1 if $author->is_superuser ||
                    $author->permissions(0)->can_do('edit_templates');
                my ($obj) = @_;
                my $perm = $author->permissions( $obj->id );
                return $perm && ( $perm->blog_id == $obj->id ) ? 1 : 0;
            },
            'search_cols' => {
                'name' => sub { $app->translate('Name') },
                'site_url' => sub { $app->translate('Site URL') },
                'site_path' => sub { $app->translate('Site Root') },
                'description' => sub { $app->translate('Description') },
            },
            'replace_cols'       => [qw(name site_url site_path description)],
            'can_replace'        => $author->is_superuser(),
            'can_search_by_date' => 0,
            'setup_terms_args'   => sub {
                my ($terms, $args, $blog_id) = @_;
                $args->{sort}      = 'name';
                $args->{direction} = 'ascend';
            }
        },
        'website' => {
            'order' => 1000,
            'system_permission' => 'administer,edit_templates',
            'label' => 'Websites',
            'handler' => '$Core::MT::CMS::Website::build_website_table',
            'perm_check' => sub {
                return 1 if $author->is_superuser;
                return 1 if $author->permissions(0)->can_do('edit_templates');
                my ($obj) = @_;
                my $perm = $author->permissions( $obj->id );
                return $perm && ( $perm->blog_id == $obj->id ) ? 1 : 0;
            },
            'search_cols' => {
                'name' => sub { $app->translate('Name') },
                'site_url' => sub { $app->translate('Site URL') },
                'site_path' => sub { $app->translate('Site Root') },
                'description' => sub { $app->translate('Description') },
            },
            'replace_cols'       => [qw(name site_url site_path description)],
            'can_replace'        => $author->is_superuser(),
            'can_search_by_date' => 0,
            'view'               => 'system',
            'setup_terms_args'   => sub {
                my ($terms, $args, $blog_id) = @_;
                $args->{sort}      = 'name';
                $args->{direction} = 'ascend';
            }
        }
    };
    return $types;
}

sub search_replace {
    my $app = shift;
    $app->return_to_dashboard( redirect => 1 )
        unless $app->can_do('use_tools:search');

    my $param = do_search_replace($app, @_) or return;
    my $blog_id = $app->param('blog_id');
    $app->add_breadcrumb( $app->translate('Search & Replace') );
    $param->{nav_search}   = 1;
    $param->{screen_class} = "search-replace";
    $param->{screen_id}    = "search-replace";
    $param->{search_tabs}  = $app->search_apis($blog_id ? 'blog' : 'system');
    $param->{entry_type}  = $app->param('entry_type');

    if ($app->param('_type') =~ /entry|page|comment|template/) {
        if ($app->param('blog_id')) {
            my $perms = $app->permissions;
            $param->{can_republish} = $perms->can_rebuild || $app->user->is_superuser;
            $param->{can_empty_junk} = $perms->can_rebuild || $app->user->is_superuser;
            $param->{state_editable} = $perms->can_rebuild || $app->user->is_superuser;
            $param->{publish_from_search} = $perms->can_rebuild || $app->user->is_superuser;
        } else {
            $param->{can_republish} = 1;
            $param->{can_empty_junk} = 1;
            $param->{state_editable} = 1;
            $param->{publish_from_search} = 1;
            }
    }

    my $tmpl = $app->load_tmpl( 'search_replace.tmpl', $param );
    my $placeholder = $tmpl->getElementById('search_results');
    $placeholder->innerHTML(delete $param->{results_template});
    return $tmpl;
}

sub do_search_replace {
    my $app     = shift;
    my $q       = $app->param;
    my $blog_id = $q->param('blog_id');
    my $author  = $app->user;

    my $search_api = $app->registry("search_apis");

    my (
        $search,        $replace,     $do_replace,     $case,
        $is_regex,      $is_limited,  $type,           $is_junk,
        $is_dateranged, $ids,         $datefrom_year,  $datefrom_month,
        $datefrom_day,  $dateto_year, $dateto_month,   $dateto_day,
        $from,          $to,          $show_all,       $do_search,
        $orig_search,   $quicksearch, $publish_status, $my_posts,
        $search_type,
      )
      = map scalar $q->param($_),
      qw( search replace do_replace case is_regex is_limited _type is_junk is_dateranged replace_ids datefrom_year datefrom_month datefrom_day dateto_year dateto_month dateto_day from to show_all do_search orig_search quicksearch publish_status my_posts search_type);

    # trim 'search' parameter
    $search =~ s/(^\s+|\s+$)//g;
    $app->param('search', $search);

    $type = $search_type if $search_type;
    if ( !$type || ( 'category' eq $type ) || ( 'folder' eq $type ) ) {
        $type = 'entry';
    }
    if ( ( 'user' eq $type ) ) {
        $type = 'author';
    }

    foreach my $obj_type (qw( role association )) {
        if ( $type eq $obj_type ) {
            $type = 'author';
        }
    }

    $replace && ( $app->validate_magic() or return );
    $search = $orig_search if $do_replace;    # for safety's sake
    my $list_pref = $app->list_pref($type);

    $app->assert( $search_api->{$type}, "Invalid request." ) or return;

    # force action bars to top and bottom
    $list_pref->{"bar"}                     = 'both';
    $list_pref->{"position_actions_both"}   = 1;
    $list_pref->{"position_actions_top"}    = 1;
    $list_pref->{"position_actions_bottom"} = 1;
    $list_pref->{"view"}                    = 'compact';
    $list_pref->{"view_compact"}            = 1;
    my ( @cols, $datefrom, $dateto, $date_col );
    $do_replace    = 0 unless $search_api->{$type}{can_replace};
    $is_dateranged = 0 unless $search_api->{$type}{can_search_by_date};
    my @ids;

    if ($ids) {
        @ids = split /,/, $ids;
    }
    if ($is_limited) {
        @cols = $q->param('search_cols');
        my %search_api_cols =
          map { $_ => 1 } keys %{ $search_api->{$type}{search_cols} };
        if ( @cols && ( $cols[0] =~ /,/ ) ) {
            @cols = split /,/, $cols[0];
        }
        @cols = grep { $search_api_cols{$_} } @cols;
    }
    else {
        @cols = keys %{ $search_api->{$type}->{search_cols} };
    }
    my $quicksearch_id;
    if ($quicksearch && ($search || '') ne '' && $search !~ m{ \D }xms) {
        $quicksearch_id = $search;
        unshift @cols, 'id';
    }
    foreach (
        $datefrom_year, $datefrom_month, $datefrom_day,
        $dateto_year,   $dateto_month,   $dateto_day
      )
    {
        s!\D!!g if $_;
    }
    if ($is_dateranged) {
        $datefrom = sprintf( "%04d%02d%02d",
            $datefrom_year, $datefrom_month, $datefrom_day );
        $dateto =
          sprintf( "%04d%02d%02d", $dateto_year, $dateto_month, $dateto_day );
        if ( ( $datefrom eq '00000000' ) && ( $dateto eq '00000000' ) ) {
            $is_dateranged = 0;
        }
        else {
            if (   !is_valid_date( $datefrom . '000000' )
                || !is_valid_date( $dateto . '000000' ) )
            {
                return $app->error(
                    $app->translate(
                        "Invalid date(s) specified for date range.")
                );
            }
        }
    }
    elsif ( $from && $to ) {
        $is_dateranged = 1;
        s!\D!!g foreach ( $from, $to );
        $datefrom = substr( $from, 0, 8 );
        $dateto   = substr( $to,   0, 8 );
    }
    my $tab = $q->param('tab') || 'entry';
    ## Sometimes we need to pass in the search columns like 'title,text', so
    ## we look for a comma (not a valid character in a column name) and split
    ## on it if it's there.
    my $plain_search = $search;
    if ( ($search || '') ne '' ) {
        $search = quotemeta($search) unless $is_regex;
        $search = '(?i)' . $search   unless $case;
    }
    my ( @to_save, @data );
    my $api   = $search_api->{$type};
    my $class = $app->model($api->{object_type} || $type);
    my %param = %$list_pref;
    my $limit;
    # type-specific directives override global CMSSearchLimit
    my $directive = 'CMSSearchLimit' . ucfirst($type);
    $limit = MT->config->$directive || MT->config->CMSSearchLimit || 125;
    # don't allow passed limit to be higher than config limit
    if ($q->param('limit') && ($q->param('limit') < $limit)) {
        $limit = $q->param('limit');
    }
    $limit =~ s/\D//g if $limit ne 'all';
    my $matches;
    $date_col = $api->{date_column} || 'created_on';
    if ( ( $do_search && $search ne '' ) || $show_all || $do_replace || defined $publish_status || $my_posts ) {
        my %terms;
        my %args;
        ## we need to search all user/group for 'grant permissions',
        ## if $blog_id is specified. it affects the setup_terms_args.
        if ( $app->param('__mode') eq 'dialog_grant_role' ) {
            if ($blog_id) {
                my $perm = $author->permissions($blog_id);
                return $app->errtrans('Permission denied.')
                    unless $perm->can_do('search_members');
            }
            $blog_id = 0;
        }
        if (exists $api->{setup_terms_args}) {
            my $code = $app->handler_to_coderef($api->{setup_terms_args});
            $code->(\%terms, \%args, $blog_id);
        }
        else {
            if ( $blog_id ) {
                require MT::Blog;
                my $blog = MT::Blog->load($blog_id) if $blog_id;
                if ($blog && !$blog->is_blog && $author->permissions($blog_id)->has('manage_member_blogs')) {
                    my @blogs = MT::Blog->load({ parent_id => $blog->id });;
                    my @blog_ids = map { $_->id } @blogs;
                    push @blog_ids, $blog_id;
                    %terms =  ( blog_id => \@blog_ids );
                } else {
                    %terms = ( blog_id => $blog_id );
                }
            }
            if ( $type ne 'template' ) {
                %args = ( 'sort' => $date_col, direction => 'descend' );
            }
        }
        if ( $class->has_column('junk_status') ) {
            require MT::Comment;
            if ($is_junk) {
                $terms{junk_status} = MT::Comment::JUNK();
            }
            else {
                $terms{junk_status} = MT::Comment::NOT_JUNK();
            }
        }
        if ( ( defined $publish_status && $publish_status =~ m/[\d]/ ) && ( $type eq 'entry' || $type eq 'page' ) ) {
            $terms{status} = $publish_status;
            $terms{class} = $type;
        }
        if ($is_dateranged) {
            $args{range_incl}{$date_col} = 1;
            if ( $datefrom gt $dateto ) {
                $terms{$date_col} =
                  [ $dateto . '000000', $datefrom . '235959' ];
            }
            else {
                $terms{$date_col} =
                  [ $datefrom . '000000', $dateto . '235959' ];
            }
        }
        if ( defined $publish_status ) {
            if ( $type eq 'entry' || $type eq 'page' ) {
                $terms{status} = $publish_status;
            }
        }
        if ( $my_posts ) {
            if ( $type eq 'comment' ) {
                $args{join} = MT::Entry->join_on(
                    undef,
                    {   id        => \'= comment_entry_id',
                        author_id => $app->user->id
                    }
                );
            } elsif ( $type eq 'entry' || $type eq 'page' ) {
                $terms{author_id} = $app->user->id;
            }
        }

        my @terms;
        # MT::Object doesn't like multi-term hashes within arrays
        if (%terms) {
        	for my $key (keys %terms) {
        		push(@terms, { $key => $terms{$key} });
        	}
        	push(@terms, '-and');
        }
        my @col_terms;
        my $query_string = "%$plain_search%";
        for my $col (@cols) {
            push(@col_terms, { $col => { like => $query_string } }, '-or' );
        }
        delete $col_terms[$#col_terms];
        push(@terms, \@col_terms);
        $args{limit} = $limit + 1 if $limit ne 'all';
        my $iter;
        if ($do_replace) {
            $iter = sub {
                if ( my $id = pop @ids ) {
                    $class->load($id);
                }
            };
        } else {
            if ( $blog_id
              || ( $type eq 'blog' )
              || ( $app->mode eq 'dialog_grant_role' ) )
            {
                $iter = $class->load_iter( \@terms, \%args ) or die $class->errstr;
            }
            else {

                my @streams;
                if ( $author->is_superuser ) {
                    @streams = ( { iter => $class->load_iter( \@terms, \%args ) } );
                }
                else {
                    # Get an iter for each accessible blog
                    my @perms = $app->model('permission')->load(
                        { blog_id => '0', author_id => $author->id },
                        { not => { blog_id => 1 } },
                    );
                    if (@perms) {
                        my @blog_terms;
                        push( @blog_terms, { blog_id => $_->blog_id, }, '-or' ) foreach @perms;
                        push @terms, \@blog_terms if @blog_terms;
                    }
                    @streams = ( {iter => $class->load_iter(
                        \@terms,
                        \%args
                    ) } );
                }

                # Pull out the head of each iterator
                # Next: effectively mergesort the various iterators
                # To call the iterator n times takes time in O(bn)
                #   with 'b' the number of blogs
                # we expect to hit the iterator l/p times where 'p' is the
                #   prob. of the search term appearing and 'l' is $limit
                $_->{head} = $_->{iter}->() foreach @streams;
                if ( $type ne 'template' ) {
                    $iter = sub {

                        # find the head with greatest created_on
                        my $which = \$streams[0];
                        foreach my $iter (@streams) {
                            next
                              if !exists $iter->{head}
                              || !$which
                              || !${$which}->{head}
                              || !defined( $iter->{head} );
                            if ( $iter->{head}->created_on >
                                ${$which}->{head}->created_on )
                            {
                                $which = \$iter;
                            }
                        }

                        # Advance the chosen one
                        my $result = ${$which}->{head};
                        ${$which}->{head} = ${$which}->{iter}->() if $result;
                        $result;
                    };
                }
                else {
                    $iter = sub {
                        return undef unless @streams;

                        # find the head with greatest created_on
                        my $which = \$streams[0];
                        while ( @streams && ( !defined ${$which}->{head} ) ) {
                            shift @streams;
                            last unless @streams;
                            $which = \$streams[0];
                        }
                        my $result = ${$which}->{head};
                        ${$which}->{head} = ${$which}->{iter}->() if $result;
                        $result;
                    };
                }
            }
        }
        my $i = 1;
        my %replace_cols;
        if ($do_replace) {
            %replace_cols = map { $_ => 1 } @{ $api->{replace_cols} };
        }

        my $re;
        if (($search || '') ne '') {
            $re = eval { qr/$search/ };
            if ( my $err = $@ ) {
                return $app->error(
                    $app->translate( "Error in search expression: [_1]", $@ ) );
            }
        }
        while ( my $obj = $iter->() ) {
            next unless $author->is_superuser || $api->{perm_check}->($obj);
            my $match = 0;
            unless ($show_all) {
                for my $col (@cols) {
                    next if $do_replace && !$replace_cols{$col};
                    my $text = $obj->column($col);
                    $text = '' unless defined $text;
                    if ($do_replace) {
                        if ( $text =~ s!$re!$replace!g ) {
                            $match++;
                            $obj->$col($text);
                        }
                    }
                    else {
                        $match = $search ne '' ? $text =~ m!$re! : 1;
                        last if $match;
                    }
                }
            }
            if ( $match || $show_all ) {
                push @to_save, $obj if $do_replace && !$show_all;
                push @data, $obj;
            }
            last if ( $limit ne 'all' ) && @data > $limit;
        }
        if (@data) {
            $param{have_results} = 1;

            # We got one extra to see if there were more
            if ( ( $limit ne 'all' ) && @data > $limit ) {
                $param{have_more} = 1;
                pop @data;
            }
            $matches = @data;
        }
        else {
            $matches = 0;
        }
    }
    my $replace_count = 0;
    for my $obj (@to_save) {
        $replace_count++;
        $obj->save
          or return $app->error(
            $app->translate( "Saving object failed: [_2]", $obj->errstr ) );
    }
    if (@data) {
        if ($quicksearch) {
            my $obj;
            if (1 == scalar @data) {
                ($obj) = @data;
            }
            elsif (defined $quicksearch_id) {
                ($obj) = grep { $_->id == $quicksearch_id } @data;
            }

            if ($obj) {
                my %args = (
                    _type         => $type,
                    id            => $obj->id,
                    search_result => 1,
                );
                $args{blog_id} = $obj->blog_id
                    if $obj->has_column('blog_id');
                my $mode = 'view';
                if ( $type eq 'blog' || $type eq 'website' ) {
                    $args{blog_id} = delete $args{id};
                    $mode = 'cfg_prefs';
                }
                return $app->redirect($app->uri(
                    mode => $mode,
                    args => \%args,
                ));
            }
        }

        if (my $meth = $search_api->{$type}{handler}) {
            $meth = $app->handler_to_coderef($meth);
            $meth->($app, items => \@data, param => \%param, type => $type );
        } else {
            my $meth = 'build_' . $type . '_table';
            if ( $app->can($meth) ) {
                $app->$meth( items => \@data, param => \%param, type => $type );
            }
            else {
                my @objects;
                push @objects, { object => $_ } for @data;
                $param{object_loop} = \@objects;
            }
        }
        $param{object_type} = $type;
        if ( exists $api->{results_table_template} ) {
            my $tmpl = _load_template( $app, $api->{results_table_template},
                exists( $api->{plugin} ) ? $api->{plugin} : undef );
            $param{results_template} = $tmpl;
        }
        else {
            $param{results_template} = _default_results_table_template($app, $type, 1, $class->class_label_plural);
        }
    }
    else {
        if ( exists $api->{no_results_template} ) {
            my $tmpl = _load_template( $app, $api->{no_results_template},
                exists( $api->{plugin} ) ? $api->{plugin} : undef );
            $param{results_template} = $tmpl;
        }
        else {
            $param{results_template} = _default_results_table_template($app, $type, 0, $class->class_label_plural);
        }
    }
    if ($is_dateranged) {
        ( $datefrom_year, $datefrom_month, $datefrom_day ) =
          $datefrom =~ m/^(\d\d\d\d)(\d\d)(\d\d)/;
        ( $dateto_year, $dateto_month, $dateto_day ) =
          $dateto =~ m/^(\d\d\d\d)(\d\d)(\d\d)/;
    }
    my %res = (
        error => $q->param('error') || '',
        limit => $limit,
        limit_all => $limit eq 'all',
        count_matches  => $matches,
        replace_count  => $replace_count,
        "search_$type" => 1,
        search_label   => $class->class_label_plural,
        object_label => $class->class_label,
        object_label_plural => $class->class_label_plural,
        object_type    => $type,
        search         => ($do_replace ? $q->param('orig_search')
        : $q->param('search')) || '',
        searched => (
            $do_replace ? $q->param('orig_search')
            : ( $do_search && $q->param('search') ne '' )
          )
          || $show_all || defined $publish_status || $my_posts,
        replace            => $replace,
        do_replace         => $do_replace,
        case               => $case,
        datefrom_year      => $datefrom_year,
        datefrom_month     => $datefrom_month,
        datefrom_day       => $datefrom_day,
        dateto_year        => $dateto_year,
        dateto_month       => $dateto_month,
        dateto_day         => $dateto_day,
        is_regex           => $is_regex,
        is_limited         => $is_limited,
        is_dateranged      => $is_dateranged,
        is_junk            => $is_junk,
        can_search_junk    => ( $type eq 'comment' || $type eq 'ping' ),
        can_replace        => $search_api->{$type}{can_replace},
        can_search_by_date => $search_api->{$type}{can_search_by_date},
        quick_search       => 0,
        "tab_$tab"         => 1,
        %param
    );
    $res{'tab_junk'} = 1 if $is_junk;
    
    my $search_cols = $search_api->{$type}{search_cols};
    my %cols = map { $_ => 1 } @cols;
    my @search_cols;
    for my $field (keys %$search_cols) {
        my %search_field;
        $search_field{field}    = $field;
        $search_field{selected} = 1 if exists($cols{$field});
        $search_field{label}    = 'CODE' eq ref($search_cols->{$field})
          ? $search_cols->{$field}->()
          : exists( $search_api->{$type}{plugin} )
            ? $search_api->{$type}{plugin}->translate($search_cols->{$field})
            : $app->translate($search_cols->{$field});
        push @search_cols, \%search_field;
    }
    $res{'search_cols'} = \@search_cols;
    \%res;
}

sub _default_results_table_template {
    my $app = shift;
    my ($type, $results, $plural) = @_;
    if ($results) {
        $type = 'blog'if $type eq 'website';
        return "<mt:include name=\"include/${type}_table.tmpl\">";
    }
    else {
        return <<TMPL;    
        <mtapp:statusmsg
                id="no-$plural"
                class="info">
                <__trans phrase="No [_1] were found that match the given criteria." params="$plural">
            </mtapp:statusmsg>
        </mt:if>
TMPL
    }
}

sub _load_template {
    my $app = shift;
    my ( $tmpl, $plugin ) = @_;

    my $meth;
    if ( ref $tmpl eq 'HASH' ) {
        $meth = $tmpl->{handler} || $tmpl->{code};
    }
    elsif ( $tmpl =~ m/^\$(\w+)::/ ) {
        $meth = $tmpl;
    }
    $tmpl = $app->handler_to_coderef($meth) if $meth;
    if ( ref $tmpl eq 'CODE' ) {
        $tmpl = $tmpl->($plugin || $app, @_);
    }
    if ($tmpl !~ /\s/) {
        # no spaces in $tmpl; must be a filename...
        my $tmpl_obj;
        if ( $plugin ) {
            $tmpl_obj = $plugin->load_tmpl($tmpl);
        }
        else {
            $tmpl_obj = $app->load_tmpl($tmpl);
        }
        if ( $tmpl_obj ) {
            $tmpl = $tmpl_obj->text;
        }
    }
    return $tmpl;
}

1;
