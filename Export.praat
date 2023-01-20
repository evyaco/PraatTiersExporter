form 1. Export Tiers: create .csv files based on Praat tiers (version 1.0)
	comment Select a sound file and its TextGrid and specify the following tier numbers in it:
	comment Note: If there is no speakers tier, leave 0
	integer SpeakersTier: 0
	natural UtterancesTier: 3 
	comment Note: If there is no words tier, leave 0, and words will be automatically formulated.
	integer wordsTier: 0
	natural SegmentsTier: 5
	comment Choose a session name (any combination of latin characters and digits)
	text sessionName: TEST
	comment Session date (not mandatory) must be in format DD.MM.YYYY
	text sessionDate: 08.08.2022
	comment Choose an output path (make sure it exists):
	folder outputPath c:\PraatExportedTiers\
endform

if length(sessionName$) = 0
	exitScript: "Session must have a name"
elif index_regex(sessionName$, "^[0-9a-zA-Z]+$") = 0
	exitScript: "Session name must consist of latin characters and/or digits"
endif

if length(sessionDate$) > 0
	if index_regex(sessionDate$, "^(0[1-9]|[12][0-9]|3[01])\.(0[1-9]|1[012])\.(19\d{2}|20[0-9]{2})$") = 0
		exitScript: "Session date must match DD.MM.YYYY format"
	endif
endif

textGridId = selected("TextGrid")
soundFileId = selected("Sound")
select 'textGridId'
numOfSegments = Get number of intervals... 'SegmentsTier'
numOfUtterances = Get number of intervals... 'UtterancesTier'

useWordsTier = 0
if (wordsTier > 0)
	numOfWords = Get number of intervals... 'wordsTier'
	printline Num of words is 'numOfWords'
	useWordsTier = 1
endif

printline Num of segments is 'numOfSegments'

outputPath$ = outputPath$ + "\\" + sessionName$
createFolder: outputPath$
outputPath$ = replace$(outputPath$, "\", "\\", 0) + "\\"
utterancesTableFile$ = outputPath$ + "\utterances.csv"
wordsTableFile$ = outputPath$ + "\words.csv"
segmentsTableFile$ = outputPath$ + "\segments.csv"
speakersTableFile$ = outputPath$ + "\speakers.csv"
sessionTableFile$ = outputPath$ + "\session.csv"
deleteFile: utterancesTableFile$
deleteFile: wordsTableFile$
deleteFile: segmentsTableFile$
deleteFile: speakersTableFile$
deleteFile: sessionTableFile$

select 'soundFileId'
sessionDuration$ = Get total duration
sessionDuration$ = replace$(sessionDuration$, " seconds", "", 0)
object_info$ = Info
sessionFile$ = extractLine$(object_info$, "Object name: ")
sessionFile$ = replace$(sessionFile$, "Object name: ", "", 0) + ".wav"
sessionFileFullPath$ = outputPath$ + sessionFile$
Save as WAV file: sessionFileFullPath$


appendFileLine: sessionTableFile$, sessionName$ + "," + sessionDate$ + "," + sessionDuration$ + "," + sessionFile$

# ADJUSTED FOR EASY HEBREW (e.g. ʁ̞ = ʁ = R = r)
# CHANGE IT WHEN SUPPORT ALL IPA
phonemesTableID = Read Table from tab-separated file... PhonemesTable.Table

speakersIndex = 1
currWordIndex = 0
prevWordIndex = 0
currWord$ = ""
currWordStart$ = ""
currWordEnd$ = ""

saveSoundsScript$ = "TmpSaveSoundFiles.praat"
deleteFile: saveSoundsScript$

# for saving script
appendFileLine: saveSoundsScript$, "select 'soundFileId'"
appendFileLine: saveSoundsScript$, "Edit"
appendFileLine: saveSoundsScript$, "editor: 'soundFileId'"

select 'soundFileId'
Edit

for currUtteranceIndex to numOfUtterances
	select 'textGridId'
	currUtterance$ = Get label of interval... 'UtterancesTier' 'currUtteranceIndex' 
	currUtteranceStart$ = Get start time of interval... 'UtterancesTier' 'currUtteranceIndex'
	currUtteranceStart$ = fixed$(number(replace$(currUtteranceStart$, " seconds", "", 0)), 3)
	currUtteranceEnd$ = Get end time of interval... 'UtterancesTier' 'currUtteranceIndex'
	currUtteranceEnd$ = fixed$(number(replace$(currUtteranceEnd$, " seconds", "", 0)), 3)
	currUtteranceDuration$ = fixed$(number(currUtteranceEnd$) - number(currUtteranceStart$), 3)


	segmentIndexInUtterance = 1
	currWord$ = ""
	currWordStart$ = currUtteranceStart$

	if 'SpeakersTier' > 0
		currSpeaker$ = Get label of interval... 'SpeakersTier' 'currUtteranceIndex'
	else
		currSpeaker$ = "XXX"
	endif
	
	text$ = ""
	if fileReadable(speakersTableFile$)
		text$ = readFile$ (speakersTableFile$)
	endif

	speakerSearchString$ = "," + currSpeaker$
	if index(text$, speakerSearchString$) = 0
		printline text is 'text$' and search string is 'speakerSearchString$'
		currSpeakerIndex = speakersIndex
		speakers[currSpeaker$] = currSpeakerIndex
		appendFileLine: speakersTableFile$, string$(speakersIndex) + "," + currSpeaker$
		speakersIndex = speakersIndex + 1
	else
		currSpeakerIndex = speakers[currSpeaker$]
	endif
	
	# diacritics (ordered by IPA table): n̥s̬tʰɔ̹ɔ̜u̟e̠ëe̽n̩e̯a˞b̤b̰t̼tʷtʲtˠtˤɫe̝e̞e̘e̙t̪t̺t̻ẽdⁿdˡd̚
	currUtterance$ = replace_regex$(currUtterance$, "̥|̬|ʰ|̹|̜|̟|̠|̈|̽|̩|̯|˞|̤|̰|̼|ʷ|ʲ|ˠ|ˤ|̴|̝|̞|̘|̙|̪|̺|̻|̃|ⁿ|ˡ|̚", "", 0)

	# suprasegmentals (order by IPA table): ˈˌeːeˑĕ|‖.͡‿
	currUtterance$ = replace_regex$(currUtterance$, "ˈ|ˌ|ː|ˑ|̆|||‖|.|͡‿", "", 0)
	
	# for saving script
	appendFileLine: saveSoundsScript$, "Select... 'currUtteranceStart$' 'currUtteranceEnd$'"
	utteranceFileName$ = "utterance" + string$('currUtteranceIndex') + ".wav"
	utteranceFileFullPath$ = outputPath$ + utteranceFileName$
	appendFileLine: saveSoundsScript$, "Save selected sound as WAV file... 'utteranceFileFullPath$'"
	appendFileLine: utterancesTableFile$, string$('currUtteranceIndex') + "," + currUtterance$ + "," + currUtteranceStart$ + "," + currUtteranceEnd$ + 
		... "," + currUtteranceDuration$ + "," + string$(currSpeakerIndex) + "," + utteranceFileName$ + ","
	# TODO add it before currUtteranceStart$ when UTF8 problem is solved: currUtterance$

	currTime = number(currUtteranceStart$) + 0.01
	currSegment$ = ""
	currSegmentLength = 0
	nextNextSegment$ = ""
	nextSegment$ = ""

	while currTime < number(currUtteranceEnd$)

		prevSegment$ = currSegment$
		prevSegmentLength = currSegmentLength

		select 'textGridId'
		currSegmentIndex = Get interval at time... 'SegmentsTier' currTime
		currSegment$ = Get label of interval... 'SegmentsTier' 'currSegmentIndex'
		currSegmentStart$ = Get start time of interval... 'SegmentsTier' 'currSegmentIndex'
		currSegmentStart$ = fixed$(number(replace$(currSegmentStart$, " seconds","", 0)), 3)
		currSegmentEnd$ = Get end time of interval... 'SegmentsTier' 'currSegmentIndex'
		currSegmentEnd$ = fixed$(number(replace$(currSegmentEnd$, " seconds","", 0)), 3)
		currSegmentDuration$ = fixed$(number(currSegmentEnd$) - number(currSegmentStart$), 3)

		currWordEnd$ = currSegmentEnd$
		

		
		# skip spaces between words
		if currSegment$ <> " " and currSegment$ <> "	"
			#printline segment before replaces is 'currSegment$'

			# whitespaces + irrelevant punctutations: ',.
			currSegment$ = replace_regex$(currSegment$, " |	|\n|\t|\r|'|,|\.|_|-|'", "", 0)

			# diacritics (ordered by IPA table): n̥s̬tʰɔ̹ɔ̜u̟e̠ëe̽n̩e̯a˞b̤b̰t̼tʷtʲtˠtˤɫe̝e̞e̘e̙t̪t̺t̻ẽdⁿdˡd̚
			currSegment$ = replace_regex$(currSegment$, "̥|̬|ʰ|̹|̜|̟|̠|̈|̽|̩|̯|˞|̤|̰|̼|ʷ|ʲ|ˠ|ˤ|̴|̝|̞|̘|̙|̪|̺|̻|̃|ⁿ|ˡ|̚", "", 0)

			# suprasegmentals (order by IPA table): ˈˌeːeˑĕ|‖.͡‿
			currSegment$ = replace_regex$(currSegment$, "ˈ|ˌ|ː|ˑ|̆|||‖|.|͡‿", "", 0)

			#printline segment after replaces is 'currSegment$'
		endif

		if currSegment$ <> ""

			if index_regex (currSegment$, "\[.*]") > 0
				segmentType$ = "DISFLUENT"
				currSegment$ = replace_regex$(currSegment$, "\[|:|\]","", 0)
			elif index_regex (currSegment$, "\<.*\>") > 0
				segmentType$ = "NOISE"
				currSegment$ = replace_regex$(currSegment$, "\<|:|\>","", 0)
			elif currSegment$ = "@"
				segmentType$ = "NOISE"
				currSegment$ = ""
			else
				segmentType$ = "FLUENT"
				currSegment$ = replace_regex$(currSegment$, ":","", 0)
			endif

			if (currSegmentIndex + 1 < numOfSegments)
				nextSegment$ = Get label of interval... 'SegmentsTier' 'currSegmentIndex' + 1
				nextSegment$ = replace_regex$(nextSegment$, "\[|:|\]","", 0)
				nextSegment$ = replace_regex$(nextSegment$, "\<|:|\>","", 0)
				nextSegment$ = replace_regex$(nextSegment$, ":","", 0)

				nextNextSegment$ = Get label of interval... 'SegmentsTier' 'currSegmentIndex' + 2
				nextNextSegment$ = replace_regex$(nextNextSegment$, "\[|:|\]","", 0)
				nextNextSegment$ = replace_regex$(nextNextSegment$, "\<|:|\>","", 0)
				nextNextSegment$ = replace_regex$(nextNextSegment$, ":","", 0)
			endif
			
			if currSegment$ <> " "

				if (useWordsTier = 0)
					currWord$ = currWord$ + currSegment$
				else
					prevWordIndex = currWordIndex
					currWordIndex = Get interval at time... 'wordsTier' currTime
					currWord$ = Get label of interval... 'wordsTier' currWordIndex
					currWordStart$ = Get start time of interval... 'wordsTier' 'currWordIndex'
					currWordStart$ = fixed$(number(replace$(currWordStart$, " seconds","", 0)), 3)
					currWordEnd$ = Get end time of interval... 'wordsTier' 'currWordIndex'
					currWordEnd$ = fixed$(number(replace$(currWordEnd$, " seconds","", 0)), 3)
				endif

				editor: soundFileId

					#printline starts at 'currSegmentStart$' and ends at 'currSegmentEnd$'
					Select... 'currSegmentStart$' 'currSegmentEnd$'
					segmentFileName$ = "utterance" + string$('currUtteranceIndex') + "_word" + string$('currWordIndex') + 
						... "_segment" + string$('currSegmentIndex') + ".wav"
					segmentFileFullPath$ = outputPath$ + segmentFileName$
					Save selected sound as WAV file... 'segmentFileFullPath$'
					Zoom to selection
					
					currSegF1$ = Get first formant
					currSegF1$ = replace$(currSegF1$, " Hz (mean F1 in SELECTION)", "", 0)
					if currSegF1$ = "--undefined--"
						currSegF1$ = "0.0"
					endif
					currSegF1$ = fixed$(number(currSegF1$), 3)

					currSegF2$ = Get second formant
					currSegF2$ = replace$(currSegF2$, " Hz (mean F2 in SELECTION)", "", 0)
					if currSegF2$ = "--undefined--"
						currSegF2$ = "0.0"
					endif
					currSegF2$ = fixed$(number(currSegF2$), 3)

					currSegF3$ = Get third formant
					currSegF3$ = replace$(currSegF3$, " Hz (mean F3 in SELECTION)", "", 0)
					if currSegF3$ = "--undefined--"
						currSegF3$ = "0.0"
					endif
					currSegF3$ = fixed$(number(currSegF3$), 3)
					
					currSegF4$ = Get fourth formant
					currSegF4$ = replace$(currSegF4$, " Hz (mean F4 in SELECTION)", "", 0)
					if currSegF4$ = "--undefined--"
						currSegF4$ = "0.0"
					endif
					currSegF4$ = fixed$(number(currSegF4$), 3)

					currSegPitch$ = Get pitch
					currSegPitch$ = replace$(currSegPitch$, " Hz (mean pitch in SELECTION)", "", 0)
					if currSegPitch$ = "--undefined--"
						currSegPitch$ = "0.0"
					endif
					currSegPitch$ = fixed$(number(currSegPitch$), 3)

				endeditor

				select 'phonemesTableID'
				phoneme_row$ = Search column... character 'currSegment$'
				phoneme_row$ = replace$(phoneme_row$, " (first row in which character is " + currSegment$, "", 0)
				phoneme_row = number(phoneme_row$)
				if phoneme_row = 0
					printline could not recognize phoneme 'currSegment$'
					 # represents a NULL phoneme in our DB
					phoneme$ = "0"
				else
					phoneme_index = Get value... phoneme_row phoneme_id
					phoneme$ = string$(phoneme_index)
				endif
				
				
				appendFileLine: segmentsTableFile$, string$('currSegmentIndex') + "," + string$('currWordIndex') + "," + phoneme$ + 
				... "," + currSegmentStart$ + "," + currSegmentEnd$ + "," + currSegmentDuration$ +
				... "," + currSegF1$ + "," + currSegF2$ + "," + currSegF3$ + "," + currSegF4$ + "," + currSegPitch$ + 
				... "," + segmentType$ + "," + segmentFileName$ + ","
				
			endif

			# HANDLING MISMATCHES BETWEEN UTTERANCE AND SEGMENT
			currSegmentLength = length(currSegment$)
			nextSegmentLength = length(nextSegment$)
			nextNextSegmentLength = length(nextNextSegment$)
			
			currCharInUtterance$ = mid$(currUtterance$, segmentIndexInUtterance, currSegmentLength)

			if ((currCharInUtterance$ <> currSegment$) and (currCharInUtterance$ <> ""))
				select 'textGridId'
				printline NOMATCH between segment and utterance: in utterance 'currCharInUtterance$' and segment is 'currSegment$', prev segment is 'prevSegment$' and next segment is 'nextSegment$'
				
				nextSegmentFirstChar$ = left$(nextSegment$, 1)
				prevSegmentFirstChar$ = left$(prevSegment$, 1)
				nextCharInUtterance$ = mid$(currUtterance$, segmentIndexInUtterance + currSegmentLength, 1)
				nextNextCharInUtterance$ = mid$(currUtterance$, segmentIndexInUtterance + currSegmentLength + 1, 1)
				prevCharInUtterance$ = mid$(currUtterance$, segmentIndexInUtterance - prevSegmentLength, 1)

				if (currCharInUtterance$ = nextSegment$)
					printline utterance matches NEXT segment: 'nextSegment$', so we freeze in place
					segmentIndexInUtterance = segmentIndexInUtterance - currSegmentLength
				elif (currCharInUtterance$ = prevSegment$)
					printline utterance matches PREVIOUS segment: 'prevSegment$', so we advance utterance to current segment
					segmentIndexInUtterance = segmentIndexInUtterance + currSegmentLength
				elif (currCharInUtterance$ = nextNextSegment$)
					printline utterance matches NEXT NEXT segment: 'nextNextSegment$', so we freeze in place
					segmentIndexInUtterance = segmentIndexInUtterance - currSegmentLength
				elif (nextCharInUtterance$ = currSegment$)
					printline next utterance character matches segment: 'nextCharInUtterance$', so we advance utterance to current segment (+1)
					segmentIndexInUtterance = segmentIndexInUtterance + 1
				elif (prevCharInUtterance$ = currSegment$)
					printline previous utterance character matches segment: 'prevCharInUtterance$', so we withdraw utterance to it (-1)
					segmentIndexInUtterance = segmentIndexInUtterance -1
				elif (nextNextCharInUtterance$ = currSegment$)
					printline NEXT NEXT utterance character matches segment: 'nextNextCharInUtterance$', so we advance utterance to current segment (+2)
					segmentIndexInUtterance = segmentIndexInUtterance + 2
				endif
			endif
			
			segmentIndexInUtterance = segmentIndexInUtterance + currSegmentLength
			currCharInUtterance$ = mid$(currUtterance$, segmentIndexInUtterance, currSegmentLength)
			#printline the inner index is 'segmentIndexInUtterance' and the char is 'currCharInUtterance$' and the segment is 'currSegment$'

			while (currCharInUtterance$ = "[") or (currCharInUtterance$ = "]") or (currCharInUtterance$ = "<") or (currCharInUtterance$ = ">") or (currCharInUtterance$ = "@") or (currCharInUtterance$ = ":")
				segmentIndexInUtterance = segmentIndexInUtterance + 1
				currCharInUtterance$ = mid$(currUtterance$, segmentIndexInUtterance, 1)
			endwhile

			# a space or end of utterance: save word
			if ((currCharInUtterance$ = " ") and (useWordsTier = 0)) or ((currWordIndex > prevWordIndex) and (useWordsTier = 1))

				if currWord$ <> ""
					#printline segment in utterance is 'segmentIndexInUtterance' and the curr seg is 'currSegment$' and the curr word is 'currWord$'
					printline WORD 'currWord$' starts at 'currWordStart$' and ends at 'currWordEnd$'

					# for saving script
					appendFileLine: saveSoundsScript$, "Select... 'currWordStart$' 'currWordEnd$'"
					wordFileName$ = "utterance" + string$('currUtteranceIndex') + "_word" + string$('currWordIndex') + ".wav"
					wordFileFullPath$ = outputPath$ + wordFileName$
					appendFileLine: saveSoundsScript$, "Save selected sound as WAV file... 'wordFileFullPath$'"

					currWordDuration$ = fixed$(number(currWordEnd$) - number(currWordStart$), 3)
					appendFileLine: wordsTableFile$, string$('currWordIndex') + "," + string$('currUtteranceIndex') + "," + currWord$ + 
						... "," + currWordStart$ + "," + currWordEnd$ + "," + currWordDuration$ + "," + wordFileName$ + ","

					if (useWordsTier = 0)
						currWordIndex = currWordIndex + 1
						currWordStart$ = currSegmentEnd$
					endif

					currWord$ = ""
				endif

				# a space should be count in the utterance tier, if it doesnt exist in the phoneme tier!
				segmentIndexInUtterance = segmentIndexInUtterance + 1
			endif
		endif

		currSegmentIndex = currSegmentIndex + 1

		if currSegmentIndex < numOfSegments
		
			select 'textGridId'
			currTimeStr$ = Get start time of interval... 'SegmentsTier' 'currSegmentIndex'
			currTimeStr$ = replace$(currTimeStr$, " seconds", "", 0)
			currTime = number(currTimeStr$) + 0.01
			#printline we are in time 'currTimeStr$' and index is 'currSegmentIndex'
			#currTime = number(replace$(currSegmentStart$, " seconds","", 0))
		else
			currTime = number(currUtteranceEnd$) + 0.01
		endif
	endwhile


	# last word of utternace / single-word utternace ??
	if (currWord$ <> "") and (useWordsTier = 0)
		#printline segment in utterance is 'segmentIndexInUtterance' and the curr seg is 'currSegment$' and the curr word is 'currWord$'
		printline LAST WORD starts at 'currWordStart$' and ends at 'currWordEnd$'

		# for saving script
		appendFileLine: saveSoundsScript$, "Select... 'currWordStart$' 'currWordEnd$'"
		wordFileName$ = "utterance" + string$('currUtteranceIndex') + "_word" + string$('currWordIndex') + ".wav"
		wordFileFullPath$ = outputPath$ + wordFileName$
		appendFileLine: saveSoundsScript$, "Save selected sound as WAV file... 'wordFileFullPath$'"
		
		currWordDuration$ = fixed$(number(currWordEnd$) - number(currWordStart$), 3)
		appendFileLine: wordsTableFile$, string$('currWordIndex') + "," + string$('currUtteranceIndex') + "," + currWord$ + 
			... "," + currWordStart$ + "," + currWordEnd$ + "," + currWordDuration$ + "," + wordFileName$ + ","

		currWordIndex = currWordIndex + 1
		currWordStart$ = currSegmentEnd$
		currWord$ = ""
	endif
endfor

editor: soundFileId
Close

select 'phonemesTableID'
Remove

appendFileLine: saveSoundsScript$, "Close"
appendFileLine: saveSoundsScript$, "endeditor"

runScript: saveSoundsScript$


procedure stripSegment .segment$

	# skip spaces between words
	if .segment$ <> " " and .segment$ <> "	"
		#printline segment before replaces is 'segment$'

		# whitespaces + irrelevant punctutations: ',.
		.strippedSegment$ = replace_regex$(.segment$, " |	|\n|\t|\r|'|,|\.|_|-|'", "", 0)

		# diacritics (ordered by IPA table): n̥s̬tʰɔ̹ɔ̜u̟e̠ëe̽n̩e̯a˞b̤b̰t̼tʷtʲtˠtˤɫe̝e̞e̘e̙t̪t̺t̻ẽdⁿdˡd̚
		.strippedSegment$ = replace_regex$(.strippedSegment$, "̥|̬|ʰ|̹|̜|̟|̠|̈|̽|̩|̯|˞|̤|̰|̼|ʷ|ʲ|ˠ|ˤ|̴|̝|̞|̘|̙|̪|̺|̻|̃|ⁿ|ˡ|̚", "", 0)

		# suprasegmentals (order by IPA table): ˈˌeːeˑĕ|‖.͡‿
		.strippedSegment$ = replace_regex$(.strippedSegment$, "ˈ|ˌ|ː|ˑ|̆|||‖|.|͡‿", "", 0)

		#printline segment after replaces is 'currSegment$'
	endif

endproc