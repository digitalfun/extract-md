Version 1.8
===========
Date of release: 2013-10-31

* removed block-level-HTML-tags (table,div,p...) because it is **not** supported by the official [Markdown-Syntax](http://daringfireball.net/projects/markdown/syntax)! 
 
 > **Markdown syntax:**
 > _"Note that Markdown formatting syntax is not processed within block-level HTML tags. 
 > E.g., you can’t use Markdown-style \*emphasis\* inside an HTML block."_
 
Version 1.7
===========
Date of release: 2013-06-07

* Error message for "no file dropped" changed slightly
* when no outputfilename is set in settings.ini, suggest the filename of the first file in the dropped-file-list instead

Version 1.6
===========
Date of release: 2012-6-4

* fixed problem: PANDOC had problems and to fix it we need to add some linebreaks.
* added executable.
* file encoding converted to UTF-8.

Version 1.5
===========
Date of release: 2012-5-31

* fixed issue #9: removed unnecessary emptylines and linebreaks from resulting output md-file.

Version 1.4
===========
Date of release: 2012-10-22

* added issue #10: auto-linebreak option.

* fixed issue #8: removing chars preceding the TEXTBLOCK_END-tag.


Version 1.3
===========
Date of release: 2012-06-19

* fixed bug: leading spaces didn't work when using the BLOCK_LINE-tag.

Version 1.2
===========
Date of release: 2012-05-21

* fixed bug: reference links didnt work when the path or filename contained a space.


Version 1.1
===========
Date of release: 2012-05-19

* fixed bug with BLOCK_LINE didnt remove the last char.

--------------------------------------------

END OF FILE
