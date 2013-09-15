-- United States Format.  Might need to be corrected in order to coerce date
-- objects if your OSX locale formats dates differently.
-- Why the ISO format doesn't work I really don't want to know.
property dateFormat : "+%D %T %Z"

-- Pick our folder
set ljPath to (choose folder)

-- Make done subdirectory
set doneDir to (POSIX path of ljPath & "done/")
try
	do shell script "mkdir " & quoted form of doneDir & " >/dev/null 2>/dev/null"
end try

-- Pick a destination notebook
set notebookName to my selectNotebook()

--Make a global variable to hold our success count.

set entryFiles to paragraphs of (do shell script "ls -1 " & POSIX path of ljPath & "L-*")

repeat with f in entryFiles
	set commentFileName to my replaceChars((last item of my explode("/", f)), "L", "C")
	set commentFileFound to false
	set commentFile to missing value
	
	try
		set commentFiles to paragraphs of (do shell script "ls -1 " & POSIX path of ljPath & commentFileName)
		set commentFile to item 1 of commentFiles
		if (count of commentFiles) is greater than 1 then
			log "Something weird just happened.  I found multiple comment files for " & f
			log "Only processing first file found: " & item 1 of commentFiles
		end if
	on error
		log "No comment files found for " & f & " continuing onwardsÉ"
	end try
	
	set entryData to my parseXML(f, commentFile)
	
	my createNoteInEvernote(entryData, notebookName)
	
	my doneWithEntry(f, commentFile, doneDir)
end repeat

"DONE WITH RUN"

on doneWithEntry(entryFile, commentFile, doneDir)
	do shell script "mv " & quoted form of entryFile & " " & quoted form of doneDir
	log commentFile
	if commentFile is not equal to missing value then
		do shell script "mv " & quoted form of commentFile & " " & quoted form of doneDir
	end if
end doneWithEntry

on createNoteInEvernote(entryData, notebookName)
	local noteBody, title
	set noteBody to generateNoteBody(entryData)
	if subject of entryData is not equal to "" then
		set theTitle to subject of entryData
	else
		local theWords
		set theWords to words of body of entryData
		if (count of theWords) is greater than 8 then
			set theTitle to my implode(" ", items 1 through 8 of theWords)
		else
			set theTitle to body of entryData
		end if
	end if
	tell application "Evernote"
		local d
		set d to my makeCreateDate(createDate of entryData)
		set newNote to create note with html noteBody title theTitle notebook notebookName created d
	end tell
end createNoteInEvernote

on makeCreateDate(dateStr)
	return date (do shell script "date -j -f '%Y-%m-%d %H:%M:%S' " & quoted form of dateStr & " " & quoted form of dateFormat)
end makeCreateDate

on generateNoteBody(entryData)
	local noteBody
	set noteBody to "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">
		<html>
			<head>
				<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\"/>
			</head>
			<body>
				<table BGCOLOR=\"#36454F\" border=\"1\" width=\"100%\" cellspacing=\"2\" cellpadding=\"1\">
					<tbody>
						<tr BGCOLOR=\"#ffffff\">
							<td align=\"center\" ><font color=\"#424242\"><h4><strong>ID Number</strong></h4></td>
							<td align=\"center\"  ><h4>" & idNumber of entryData & "</h4></td>
						</tr>

						<tr BGCOLOR=\"#ffffff\">
							<td align=\"center\" ><font color=\"#424242\"><h4><strong>Date</strong></h4></td>
							<td align=\"center\" ><h4><strong>" & createDate of entryData & "</strong></h4></td>
						</tr>

						<tr BGCOLOR=\"#ffffff\">
							<td align=\"center\" ><font color=\"#424242\"><h4><strong>URL</strong></h4></td>
							<td align=\"center\" ><h4>" & theUrl of entryData & "</h4></td>
						</tr>

						<tr BGCOLOR=\"#ffffff\">
							<td align=\"center\" ><font color=\"#424242\"><h4><strong>Mood</strong></h4></td>
							<td align=\"center\" ><h4>" & mood of entryData & "</h4></td>
						</tr>
						
						<tr BGCOLOR=\"#ffffff\">
							<td align=\"center\" ><font color=\"#424242\"><h4><strong>Music</strong></h4></td>
							<td align=\"center\" ><h4>" & music of entryData & "</h4></td>
						</tr>
						
						<tr BGCOLOR=\"#ffffff\">
							<td align=\"center\" ><font color=\"#424242\"><h4><strong>Subject</strong></h4></td>
							<td align=\"center\" ><h4>" & subject of entryData & "</h4></td>
						</tr>
					</tbody>
				</table>
				<hr />
				<table border=\"1\" width=\"100%\" cellspacing=\"10\" cellpadding=\"10\">
					<tbody>" & body of entryData & "</tbody>
				</table>"
	if (count of (comments of entryData)) is greater than 0 then
		set noteBody to noteBody & "
				<hr />
				<h2>Comments</h2>
				<hr />"
		repeat with aComment in comments of entryData
			set noteBody to noteBody & "
				<table BGCOLOR=\"#36454F\" border=\"1\" width=\"100%\" cellspacing=\"2\" cellpadding=\"1\">
					<tbody>
						<tr BGCOLOR=\"#ffffff\">
							<td align=\"center\" ><font color=\"#424242\"><h4><strong>ID Number</strong></h4></td>
							<td align=\"center\"  ><h4>" & idNumber of aComment & "</h4></td>
						</tr>
						
						<tr BGCOLOR=\"#ffffff\">
							<td align=\"center\" ><font color=\"#424242\"><h4><strong>Parent ID</strong></h4></td>
							<td align=\"center\"  ><h4>" & parentid of aComment & "</h4></td>
						</tr>
						
						<tr BGCOLOR=\"#ffffff\">
							<td align=\"center\" ><font color=\"#424242\"><h4><strong>Date</strong></h4></td>
							<td align=\"center\"  ><h4>" & createDate of aComment & "</h4></td>
						</tr>
						
						<tr BGCOLOR=\"#ffffff\">
							<td align=\"center\" ><font color=\"#424242\"><h4><strong>User</strong></h4></td>
							<td align=\"center\"  ><h4>" & user of aComment & "</h4></td>
						</tr>
						
						<tr BGCOLOR=\"#ffffff\">
							<td align=\"center\" ><font color=\"#424242\"><h4><strong>State</strong></h4></td>
							<td align=\"center\"  ><h4>" & state of aComment & "</h4></td>
						</tr>
					</tbody>
				</table>
				<table border=\"1\" width=\"100%\" cellspacing=\"10\" cellpadding=\"10\">
					<tbody>" & body of aComment & "</tbody>
				</table>"
		end repeat
	end if
	set noteBody to noteBody & "
			</body>
		</html>"
	return noteBody
end generateNoteBody

on parseXML(entryFile, commentFile)
	local itemId, createDate, theUrl, moodId, music, post, subject, comments, mood
	
	-- Get to work.
	tell application "System Events"
		tell XML element "event" of contents of XML file (entryFile as text)
			try
				set itemId to value of XML element "itemid"
				get itemId
			on error
				set itemId to ""
			end try
			
			try
				set createDate to value of XML element "eventtime"
				get createDate
			on error
				set createDate to ""
			end try
			
			try
				set theUrl to value of XML element "url"
				get theUrl
			on error
				set theUrl to ""
			end try
			
			try
				tell XML element "props"
					try
						set mood to convertMoodId(value of XML element "current_moodid" as integer)
						get mood
					on error
						set mood to ""
					end try
					
					try
						set music to value of XML element "current_music"
						get music
					on error
						set music to ""
					end try
					
				end tell
			on error
				set mood to ""
				set music to ""
			end try
			
			try
				set post to my convertNewlineToBrTag(value of XML element "event")
				get post
			on error
				set post to ""
			end try
			
			try
				set subject to value of XML element "subject"
				get subject
			on error
				set subject to ""
			end try
		end tell
		
		set comments to {}
		
		if commentFile is not missing value then
			tell XML element "comments" of contents of XML file (commentFile as text)
				repeat with thisCommentTag in XML elements
					local cId, cSubject, cBody, cState, cUser, cParentId, cDate
					--And try to get some values.
					try
						set cId to value of XML element "id" in thisCommentTag
						get cId
					on error
						set cId to ""
					end try
					
					try
						set cSubject to value of XML element "subject" in thisCommentTag
						get cSubject
					on error
						set cSubject to ""
					end try
					
					try
						set cBody to my convertNewlineToBrTag(value of XML element "body" in thisCommentTag)
						get cBody
					on error
						set cBody to ""
					end try
					
					try
						set cState to value of XML element "state" in thisCommentTag
						get cState
					on error
						set cState to ""
					end try
					
					try
						set cUser to value of XML element "user" in thisCommentTag
						get cUser
					on error
						set cUser to ""
					end try
					
					try
						set cParentId to value of XML element "parentid" in thisCommentTag
						get cParentId
					on error
						set cParentId to ""
					end try
					
					try
						set cDate to value of XML element "date" in thisCommentTag
						get cDate
					on error
						set cDate to ""
					end try
					
					--Make the comment script object and then append it to our list of comments.
					set comment to my makeComment(cId, cSubject, cBody, cState, cUser, cParentId, cDate)
					
					copy comment to end of comments
				end repeat
			end tell
		end if
	end tell
	
	--Sort comments
	my msort(my commentsAscendingComparator_, comments)
	
	--Return our entry object.  Hazaa.
	return makeEntry(itemId, createDate, theUrl, mood, music, post, subject, comments)
end parseXML

on makeEntry(itemId, theCreateDate, thePostUrl, theMood, theMusic, postBody, postSubject, commentsList)
	script theEntry
		property idNumber : itemId
		property createDate : theCreateDate
		property theUrl : thePostUrl
		property mood : theMood
		property music : theMusic
		property body : postBody
		property subject : postSubject
		property comments : commentsList
	end script
	return theEntry
end makeEntry

on makeComment(cId, theSubject, theBody, theState, theUser, theParentid, cDate)
	script theComment
		property idNumber : cId
		property subject : theSubject
		property body : theBody
		property state : theState
		property user : theUser
		property parentid : theParentid
		property createDate : cDate
	end script
	return theComment
end makeComment

-- From http://www.macosxautomation.com/applescript/sbrt/sbrt-06.html
on replaceChars(this_text, search_string, replacement_string)
	set AppleScript's text item delimiters to the search_string
	set the item_list to every text item of this_text
	set AppleScript's text item delimiters to the replacement_string
	set this_text to the item_list as string
	set AppleScript's text item delimiters to ""
	return this_text
end replaceChars

on convertStateChar(state)
	if state is equal to "S" then return "Screened"
	if state is equal to "D" then return "Deleted"
	if state is equal to "F" then return "Frozen"
	return "Active"
end convertStateChar

on convertMoodId(id)
	if id is equal to 0 then return "pissed"
	if id is equal to 1 then return "aggravated"
	if id is equal to 2 then return "angry"
	if id is equal to 3 then return "annoyed"
	if id is equal to 4 then return "anxious"
	if id is equal to 5 then return "bored"
	if id is equal to 6 then return "confused"
	if id is equal to 7 then return "crappy"
	if id is equal to 8 then return "cranky"
	if id is equal to 9 then return "depressed"
	if id is equal to 10 then return "discontent"
	if id is equal to 11 then return "energetic"
	if id is equal to 12 then return "enraged"
	if id is equal to 13 then return "enthralled"
	if id is equal to 14 then return "exhausted"
	if id is equal to 15 then return "happy"
	if id is equal to 16 then return "high"
	if id is equal to 17 then return "horny"
	if id is equal to 18 then return "hungry"
	if id is equal to 19 then return "infuriated"
	if id is equal to 20 then return "irate"
	if id is equal to 21 then return "jubilant"
	if id is equal to 22 then return "lonely"
	if id is equal to 23 then return "moody"
	if id is equal to 25 then return "sad"
	if id is equal to 26 then return "satisfied"
	if id is equal to 27 then return "sore"
	if id is equal to 28 then return "stressed"
	if id is equal to 29 then return "thirsty"
	if id is equal to 30 then return "thoughtful"
	if id is equal to 31 then return "tired"
	if id is equal to 32 then return "touched"
	if id is equal to 33 then return "lazy"
	if id is equal to 34 then return "drunk"
	if id is equal to 35 then return "ditzy"
	if id is equal to 36 then return "mischievous"
	if id is equal to 37 then return "morose"
	if id is equal to 38 then return "gloomy"
	if id is equal to 39 then return "melancholy"
	if id is equal to 40 then return "drained"
	if id is equal to 41 then return "excited"
	if id is equal to 42 then return "relieved"
	if id is equal to 43 then return "hopeful"
	if id is equal to 44 then return "amused"
	if id is equal to 45 then return "determined"
	if id is equal to 46 then return "scared"
	if id is equal to 47 then return "frustrated"
	if id is equal to 48 then return "indescribable"
	if id is equal to 49 then return "sleepy"
	if id is equal to 51 then return "groggy"
	if id is equal to 52 then return "hyper"
	if id is equal to 53 then return "relaxed"
	if id is equal to 54 then return "restless"
	if id is equal to 55 then return "disappointed"
	if id is equal to 56 then return "curious"
	if id is equal to 57 then return "mellow"
	if id is equal to 58 then return "peaceful"
	if id is equal to 59 then return "bouncy"
	if id is equal to 60 then return "nostalgic"
	if id is equal to 61 then return "okay"
	if id is equal to 62 then return "rejuvenated"
	if id is equal to 63 then return "complacent"
	if id is equal to 64 then return "content"
	if id is equal to 65 then return "indifferent"
	if id is equal to 66 then return "silly"
	if id is equal to 67 then return "flirty"
	if id is equal to 68 then return "calm"
	if id is equal to 69 then return "refreshed"
	if id is equal to 70 then return "optimistic"
	if id is equal to 71 then return "pessimistic"
	if id is equal to 72 then return "giggly"
	if id is equal to 73 then return "pensive"
	if id is equal to 74 then return "uncomfortable"
	if id is equal to 75 then return "lethargic"
	if id is equal to 76 then return "listless"
	if id is equal to 77 then return "recumbent"
	if id is equal to 78 then return "exanimate"
	if id is equal to 79 then return "embarrassed"
	if id is equal to 80 then return "envious"
	if id is equal to 81 then return "sympathetic"
	if id is equal to 82 then return "sick"
	if id is equal to 83 then return "hot"
	if id is equal to 84 then return "cold"
	if id is equal to 85 then return "worried"
	if id is equal to 86 then return "loved"
	if id is equal to 87 then return "awake"
	if id is equal to 88 then return "working"
	if id is equal to 89 then return "productive"
	if id is equal to 90 then return "accomplished"
	if id is equal to 91 then return "busy"
	if id is equal to 92 then return "blah"
	if id is equal to 93 then return "full"
	if id is equal to 95 then return "grumpy"
	if id is equal to 96 then return "weird"
	if id is equal to 97 then return "nauseated"
	if id is equal to 98 then return "ecstatic"
	if id is equal to 99 then return "chipper"
	if id is equal to 100 then return "rushed"
	if id is equal to 101 then return "contemplative"
	if id is equal to 102 then return "nerdy"
	if id is equal to 103 then return "geeky"
	if id is equal to 104 then return "cynical"
	if id is equal to 105 then return "quixotic"
	if id is equal to 106 then return "crazy"
	if id is equal to 107 then return "creative"
	if id is equal to 108 then return "artistic"
	if id is equal to 109 then return "pleased"
	if id is equal to 110 then return "bitchy"
	if id is equal to 111 then return "guilty"
	if id is equal to 112 then return "irritated"
	if id is equal to 113 then return "blank"
	if id is equal to 114 then return "apathetic"
	if id is equal to 115 then return "dorky"
	if id is equal to 116 then return "impressed"
	if id is equal to 117 then return "naughty"
	if id is equal to 118 then return "predatory"
	if id is equal to 119 then return "dirty"
	if id is equal to 120 then return "giddy"
	if id is equal to 121 then return "surprised"
	if id is equal to 122 then return "shocked"
	if id is equal to 123 then return "rejected"
	if id is equal to 124 then return "numb"
	if id is equal to 125 then return "cheerful"
	if id is equal to 126 then return "good"
	if id is equal to 127 then return "distressed"
	if id is equal to 128 then return "intimidated"
	if id is equal to 129 then return "crushed"
	if id is equal to 130 then return "devious"
	if id is equal to 131 then return "thankful"
	if id is equal to 132 then return "grateful"
	if id is equal to 133 then return "jealous"
	if id is equal to 134 then return "nervous"
	return "Unknown Mood ID: " & id
end convertMoodId

--Sort comments
on commentsAscendingComparator_(l, r)
	if idNumber of l is less than idNumber of r then
		return false
	else
		return true
	end if
end commentsAscendingComparator_

--Sort strings
on stringComparator_(l, r)
	if l comes before r then
		return false
	else
		return true
	end if
end stringComparator_

--MergeSort algorithm hijacked from https://discussions.apple.com/thread/2752690?start=0&tstart=0
on msort(cmp_, aa) -- v1.2f2
	(*
 Basic recursive merge sort handler having list sorted in place
 *)
	(*
 handler cmp_ : comparator
 * cmp_(x, y) must return true iff list element x and y are out of order.
 list aa : list to be sorted in place
 *)
	script o
		property parent : {} -- limit closure to minimum
		property xx : aa -- to be sorted in place
		property xxl : count my xx
		property yy : {}
		property cmp : cmp_
		on merge(p, q, r)
			(*
 property xx: source list
 integer p, q, r : absolute indices to specify range to be merged such that
 xx's items p thru r is the target range,
 xx's items p thru (q-1) is the first sublist,
 xx's items q thru r is the second sublist.
 (p < q <= r)
 *)
			local i, j, k, xp, xr, yi, yj, ix, jx
			
			if r - p = 1 then
				set xp to my xx's item p
				set xr to my xx's item r
				if my cmp(xp, xr) then
					set my xx's item p to xr
					set my xx's item r to xp
				end if
				return -- exit
			else
				if p < q - 1 then merge(p, (p + q) div 2, q - 1)
				merge(q, (q + r + 1) div 2, r)
			end if
			(*
 At this point, sublits xx[p, q-1] and xx[q, r] have been already sorted (p < q <= r)
 *)
			
			if my cmp(my xx's item (q - 1), my xx's item q) then
			else -- xx[p, q-1] & xx[q, r] are already sorted
				return
			end if
			
			set yy to my xx's items p thru r -- working copy for comparison
			set ix to q - p
			set jx to r - p + 1
			set i to 1
			set j to q - p + 1
			set k to p
			set yi to my yy's item i
			set yj to my yy's item j
			repeat
				if my cmp(yi, yj) then
					set my xx's item k to yj
					set j to j + 1
					set k to k + 1
					if j > jx then
						set my xx's item k to yi
						set i to i + 1
						set k to k + 1
						repeat until k > r
							set my xx's item k to my yy's item i
							set i to i + 1
							set k to k + 1
						end repeat
						return
					end if
					set yj to my yy's item j
				else
					set my xx's item k to yi
					set i to i + 1
					set k to k + 1
					if i > ix then
						set my xx's item k to yj
						set j to j + 1
						set k to k + 1
						repeat until k > r
							set my xx's item k to my yy's item j
							set j to j + 1
							set k to k + 1
						end repeat
						return
					end if
					set yi to my yy's item i
				end if
			end repeat
		end merge
		
		local d, i, j
		if xxl ² 1 then return
		if cmp_ = {} then set my cmp to cmp -- comparator fallback
		my merge(1, (xxl + 1) div 2, xxl)
	end script
	tell o to run
end msort

-- from http://applescript.bratis-lover.net/library/string/
on implode(delimiter, pieces)
	local delimiter, pieces, ASTID
	set ASTID to AppleScript's text item delimiters
	try
		set AppleScript's text item delimiters to delimiter
		set pieces to "" & pieces
		set AppleScript's text item delimiters to ASTID
		return pieces --> text
	on error eMsg number eNum
		set AppleScript's text item delimiters to ASTID
		error "Can't implode: " & eMsg number eNum
	end try
end implode

-- from http://applescript.bratis-lover.net/library/string/
on explode(delimiter, input)
	local delimiter, input, ASTID
	set ASTID to AppleScript's text item delimiters
	try
		set AppleScript's text item delimiters to delimiter
		set input to text items of input
		set AppleScript's text item delimiters to ASTID
		return input --> list
	on error eMsg number eNum
		set AppleScript's text item delimiters to ASTID
		error "Can't explode: " & eMsg number eNum
	end try
end explode

--Lifted and adapted from this script: http://veritrope.com/code/outlook-2011-to-evernote
on selectNotebook()
	local listOfNotebooks, EVNotebooks, SelNotebook, EVnotebook
	tell application "Evernote"
		set listOfNotebooks to {} (*PREPARE TO GET EVERNOTE'S LIST OF NOTEBOOKS *)
		set EVNotebooks to every notebook (*GET THE NOTEBOOK LIST *)
		repeat with currentNotebook in EVNotebooks
			local currentNotebookName
			set currentNotebookName to (the name of currentNotebook)
			copy currentNotebookName to the end of listOfNotebooks
		end repeat
		my msort(stringComparator_, listOfNotebooks) (*SORT THE LIST *)
		set SelNotebook to choose from list of listOfNotebooks with title "Select Evernote Notebook" with prompt Â
			"Current Evernote Notebooks" OK button name "OK" cancel button name "New Notebook" (*USER SELECTION FROM NOTEBOOK LIST *)
		if (SelNotebook is false) then (*CREATE NEW NOTEBOOK OPTION *)
			set userInput to Â
				text returned of (display dialog "Enter New Notebook Name:" default answer "")
			set EVnotebook to userInput
		else
			set EVnotebook to item 1 of SelNotebook
		end if
	end tell
	return EVnotebook
end selectNotebook

--Wrote this one myself
on convertNewlineToBrTag(theText)
	local input
	set input to quoted form of theText
	return do shell script "echo " & input & " | " & Â
		"perl -p -e 's#\\n#<br />#g'"
end convertNewlineToBrTag