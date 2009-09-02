<?php
# Movable Type (r) Open Source (C) 2001-2009 Six Apart, Ltd.
# This program is distributed under the terms of the
# GNU General Public License, version 2.
#
# $Id: class.mt_comment.php 106007 2009-07-01 11:33:43Z ytakayama $

require_once("class.baseobject.php");

/***
 * Class for mt_comment
 */
class Comment extends BaseObject
{
    public $_table = 'mt_comment';
    protected $_prefix = "comment_";
    protected $_has_meta = true;

    public function commenter() {
        $commenter_id = $this->comment_commenter_id;

        if (empty($commenter_id) || !is_numeric($commenter_id))
            return;

        require_once('class.mt_author.php');
        $author = new Author;
        $author->Load("author_id = $commenter_id");
        return $author;
    }
}

// Relations
ADODB_Active_Record::ClassHasMany('Comment', 'mt_comment_meta','comment_meta_comment_id');	
