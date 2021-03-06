#!/usr/bin/perl
use strict;
use warnings;
use lib qw( t/lib lib extlib ../lib ../extlib );

BEGIN {
    $ENV{MT_CONFIG} = 'mysql-test.cfg';
}

use MT::Test qw(:db :data);
use Test::More qw( no_plan );
use YAML::Tiny;
use File::Spec;
use FindBin qw( $Bin );
use MT;

use YAML;
my $mt = MT->new();

use_ok('MT::Theme', 'use MT::Theme');

## building test themes.
my $data;
{
    local $/ = undef;
    $data = (YAML::Tiny::Load(<DATA>))[0];
}
$mt->component('core')->registry->{themes} = $data;

## create theme instance.
my $theme;
ok($theme = MT::Theme->load('MyTheme'), 'Load theme instance');

my $blog;
ok($blog = MT->model('blog')->load(1));

my ($errors, $warnings) = $theme->validate_versions;
ok( !scalar @$errors );
ok( !scalar @$warnings );

is( $blog->allow_comment_html, 1 );
is( $blog->allow_pings,        1 );

## apply!!
ok( $theme->apply($blog), 'apply theme');

## prefs was changed by theme.
is( $blog->allow_comment_html, 0 );
is( $blog->allow_pings,        0 );

## only applied template set has this.
ok(MT->model('template')->load({ blog_id => $blog->id, identifier => 'Other Utilities' }));
## and backuped templates exists.
ok( MT->model('template')->load({ blog_id => $blog->id, type => 'backup'}) );

## ============================ Tests for loading theme package
## create second theme instance.
my $theme2;
ok($theme2 = MT::Theme->_load_from_themes_directory('other_theme'), 'Load from themes directory');

is( $theme2->envelope, File::Spec->catdir( $Bin, 'themes/other_theme'));
#ok( $blog->apply_theme($theme2) );
$theme2->apply($blog);
my $atom = MT->model('template')->load({
    blog_id => $blog->id,
    type => 'index',
    name => 'Atom',
});
is( $atom->text, 'ATOMTEMPLATE BODY FOR TEST');

__DATA__
MyTheme:
    id: my_theme
    name: my_theme
    label: My Theme
    thumbnail: my_thumbnail.png
    template_set: my_existing_template_set
    elements:
        template_set:
            component: core
            importer: template_set
            label: Template set
            require: 1
            data: mtVicuna
        core_configs:
            component: core
            importer: default_prefs
            label: core configs
            require: 0
            data:
                allow_comment_html: 0
                allow_pings: 0
        default_categories:
            component: core
            importer: default_categories
            require: 1
            data:
                foo:
                    label: another_foo
                xxx:
                    label: moge
                    description: category description.
                    children:
                        yyy:
                            label: foobar
                            description: some other category.
very_old_theme:
    id: old_theme
    name: OLD Theme
    label: Old theme
    required_components:
        core: 1.0
    optional_components:
        commercial: 2.0
