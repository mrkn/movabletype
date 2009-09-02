<?php
# Movable Type (r) Open Source (C) 2001-2009 Six Apart, Ltd.
# This program is distributed under the terms of the
# GNU General Public License, version 2.
#
# $Id: block.mtsetvars.php 106007 2009-07-01 11:33:43Z ytakayama $

function smarty_block_mtsetvars($args, $content, &$ctx, &$repeat) {
    // parameters: name, value
    if (isset($content)) {
        $vars =& $ctx->__stash['vars'];
        if (!is_array($vars)) {
            $vars = array();
            $ctx->__stash['vars'] =& $vars;
        }
        $pairs = preg_split('/\r?\n/', trim($content));
        foreach ($pairs as $line) {
            list($var, $value) = preg_split('/\s*=/', $line, 2);
            if (isset($var) && isset($value)) {
                $vars[trim($var)] = $value;
            }
        }
    }
    return '';
}
?>
