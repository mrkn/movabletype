<?php
# Movable Type (r) Open Source (C) 2001-2009 Six Apart, Ltd.
# This program is distributed under the terms of the
# GNU General Public License, version 2.
#
# $Id: function.mtcurrentpage.php 106007 2009-07-01 11:33:43Z ytakayama $

function smarty_function_mtcurrentpage($args, &$ctx) {
    $limit = $ctx->stash('__pager_limit');
    $offset = $ctx->stash('__pager_offset');
    return $limit ? $offset / $limit + 1 : 1;
}
?>

