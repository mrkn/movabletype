<?php
# Movable Type (r) Open Source (C) 2001-2009 Six Apart, Ltd.
# This program is distributed under the terms of the
# GNU General Public License, version 2.
#
# $Id: function.mtentrytitle.php 106007 2009-07-01 11:33:43Z ytakayama $

function smarty_function_mtentrytitle($args, &$ctx) {
    $entry = $ctx->stash('entry');
    $title = $entry->entry_title;
    if (empty($title)) {
        if (isset($args['generate']) && $args['generate']) {
            require_once("MTUtil.php");
            $title = first_n_text($entry->entry_text, 5);
        }
    }
    return $title;
}
?>
