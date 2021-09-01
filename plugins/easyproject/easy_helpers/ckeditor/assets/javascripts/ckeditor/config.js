/**
 * @license Copyright (c) 2003-2018, CKSource - Frederico Knabben. All rights reserved.
 * For licensing, see https://ckeditor.com/legal/ckeditor-oss-license
 */

CKEDITOR.editorConfig = function( config )
{
    // Define changes to default configuration here. For example:
    // config.language = 'fr';
    // config.uiColor = '#AADC6E';

    config.removePlugins = 'scayt';
    config.extraPlugins = 'base64image';
    config.entities_latin = false;
    config.disableNativeSpellChecker = true;
    config.skin = 'moono';
    config.resize_enabled = true;
    config.toolbarStartupExpanded = true;
    config.toolbarCanCollapse = false;
    config.extraAllowedContent = 'blockquote table pre code big small img section a i span div; *[id](*){*}; *[class](*){*}; *[style](*){*}; *[data*](*){*}';
    config.keystrokes = [];
    config.keystrokes = [
        [ CKEDITOR.CTRL + 76, null ]                       // CTRL + L
    ];
    // config.allowedContent = true;
    config.tabSpaces = 4;
    config.toolbar_Full = [
    ['Bold','Italic','Underline','Strike','NumberedList','BulletedList','Subscript','Superscript','-','Outdent','Indent','Blockquote'],
    ['Styles','Format','Font','FontSize'],
    ['TextColor','BGColor'],
    ['JustifyLeft','JustifyCenter','JustifyRight','JustifyBlock'],
    ['Link','Unlink','Anchor'],
    ['base64image','Table','HorizontalRule','EmojiPanel','SpecialChar','-', 'ShowBlocks'],
    ['Cut','Copy','Paste','PasteText','PasteFromWord','-','Print', 'SpellChecker'],
    ['Undo','Redo','-','Find','Replace','-','SelectAll','RemoveFormat'],
    ['Source','Preview','Templates', 'CodeSnippet', 'PageBreak']
    ];

    config.toolbar_Extended = [
    ['Format'], //['Format','Font','FontSize'],
    ['Bold','Italic','Underline','Strike'],
    ['TextColor','BGColor','Link','Unlink'],
    ['JustifyLeft','JustifyCenter','JustifyRight','JustifyBlock'],
    ['NumberedList','BulletedList'],
    ['HorizontalRule'],
    ['base64image','Table','Source'], //['Table','HorizontalRule'],
    ['Cut','Copy','Paste','PasteText','PasteFromWord']
    ];

    config.toolbar_Basic = [
    ['Bold','Italic','Underline','Strike'],['TextColor','BGColor','Link','Unlink'],
    ['NumberedList','BulletedList'],['base64image','PasteFromWord','Table','Source']
    ];

    config.toolbar_Mobile = [
    ['Bold','Italic','Underline','Strike'],['TextColor','BGColor','Link','Unlink'],['base64image'],['Source']
    ];

    config.toolbar_Publishing = [
    ['Bold','Italic','Underline','Strike'],['TextColor','BGColor','Link','Unlink'],
    ['NumberedList','BulletedList'],['base64image','PasteFromWord','Table','Source']
    ];
};
