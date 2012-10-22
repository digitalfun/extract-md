extract-md
==========

Scriptlanguage: [AutoHotkey](http://www.autohotkey.com/ "AutoHotkey homepage").

The aim of this tool is to extract [Markdown][link_md] textblocks
from files and merge them into a single file.  
The file can then be processed by a tool like [Pandoc][link_pandoc] to convert it from Markdown into a HTML page for example.

Usage
-----
1. Setup the INI-file to fit your needs
2. drag and drop the file(s) onto the .exe
3. enter the name of the project (= level 1 header)
4. enter the name of the output-file


The INI-Configuration file
--------------------------
**Filename:** *NAME_OF_EXE*.ini  

The **INI-File** looks like this:  

	[SETUP]
	BLOCK_START=<string>
	BLOCK_LINE=<string>
	BLOCK_END=<string>
	CUSTOM_BR=<string>
	AUTO_BR=<0|1>
	BLOCK_SEP=<string>
	FILE_SEP=<string>
	OUTPUT=<filename>

Details
---------
`BLOCK_START`   
Tag to identify the **start** of a block.  
 *standard value:* &#47;\*md   

`BLOCK_LINE`   
If a line inside the block starts with this string it will be removed from the line.  
 *standard value:* (empty)   

`BLOCK_END`   
Tag to identify the **end** of a block.  
 *standard value:* \*&#47;   

`CUSTOM_BR`   
If this tag is found, it will be replaced with 2 space-characters. (inducing a line-break)  
 *standard value:* &#45;b   

`AUTO_BR`   
If this is set to __1__, it will add a line-break at the end of every line.  
__0__ : option disabled  
__1__ : option enabled  
__known issues:__ The Heading "=====" and "------" will not work anymore. Use "#" and "##" instead.  
 *standard value:* 1   

`BLOCK_SEP`   
Tag that will be used to seperate 2 blocks in the output md-file.  
 *standard value:* (empty) 
  
`FILE_SEP`   
Tag that will be used to seperate 2 files in the output md-file.  
 *standard value:* *******************   

`OUTPUT`   
Default filename in the file-selection dialog.  
 *standard value:* output.md   

[link_md]: http://daringfireball.net/projects/markdown/ "Markdown Homepage"
[link_pandoc]: http://johnmacfarlane.net/pandoc/ "Pandoc Homepage"
