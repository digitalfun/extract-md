/* TODO

[] issue #19: silent-mode
[] issue #20: auto-br problem: SeText Heading won't work
[] rename TEXTBLOCK_LINE -> TEXTBLOCK_LINESTART
[] check all @DEBUG-tags
[] check all @TODO-tags
[] remove this TODO text once all is completed
*/




/* The MIT License (MIT)
Copyright (c) 2012 Florian Schmid aka "dabyte"

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

/*md# file: `extract_md.ahk`  
> Type: AutoHotkey Script _(Compiler used: Ahk2Exe Version 1.0.48.05)_
> file encoding: UTF-8
> License: [MIT](http://www.opensource.org/licenses/mit-license.php/)
*/







/*md# project: Extract Markdown (MD) code from files
* author: Florian SCHMID
* company: private
* version: 1.9
*/





/*md## History 

> format: `v<MAJOR>.<MINOR> @<YYYY>-<MM>-<DD>: <DESCRIPTION>`

* v1.9 @2014-05-19: Re-write code and comments; 

* v1.8 2013-07-05: remove block-level-HTML-tags (table,div,p...) because it is **not** supported by the official Markdown-Syntax! 

 > _"Note that Markdown formatting syntax is not processed within block-level HTML tags. 
 > E.g., you can’t use Markdown-style \*emphasis\* inside an HTML block."_

* v1.7 2013-06-07: when no outputfilename is set in settings, use filename of dropped file instead
* v1.6 2013-06-04: insert some linebreaks because **PANDOC** had problems. (even though other converters worked)
* v1.5 2013-05-31: fixed issue #9: removed a lot of empty lines and linebreaks from the output md-file.
* v1.4 2012-10-20: added: appname and versionNo. to errormessage if no file dropped.
* v1.4 2012-10-17: added issue #10: auto linebreak (AUTO_BR).
* v1.4 2012-10-17: fixed issue #8: dont remove chars preceding BLOCK_END-tag.
* v1.3 2012-06-19: fixed bug: ignore leading spaces when looking for BLOCK_LINE.
* v1.2 2012-05-19: fixed bug: reference links didnt work when the path or filename contained a space.
* v1.1 2012-05-19: fixed bug with BLOCK_LINE didnt remove the last char.
* v1.0 2012-05-16: initial
initial release

Description
-------------------
**Language:** [AutoHotkey script](http://www.autohotkey.com/ "AutoHotkey homepage").

The aim of this tool is to extract [Markdown][link_md] textblocks
from files and merge them into a single file.
The file can then be processed by a tool like [Pandoc][link_pandoc] to convert it from Markdown into a HTML page for example.

Usage
---------------

1. Setup the INI-file to fit your needs 
2. drag and drop the file(s) onto the .exe 
3. enter the name of the project (= level 1 header) 
4. enter the name of the output-file 


### The INI-Configuration file

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

#### Details

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

;------------------------------
; other settings
;------------------------------
MARKDOWN_BR 	:= "  "

;------------------------------
; User settings
;------------------------------
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


;------------------------------
; other global variables
;------------------------------
Files = ;pseudo-array to hold filenames
filesCount = ;number of files dropped/commandline parameter




/*md## subroutine `MainSub`
Mainloop of the application.

### remarks
_none_
*/
MainSub:

	filesCount = %0% ;number of files dropped

	;EXIT CONDITION: no files to work with!
	if(filesCount = 0)
	{
		;Msgbox with Exclamation mark (48)
		MsgBox, 48, %APPNAME% %VERSION% - Error, Please drop a file!
		ExitApp
	}
	
	
	Gosub LoadSettings

	;------------------------------
	; store the full path+filename of the dropped file(s)
	; into pseudo-array "Files"
	;------------------------------
	Loop %filesCount%  ; For each parameter (or file dropped onto a script):
	{
		GivenPath := %A_INDEX%  ; Fetch the contents of the variable whose name is contained in A_INDEX.
		Loop %GivenPath%, 1
			Files%A_Index% := A_LoopFileLongPath
	}

	;------------------------------
	; User input: Projectname
	;------------------------------
	InputBox, UserInput, %APPNAME% %VERSION%, Please enter the name of the project:,,,,,,,,%PROJECTNAME%
	if ErrorLevel ;-> [CANCEL]
	{
		ExitApp		
	}
	else ; -> [OK]
	{
		PROJECTNAME := UserInput		
	}

	
	;------------------------------
	; User input: filename 
	;------------------------------
	;if not filename set in settings,
	;use name of the first file in the list of dropped files
	;------------------------------
	if( OUTPUTFILENAME = "") {
		OUTPUTFILENAME := Files1
		SplitPath, OUTPUTFILENAME, , , , sOutNameNoExt
		OUTPUTFILENAME := sOutNameNoExt . ".md"
	}	
	
	InputBox, UserInput, %APPNAME% %VERSION%, Please enter the filename of the outputfile:,,,,,,,,%OUTPUTFILENAME%
	if ErrorLevel ;-> [CANCEL]
	{
		ExitApp		
	}
	else ; -> [OK]
	{
		OUTPUTFILENAME := UserInput
	}


	;@DEBUG: include ADD_HEADER=0|1 in settings.ini
	
	;------------------------------
	; add header "Projectname"
	;------------------------------
	if( PROJECTNAME <> "") 
	{
		sContent = <header><div class="md_header"><b>%PROJECTNAME%</b></div></header>`n
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
	;add links (only if exist)
	if( sLinks != "" ) {
		sContent := sContent . "`n" . sLinks
	}


	;------------------------------
	; create the outputfile
	;------------------------------
	sFilename := Files1
	SplitPath, sFilename, , sFileDir
	sFileMD := sFileDir . "\" . OUTPUTFILENAME
	FileDelete, %sFileMD%
	FileAppend, %sContent%, %sFileMD%	
Return



/*md## subroutine `LoadSettings`
Loads custom user settings from INI-file.

### remarks
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





/*md## function `extractMD ( in_sFile : string ) : string`

Extract Markdown-blocks from a given file.

### parameters

`in_sFile : string`  
The filename of the file that contains the MD-blocks to extract.

### return `string`
All the extracted blocks concenated.

### remarks
- Removes the Start-, Line- and End-tags
- replaces custom linebreaks with markdown line-break

### examples
    sMD := extractMD("file.js")
sMD contains the extracted MD-blocks.

### related
_none_
*/
extractMD(in_sFile) 
{
	global TEXTBLOCK_START
	global TEXTBLOCK_LINE
	global TEXTBLOCK_END

	global OUTPUTBLOCK_SEP
	global CUSTOM_BR
	global MARKDOWN_BR
	global AUTO_BR

	;locals
	ErrorCode = 
	nLinetag_len := StrLen(TEXTBLOCK_LINE) ;@DEBUG needed?
	nBreaktag_len := StrLen(CUSTOM_BR) ;@DEBUG needed?

	StartPos := 0  ;@DEBUG needed?
	FileContent := ""   ;@DEBUG needed?
	BlockContent := "" 
	
	; @DEBUG -> make functions:
	; 1. extract all text between start- and end-tags
	;    -> ExtractBlock ( in_FileName, ByRef out_Block) : int (errorcode)
	;
	; from AutoHotKey-help:
	; > When passing large strings to a function, **ByRef** enhances performance 
	; > and conserves memory by avoiding the need to make a copy of the string.
	; > Similarly, using ByRef to send a long string back to the caller 
	; > usually performs better than something like Return HugeString.
	;
	;
	; 2. loop line by line: 
	; ...


	; load content from file
	FileRead, FileContent, %in_sFile%
	;EXIT CONDITION: failed to load file content
	if ERRORLEVEL
	{
		return "ERROR"
	}
	
	;----------------------------------------------------
	; LOOP
	; Collect all MD-Block contents in variable
	;
	; Info:
	; InStr(Haystack, Needle, CaseSensitive = false, StartingPos = 1):
	;-------------------------------------------------------
	StartPos := InStr(FileContent, TEXTBLOCK_START, false, 1)
	while StartPos
	{
		
		StartPos := StartPos +StrLen(TEXTBLOCK_START) ;advance position to exclude the start-tag (we only want the content between the tags)
		EndPos := InStr(FileContent, TEXTBLOCK_END, false, StartPos) ;find position of end-tag
		
		;get md-block from STARTPOS to ENDPOS (without start/end tags)
		if EndPos 
		{
			nLength := EndPos - StartPos
			if( nLength) 
			{
				sNewBlock := SubStr( FileContent, StartPos, nLength) 
				MDContent := MDContent . "`n" . sNewBlock . "`n"
			}
		}

		; or if no endtag found get everything from STARTPOS until end of file
		else
		{
			sNewBlock := SubStr( FileContent, StartPos) 
			MDContent := MDContent . "`n" . sNewBlock . "`n"
		}
		
		;find next block
		EndPos := EndPos +StrLen( TEXTBLOCK_END)
		StartPos := InStr( FileContent, TEXTBLOCK_START, false, EndPos)
		if StartPos
		{
			if( OUTPUTBLOCK_SEP != "") {
				MDContent := MDContent . OUTPUTBLOCK_SEP . "`n"
			}
		}	

		sNewBlock := "" ; free memory
	} ;end: while block is found	

	FileContent = ;free memory




	;-------------------------------------
	; parse line by line:
	; - remove BLOCK_LINEs 
	; - replace CUSTOM_BR tags with markdown line-break (2 space characters)
	;
	; INFO
	;-------
	; ``Loop, Parse, InputVar, Delimiters, OmitChars``
	;       ``%A_Index%`` : Line number 
	;       ``%A_LoopField%`` : content
	;-------------------------------------
	MDContent_new := ""
	loop, parse, BlockContent, `n, `r 
	{
		sLine := A_LOOPFIELD

		;remove leading/trailing spaces to remove TAB etc
		;when checking for empty line
		sLineNew = %sLine%
		
		;CONTINUTE LOOP CONDITION: line is empty 
		;->add newline char and continue loop
		if (sLineNew = "")	{
			MDContent_new := MDContent_new . "`n"
			continue
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
			bCustomBRUsed := false
			
			;-> found!
			if( sLineEnd == CUSTOM_BR) { ; "==" -> case-sensitive
				_length := StrLen( sLine) -nBreaktag_len
				sLine := SubStr( sLine, 1, _length)
				sLine :=  sLine . MARKDOWN_BR
				bCustomBRUsed := True
			}	
		}
		
		;-> add linebreak if AUTO-BR flag is set (and CUSTOM-BR was not used)
		if( bCustomBRUsed = false and AUTO_BR = 1) {
			sLine := sLine . MARKDOWN_BR
		}
	
		;append line to textblock
		MDContent_new := MDContent_new . sLine . "`n"	
	} ;loop content line-by-line

	MDContent := MDContent_new
	MDContent_new := "" ;free memory
	
	;append textblock to result
	MDContent := MDContent . OUTPUTBLOCK_SEP . "`n"
	

	; Free the memory
	MDContent_new := ""

	return sMDContent
} 
;end extractMD()
