/*
The MIT License (MIT)
Copyright (c) 2012 Florian Schmid "digitalfun"

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

/*md*
## file: *extract_md.ahk*
> Type: _AutoHotkey_ (Compiler Ahk2Exe Version 1.0.48.05)
> **file encoding:** UTF-8
> **License:** [MIT](http://www.opensource.org/licenses/mit-license.php/)

*******************

> **project:** Extract Markdown (MD) code from files
> **author:** Florian SCHMID
> **company:** private
> **version:** 1.8

*******************

###history (yyyy.mm.dd)

* v1.8 2013-07-05: removed block-level-HTML-tags (table,div,p...) because it is **not** supported by the official Markdown-Syntax! 

 > _"Note that Markdown formatting syntax is not processed within block-level HTML tags. 
 > E.g., you can’t use Markdown-style \*emphasis\* inside an HTML block."_

* v1.7 2013-06-07: when no outputfilename is set in settings, use filename of dropped file instead
* v1.6 2013-06-04: insert some linebreaks because PANDOC had problems. (even though other converters worked)
* v1.5 2013-05-31: fixed issue #9: removed a lot of empty lines and linebreaks from the output md-file.
* v1.4 2012-10-20: added: appname and versionno. to errormessage if no file dropped.
* v1.4 2012-10-17: added issue #10: auto linebreak (AUTO_BR).
* v1.4 2012-10-17: fixed issue #8: dont remove chars preceding BLOCK_END-tag.
* v1.3 2012-06-19: fixed bug: ignore leading spaces when looking for BLOCK_LINE.
* v1.2 2012-05-19: fixed bug: reference links didnt work when the path or filename contained a space.
* v1.1 2012-05-19: fixed bug with BLOCK_LINE didnt remove the last char.
* v1.0 2012-05-16: initial
initial release

###description

**Language:** [AutoHotkey script](http://www.autohotkey.com/ "AutoHotkey homepage").

The aim of this tool is to extract [Markdown][link_md] textblocks
from files and merge them into a single file.
The file can then be processed by a tool like [Pandoc][link_pandoc] to convert it from Markdown into a HTML page for example.

###Usage

1. Setup the INI-file to fit your needs 
2. drag and drop the file(s) onto the .exe 
3. enter the name of the project (= level 1 header) 
4. enter the name of the output-file 


####The INI-Configuration file

> Filename: *\<Name of .exe or .ahk file>.ini* 

The **INI-File** looks like this:

	[SETUP]
	BLOCK_START=<string>
	BLOCK_LINE=<string>
	BLOCK_END=<string>
	CUSTOM_BR=<string>
	BLOCK_SEP=<string>
	FILE_SEP=<string>
	OUTPUT=<filename>

#####Details

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
 
`BLOCK_SEP`
Tag that will be used to seperate 2 blocks in the output md-file.
 *standard value:* (empty)
 
`FILE_SEP`
Tag that will be used to seperate 2 files in the output md-file.
 *standard value:* *******************
 
`OUTPUT`
Default filename in the file-selection dialog.
If left empty, then the filename of the first file in the dropped-file-list will be used instead.
 *standard value:* output.md 
 
[link_md]: http://daringfireball.net/projects/markdown/ "Markdown Homepage"
[link_pandoc]: http://johnmacfarlane.net/pandoc/ "Pandoc Homepage"

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
VERSION			:= "1.8"
MARKDOWN_BR 	:= "  "

;these settings may be overwritten by the INI-file settings.
TEXTBLOCK_START := "/*md"
TEXTBLOCK_LINE :=""
TEXTBLOCK_END := "*/"
CUSTOM_BR := "-b"
OUTPUTBLOCK_SEP := ""
FILE_SEP := "*******************"
OUTPUTFILENAME := "output.md"
PROJECTNAME := "project"
AUTO_BR := 1 ;0 = off, 1 = on

MainSub:

	filesCount = %0% ;number of files dropped

	if( filesCount = 0)
	{
		;Msgbox with Exclamation mark (48)
		MsgBox, 48, %APPNAME% %VERSION% - Error, Please drop a file!
		ExitApp
	}
	
	Gosub LoadSettings

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
	
	;if not filename set in settings,
	;use name of the first file in the list of dropped files
	if( OUTPUTFILENAME = "") {
		OUTPUTFILENAME := Files1
		SplitPath, OUTPUTFILENAME, , , , sOutNameNoExt
		OUTPUTFILENAME := sOutNameNoExt . ".md"
	}	
	
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
	; add header H1 "Projectname"
	;------------------------------
	if( PROJECTNAME <> "") 
	{
		sContent = <h1 class="mdprojectname">%PROJECTNAME%</h1>`n<hr />`n
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
		sContent = %sContent%file: [%sFileNameNoPath%][filelink_%A_Index%]`n%sTemp%`n%FILE_SEP%`n
	}

	;------------------------------
	; add link references at end of outputfile
	;------------------------------
	;markdown link refers format: [filelink_X]: http://google.com/    "Google"
	;
	sLinks := "" 
	Loop %filesCount%  
	{
		sFilename :=  Files%A_Index%
		SplitPath, sFilename, sFileNameNoPath

		; Replace all spaces with "%20"
		sSpaceReplace := "%20"
		StringReplace, sFilename, sFilename, %A_SPACE%, %sSpaceReplace%, All

		; Create link-entry
		sLinks = %sLinks%`n[filelink_%A_Index%]: file:///%sFilename% "%sFileNameNoPath%"
	}
	if( sLinks != "" ) {
		sContent := sContent . "`n" . sLinks
	}


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
##subroutine: *LoadSettings*
> **syntax:** *LoadSettings*
> **version:** 1.1

*******************

> **author:** Florian SCHMID
> **added in project version:** 1.0

*******************

###parameters

###returns

###description
Loads custom user settings from INI-file.

###usage
	Gosub LoadSettings

###info
For more information about the INI format, look in the File description.
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
	IniRead, AUTO_BR, %sINIFilename%, SETUP, AUTO_BR, %AUTO_BR%
	
Return



/*md*
##function: *extractMD*
> **syntax:** *extractMD( in_sFile) : string*
> **version:** 1.3

*******************

> **author:** Florian SCHMID
> **added in project version:** 1.0

*******************

###parameters
* _[in]_ in_sFile : string
The file containing the MD-code to extract.

###returns
* string
Returns the extracted MD-codeblock.
Removes the Start-, Line- and End-tags and also the custom BRs.

###description

###usage
	sMD = extractMD( "file.js" )
sMD contains the extracted MD-codeblock.

###info

*/
extractMD( in_sFile ) 
{
	global TEXTBLOCK_START
	global TEXTBLOCK_LINE
	global TEXTBLOCK_END

	global OUTPUTBLOCK_SEP
	global CUSTOM_BR
	global MARKDOWN_BR
	global AUTO_BR
	
	FileRead, sFileContent, %in_sFile%
	nLinetag_len := StrLen( TEXTBLOCK_LINE)
	nBreaktag_len := StrLen( CUSTOM_BR)
	

	sMDContent := "" 
	
	if not ErrorLevel  ; Successfully loaded.
	{
		;-------------------------------------
		;loop as long as a MD block is found
		; and collect all MD-Blocks in var sMDContent
		;-------------------------------------
		nPosStart := InStr( sFileContent, TEXTBLOCK_START, false, 1)
		while nPosStart
		{
			
			nPosStart := nPosStart +StrLen( TEXTBLOCK_START)
			nPosEnd := InStr( sFileContent, TEXTBLOCK_END, false, nPosStart)
			sNewBlock := ""
			
			if nPosEnd ;get md-block from STARTPOS to ENDPOS (without start/end tags)
			{
				nLength := nPosEnd - nPosStart
				if( nLength) 
				{
					sNewBlock := SubStr( sFileContent, nPosStart, nLength) 
					sMDContent := sMDContent . "`n" . sNewBlock . "`n"
				}
			}
		
			else ; or if no endtag found get everything from STARTPOS until end of file
			{
				sNewBlock := SubStr( sFileContent, nPosStart) 
				sMDContent := sMDContent . "`n" . sNewBlock . "`n"
			}
			
			;find next block
			nPosEnd := nPosEnd +StrLen( TEXTBLOCK_END)
			nPosStart := InStr( sFileContent, TEXTBLOCK_START, false, nPosEnd)
			if( nPosStart) {
				if( OUTPUTBLOCK_SEP != "") {
					sMDContent := sMDContent . OUTPUTBLOCK_SEP . "`n"
				}
			}	
			
		} ;end: while block is found	
	
		;-------------------------------------
		; remove leading tags (=TEXTBLOCK_LINE)
		; from each line
		;
		; loop line by line and remove BLOCK_LINEs 
		; and replace CUSTOM_BR tags
		;
		; Loop, Parse, InputVar [, Delimiters, OmitChars] 
		;       %A_Index% : Line number 
		;       %A_LoopField% : content
		;-------------------------------------
		sMDContent_new := ""
		Loop, parse, sMDContent, `n, `r 
		{
			sLine := A_LoopField

			;if emptyline, continue the loop
			if (sLine = "")	{
				sMDContent_new := sMDContent_new . "`n"
				Continue
			}	

			;remove leading/trailing spaces to remove TAB etc
			;when checking for empty line
			sLineNew = %sLine%
			if( sLineNew = "") {
				Continue
			}
			
			;check for: Line-tag
			if (nLinetag_len > 0) {
				; first, remove leading whitespaces
				; for this we append a character, use the [var1 = %var2%] method to remove leading/trailing spaces
				; but because we have added a char at the end, it will only remove the leading spaces.
				sLineNew := sLine . "x"
				sLineNew = %sLineNew%

				; extract characters (linetag-length)
				sLineStart := SubStr( sLineNew, 1, nLinetag_len)
				
				; -> found Line-tag
				if( sLineStart == TEXTBLOCK_LINE)
				{
					; remove Line-tag from the string with no whitespaces
					sLine := SubStr( sLineNew, nLinetag_len +1)
					; remove the appended char
					sLine := SubStr( sLine, 1, -1)
				}	
			}
		
			;check for: custom BR-tag
			if (nBreaktag_len > 0) {
				_length := 1 - nBreaktag_len
				sLineEnd := SubStr( sLine, _length)
				bCustomBRUsed := False
				
				;-> found!
				if( sLineEnd == CUSTOM_BR) { ; "==" -> case-sensitive
					_length := StrLen( sLine) -nBreaktag_len
					sLine := SubStr( sLine, 1, _length)
					sLine :=  sLine . MARKDOWN_BR
					bCustomBRUsed := True
				}	
			}
			
			;-> add linebreak if AUTO-BR flag is set (and CUSTOM-BR was not used)
			if( bCustomBRUsed = False and AUTO_BR = 1) {
				sLine := sLine . MARKDOWN_BR
			}
		
			;append line to textblock
			sMDContent_new := sMDContent_new . sLine . "`n"	
		} ;loop
	
		sMDContent := sMDContent_new
		sMDContent_new := "" ;free memory
		
		;append textblock to result
		sMDContent := sMDContent . OUTPUTBLOCK_SEP . "`n"
		
	
		; Free the memory
		sFileContent := ""
		sMDContent_new := ""
	}
	
	Return sMDContent
} 
;end extractMD()
