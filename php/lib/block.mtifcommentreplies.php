<?php
# Movable Type (r) Open Source (C) 2001-2009 Six Apart, Ltd.
# This program is distributed under the terms of the
# GNU General Public License, version 2.
#
# $Id: block.mtifcommentreplies.php 106007 2009-07-01 11:33:43Z ytakayama $

function smarty_block_mtifcommentreplies($args, $content, &$ctx, &$repeat) {
    if (!isset($content)) {
        $comment = $ctx->stash('comment');
        $args['comment_id'] = $comment->comment_id;
        $children = $ctx->mt->db()->fetch_comment_replies($args);
        return $ctx->_hdlr_if($args, $content, $ctx, $repeat, count($children));
    } else {
        return $ctx->_hdlr_if($args, $content, $ctx, $repeat);
    }
}
?>
