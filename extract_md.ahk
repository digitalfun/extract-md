/*
The MIT License (MIT)
Copyright (c) 2012 Florian Schmid "digitalfun"

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

/*md*
<div class="mdfile">
file: *extract_md.ahk*
---------------------------
> Type: _AutoHotkey_ (Version 1.0.48.05)-b
> **file version:** 1.2-b
> License: [MIT](http://www.opensource.org/licenses/mit-license.php/)

*******************

> **project:** Extract Markdown (MD) code from files-b
> **author:** Florian SCHMID-b
> **company:** private-b
> **added in project version:** 1.0-b

*******************

###history
* v1.2 2012-05-19: fixed bug: reference links didnt work when the path or filename contained a space.
* v1.1 2012-05-19: fixed bug with BLOCK_LINE didnt remove the last char.
* v1.0 2012-05-16: initial-b
initial release

###description
Scriptlanguage: [AutoHotkey](http://www.autohotkey.com/ "AutoHotkey homepage").-b

The aim of this tool is to extract [Markdown][link_md] textblocks
from files and merge them into a single file.-b
The file can then be processed by a tool like [Pandoc][link_pandoc] to convert it from Markdown into a HTML page for example.

###Usage
1. Setup the INI-file to fit your needs -b
2. drag and drop the file(s) onto the .exe -b
3. enter the name of the project (= level 1 header) -b
4. enter the name of the output-file -b


####The INI-Configuration file
The **INI-File** looks like this:-b
**Filename:** *\<Name of .exe or .ahk file>.ini* -b

	[SETUP]
	BLOCK_START=<string>
	BLOCK_LINE=<string>
	BLOCK_END=<string>
	CUSTOM_BR=<string>
	BLOCK_SEP=<string>
	FILE_SEP=<string>
	OUTPUT=<filename>

#####Details
`BLOCK_START` -b
Tag to identify the **start** of a block. -b
 *standard value:* &#47;\*md -b
 
`BLOCK_LINE` -b
If a line inside the block starts with this string it will be removed from the line.-b
 *standard value:* (empty) -b
 
`BLOCK_END` -b
Tag to identify the **end** of a block. -b
 *standard value:* \*&#47; -b
 
`CUSTOM_BR` -b
If this tag is found, it will be replaced with 2 space-characters. (inducing a line-break)-b
 *standard value:* &#45;b -b
 
`BLOCK_SEP` -b
Tag that will be used to seperate 2 blocks in the output md-file.-b
 *standard value:* (empty) -b
 
`FILE_SEP` -b
Tag that will be used to seperate 2 files in the output md-file.-b
 *standard value:* ******************* -b
 
`OUTPUT` -b
Default filename in the file-selection dialog.-b
 *standard value:* output.md -b
 
_**Tip:** to use "space" in a tag, surround the string with quotation marks (")_

[link_md]: http://daringfireball.net/projects/markdown/ "Markdown Homepage"
[link_pandoc]: http://johnmacfarlane.net/pandoc/ "Pandoc Homepage"

</div>
*/




;------------------------------
; Script Settings
;------------------------------
#SingleInstance force
; The word FORCE skips the dialog box and replaces the old instance automatically, which is similar in effect to the Reload command.

SetWorkingDir %A_ScriptDir%
; to get a consistent path for the directory where the script is run.


;------------------------------
; Application settings
;------------------------------

APPNAME			:= "extract-md"
VERSION			:= "1.2"
MARKDOWN_BR 	:= "  "

;these settings may be overwritten by the INI-file settings.
TEXTBLOCK_START := "/*md"
TEXTBLOCK_LINE  :=""
TEXTBLOCK_END   := "*/"
CUSTOM_BR	:= "-b"
OUTPUTBLOCK_SEP := ""
FILE_SEP := "*******************"
OUTPUTFILENAME := "output.md"
PROJECTNAME := "project"


MainSub:

	filesCount = %0% ;number of files dropped

	if( filesCount = 0)
	{
		;Msgbox with Exclamation mark (48)
		MsgBox, 48, Error, Please drop a file on me!
		ExitApp
	}
	
	Gosub LoadSettings

	;------------------------------
	; User input: Projectname
	;------------------------------
	InputBox, UserInput, %APPNAME% %VERSION%, Please enter the name of the project:,,,,,,,,%PROJECTNAME%
	if ErrorLevel ;clicked [CANCEL]
	{
		ExitApp		
	}
	
	else ; clicked [OK]
	{
		PROJECTNAME := UserInput		
	}

	
	;------------------------------
	; User input: filename 
	;------------------------------
	InputBox, UserInput, %APPNAME% %VERSION%, Please enter the filename of the outputfile:,,,,,,,,%OUTPUTFILENAME%
	if ErrorLevel ;clicked [CANCEL]
	{
		ExitApp		
	}
	
	else ; clicked [OK]
	{
		OUTPUTFILENAME := UserInput		
	}

	;------------------------------
	; store the full path+filename of the dropped file(s)
	; into array "Files"
	;------------------------------
	Loop %filesCount%  ; For each parameter (or file dropped onto a script):
	{
		GivenPath := %A_Index%  ; Fetch the contents of the variable whose name is contained in A_Index.
		Loop %GivenPath%, 1
			LongPath = %A_LoopFileLongPath%
		Files%A_Index% := LongPath
	}

	;------------------------------
	; add header H1 "Projectname"
	;------------------------------
	if( PROJECTNAME <> "") 
	{
		sContent = <h1 class="mdprojectname">%PROJECTNAME%</h1>`n
	}

	;------------------------------
	; loop files and collect the MD content
	;------------------------------
	Loop %filesCount%  
	{
		sFilename :=  Files%A_Index%
		SplitPath, sFilename, sFileNameNoPath
		sTemp := extractMD( sFilename)
		
		;add file-div (incl. referenced link)
		sContent = %sContent%<div class="mdfilename">file: [%sFileNameNoPath%][filelink_%A_Index%]`n%sTemp%`n</div>`n%FILE_SEP%`n`n
	}

	;------------------------------
	; add link references at end of outputfile
	;------------------------------
	;markdown link refers format: [filelink_X]: http://google.com/    "Google"
	;
	sLinks = 
	Loop %filesCount%  
	{
		sFilename :=  Files%A_Index%
		SplitPath, sFilename, sFileNameNoPath

		; Replace all spaces with "%20"
		sSpaceReplace := "%20"
		StringReplace, sFilename, sFilename, %A_SPACE%, %sSpaceReplace%, All

		; Create link-entry
		sLinks = %sLinks%`n[filelink_%A_Index%]: file:///%sFilename%    "%sFileNameNoPath%"`n
		
	}
	sContent := sContent . "`n`n" . sLinks



	;------------------------------
	; create the outputfile
	;------------------------------
	sFilename :=  Files1
	SplitPath, sFilename, , sFileDir
	sFileMD := sFileDir . "\" . OUTPUTFILENAME
	FileDelete, %sFileMD%
	FileAppend, %sContent%, %sFileMD%	



Return



/*md*
<div class="mdfunction">
subroutine: *LoadSettings*
---------------------------
> **syntax:** *LoadSettings*-b
> **version:** 1.0

*******************

> **author:** Florian SCHMID-b
> **added in project version:** 1.0

*******************

###parameters

###returns

###description
Loads custom user settings from INI-file.-b

###usage
	Gosub LoadSettings

###info
For more information about the INI format, look in the File description.-b

</div> 
*/

LoadSettings:
	;INI-Filename: <name of .exe or .ahk>.ini
	SplitPath, A_ScriptName, , , , sIniFileNameNoExt, 
	sINIFilename = %A_WorkingDir%\%sIniFileNameNoExt%.ini
		
	IniRead, TEXTBLOCK_START, %sINIFilename%, SETUP, BLOCK_START, %TEXTBLOCK_START%
	IniRead, TEXTBLOCK_LINE, %sINIFilename%, SETUP, BLOCK_LINE, %TEXTBLOCK_LINE%
	IniRead, TEXTBLOCK_END, %sINIFilename%, SETUP, BLOCK_END, %TEXTBLOCK_END%
	IniRead, OUTPUTBLOCK_SEP, %sINIFilename%, SETUP, BLOCK_SEP, %OUTPUTBLOCK_SEP%
	IniRead, FILE_SEP, %sINIFilename%, SETUP, FILE_SEP, %FILE_SEP%
	IniRead, CUSTOM_BR, %sINIFilename%, SETUP, CUSTOM_BR, %CUSTOM_BR%
	IniRead, OUTPUTFILENAME, %sINIFilename%, SETUP, OUTPUT, %OUTPUTFILENAME%
	IniRead, PROJECTNAME, %sINIFilename%, SETUP, PROJECT, %PROJECTNAME%
Return



/*md*
<div class="mdfunction">
function: *extractMD*
---------------------------
> **syntax:** *extractMD( in_sFile) : string*-b
> **version:** 1.1

*******************

> **author:** Florian SCHMID-b
> **added in project version:** 1.0

*******************

###parameters
* _[in]_ in_sFile : string-b
The file containing the MD-code to extract.

###returns
* string-b
Returns the extracted MD-codeblock.-b
Start-, Line and End-tags are removed.
Also the custom BRs are replaced.

###description

###usage
	sMD = extractMD( "file.js" )
sMD contains the extracted MD-codeblock.

###info

</div>
*/
extractMD( in_sFile ) 
{
	global TEXTBLOCK_START
	global TEXTBLOCK_LINE
	global TEXTBLOCK_END

	global OUTPUTBLOCK_SEP
	global CUSTOM_BR
	global MARKDOWN_BR
	
	FileRead, sFileContent, %in_sFile%
	nLinetag_len := StrLen( TEXTBLOCK_LINE)
	nBreaktag_len := StrLen( CUSTOM_BR)
	

	sMDContent = 
	
	if not ErrorLevel  ; Successfully loaded.
	{
		
		;loop as long as a MD block is found
		nPosStart := InStr( sFileContent, TEXTBLOCK_START, false, 1)
		while nPosStart
		{
			
			nPosStart := nPosStart +StrLen( TEXTBLOCK_START)
			nPosEnd := InStr( sFileContent, TEXTBLOCK_END, false, nPosStart)
			sNewBlock = 
			
			if nPosEnd ;get md-block from STARTPOS to ENDPOS (without start/end tags)
			{
				nPosEnd := nPosEnd -StrLen( TEXTBLOCK_END)
				nLength := nPosEnd - nPosStart
				if( nLength) 
				{
					sNewBlock := SubStr( sFileContent, nPosStart, nLength) 
					sMDContent := sMDContent . sNewBlock
				}
			}
		
			else ; or if no endtag found get everything from STARTPOS until end of file
			{
				sNewBlock := SubStr( sFileContent, nPosStart) 
				sMDContent := sMDContent . sNewBlock
				Return ""
			}
			
			;
			; remove trailing tags (=TEXTBLOCK_LINE)
			; from each line
			;
			sMDContent_new =
			
			;loop line by line and remove BLOCK_LINEs 
			; and replace CUSTOM_BR tags
			;       %A_Index% : Line number 
			;       %A_LoopField% : content
			Loop, parse, sMDContent, `n, `r 
			{
				;if line start with tag, remove tag
				sLine := A_LoopField
				
				;check for Linetag
				if nLinetag_len 
				{
					sLineStart := SubStr( sLine, 1, nLinetag_len)
					; -> found!
					if( sLineStart == TEXTBLOCK_LINE)
					{
						sLine := SubStr( sLine, nLinetag_len +1)
					}	
				}
			
				;check for: custom BR-tag
				if nBreaktag_len
				{
					_length := 1 - nBreaktag_len
					sLineEnd := SubStr( sLine, _length)
					
					;-> found!
					if( sLineEnd == CUSTOM_BR)
					{
						_length := StrLen( sLine) -nBreaktag_len
						sLine := SubStr( sLine, 1, _length)
						sLine :=  sLine . MARKDOWN_BR
					}	
				}
			
			sMDContent_new := sMDContent_new . "`n" . sLine
			
			
			} ;loop
		
			sMDContent := sMDContent_new
			sMDContent_new =
			
			;add block to result
			sMDContent := sMDContent . "`n`n" . OUTPUTBLOCK_SEP . "`n`n"
		
		
			;find next block
			nPosStart := InStr( sFileContent, TEXTBLOCK_START, false, nPosEnd)
		} ;end while
		
	
		; Free the memory.
		sFileContent =  
	}	

Return sMDContent
} 
;end extractMD()
