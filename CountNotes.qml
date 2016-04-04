//=============================================================================
//  Count Notes Plugin
//  Copyright (C)2011 Mike Magatagan
//  port to qml: Copyright (C) 2016 Johan Temmerman (jeetee)
//  note name detection from the Note Names plugin of the MuseScore distribution
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License version 2.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//=============================================================================
import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.1
import Qt.labs.folderlistmodel 2.1
import Qt.labs.settings 1.0

import MuseScore 1.0
import FileIO 1.0


MuseScore {
	menuPath: 'Plugins.Notes.Count Notes'
	version: '2.2'
	description: 'Creates Performance notes (commonly used in Handbell Arrangements) detailing the notes used (by octave as well as Sharps and Flats used).'
	pluginType: 'dialog'
	//requiresScore: true //not supported before 2.1.0, manual checking onRun

	width:  360
	height: 90

	onRun: {
		if (!curScore) {
			console.log(qsTranslate("QMessageBox", "No score open.\nThis plugin requires an open score to run.\n"));
			Qt.quit();
		}
		directorySelectDialog.folder = ((Qt.platform.os == "windows")? "file:///" : "file://") + exportDirectory.text;
	}

	Component.onDestruction: {
		settings.exportDirectory = exportDirectory.text;
	}

	Settings {
		id: settings
		category: 'Plugins_Notes_CountNotes'
		property alias exportDirectory: exportDirectory.text
		property alias useSafeASCII: useSafeASCII.checked
	}

	FileIO {
		id: textWriter
		onError: console.log(msg)
	}

	FileDialog {
		id: directorySelectDialog
		title: qsTranslate("MS::PathListDialog", "Choose a directory")
		selectFolder: true
		visible: false
		onAccepted: {
			exportDirectory.text = this.folder.toString().replace("file://", "").replace(/^\/(.:\/)(.*)$/, "$1$2");
		}
		Component.onCompleted: visible = false
	}

	Rectangle {
		color: "lightgrey"
		anchors.fill: parent

		GridLayout {
			columns: 2
			anchors.fill: parent
			anchors.margins: 10

			Button {
				id: selectDirectory
				text: qsTranslate("PrefsDialogBase", "Browse...")
				onClicked: {
					directorySelectDialog.open();
				}
			}
			Label {
				id: exportDirectory
				text: ""
			}
			
			CheckBox {
				id: useSafeASCII
				Layout.columnSpan: 2
				text: qsTr("Use 'b' instead of '♭' and '#' instead of '♯'")
			}
			
			Button {
				id: exportButton
				Layout.columnSpan: 2
				text: qsTranslate("PrefsDialogBase", "Export")
				onClicked: {
					countNotes();
					Qt.quit();
				}
			}

		}
	}

	function countNotes()
	{
		var count = {
			flats: 0,
			sharps: 0,
			bells: 0,
			notes: []//octaves array, for each octave nest the pitches as properties
		};
		var cursor = curScore.newCursor();
		var note = null;//used in the analysis loop
		
		for (var track = curScore.ntracks; track-- > 0; ) {
			cursor.track = track;
			cursor.rewind(0);
			//loop over all chords in this track
			while (cursor.segment) {
				if (cursor.element && (cursor.element.type === Element.CHORD)) {
					//graceNotes are a chord-array
					for (var gc = cursor.element.graceNotes.length; gc-- > 0; ) {
					//each note in this graceChord
						for (note = cursor.element.graceNotes[gc].notes.length; note-- > 0; ) {
							processNoteIntoCount(cursor.element.graceNotes[gc].notes[note], count);
						}
					}
					//normal notes
					for (note = cursor.element.notes.length; note-- > 0; ) {
						processNoteIntoCount(cursor.element.notes[note], count);
					}
				}
				cursor.next();
			} //end segment loop
		}
		saveNotes(count);
	}

	function processNoteIntoCount(note, count)
	{
		var octave = Math.floor(note.ppitch / 12); //MIDI pitch to octave
		if (!count.notes[octave]) { //didn't have this octave yet
			count.notes[octave] = [];
		}
		var tpc = getTpcInfo(note.tpc); //tonal pitch class
		//check if we've already registered this note
		var i = 0;
		while ((i < count.notes[octave].length) && (count.notes[octave][i].pitch < note.ppitch)) {
			i++;
		}
		if (   (i == count.notes[octave].length)
			|| (count.notes[octave][i] && (count.notes[octave][i].pitch > note.ppitch))
			) {//last or higher pitched notes in this octave were already detected
			for (var j = count.notes[octave].length; j > i; --j) { //shift them
				count.notes[octave][j] = count.notes[octave][j - 1];
			}
			//add new note
			count.bells++;
			count.notes[octave][i] = {
				pitch: note.ppitch,
				text: tpc.text + octave
			};
			if (tpc.isFlat) {
				count.flats++;
			}
			else if (tpc.isSharp) {
				count.sharps++;
			}
		}
	}

	function getTpcInfo(tpc)
	{
		var res = {
			isFlat: (tpc < 13),
			isSharp: (tpc > 19),
			text: '-' //default case
		};
		switch (tpc) {
			case -1: res.text = qsTranslate("InspectorAmbitus", "F♭♭"); break;
			case  0: res.text = qsTranslate("InspectorAmbitus", "C♭♭"); break;
			case  1: res.text = qsTranslate("InspectorAmbitus", "G♭♭"); break;
			case  2: res.text = qsTranslate("InspectorAmbitus", "D♭♭"); break;
			case  3: res.text = qsTranslate("InspectorAmbitus", "A♭♭"); break;
			case  4: res.text = qsTranslate("InspectorAmbitus", "E♭♭"); break;
			case  5: res.text = qsTranslate("InspectorAmbitus", "B♭♭"); break;
			
			case  6: res.text = qsTranslate("InspectorAmbitus", "F♭"); break;
			case  7: res.text = qsTranslate("InspectorAmbitus", "C♭"); break;
			case  8: res.text = qsTranslate("InspectorAmbitus", "G♭"); break;
			case  9: res.text = qsTranslate("InspectorAmbitus", "D♭"); break;
			case 10: res.text = qsTranslate("InspectorAmbitus", "A♭"); break;
			case 11: res.text = qsTranslate("InspectorAmbitus", "E♭"); break;
			case 12: res.text = qsTranslate("InspectorAmbitus", "B♭"); break;
			
			case 13: res.text = qsTranslate("InspectorAmbitus", "F"); break;
			case 14: res.text = qsTranslate("InspectorAmbitus", "C"); break;
			case 15: res.text = qsTranslate("InspectorAmbitus", "G"); break;
			case 16: res.text = qsTranslate("InspectorAmbitus", "D"); break;
			case 17: res.text = qsTranslate("InspectorAmbitus", "A"); break;
			case 18: res.text = qsTranslate("InspectorAmbitus", "E"); break;
			case 19: res.text = qsTranslate("InspectorAmbitus", "B"); break;
			
			case 20: res.text = qsTranslate("InspectorAmbitus", "F♯"); break;
			case 21: res.text = qsTranslate("InspectorAmbitus", "C♯"); break;
			case 22: res.text = qsTranslate("InspectorAmbitus", "G♯"); break;
			case 23: res.text = qsTranslate("InspectorAmbitus", "D♯"); break;
			case 24: res.text = qsTranslate("InspectorAmbitus", "A♯"); break;
			case 25: res.text = qsTranslate("InspectorAmbitus", "E♯"); break;
			case 26: res.text = qsTranslate("InspectorAmbitus", "B♯"); break;
			
			case 27: res.text = qsTranslate("InspectorAmbitus", "F♯♯"); break;
			case 28: res.text = qsTranslate("InspectorAmbitus", "C♯♯"); break;
			case 29: res.text = qsTranslate("InspectorAmbitus", "G♯♯"); break;
			case 30: res.text = qsTranslate("InspectorAmbitus", "D♯♯"); break;
			case 31: res.text = qsTranslate("InspectorAmbitus", "A♯♯"); break;
			case 32: res.text = qsTranslate("InspectorAmbitus", "E♯♯"); break;
			case 33: res.text = qsTranslate("InspectorAmbitus", "B♯♯"); break;
		}
		if (useSafeASCII.checked) {
			res.text = res.text.replace('♭', 'b').replace('♯', '#').replace('?', 'b'); //replace ? as well, as some translations currently already return that
		}
		return res;
	}


	function saveNotes(count)
	{
		var octaveRange = { min: 11, max: 0 };
		var crlf = "\r\n";
		var content = "Notes Used:" + crlf;
		
		for (var octave = 0; octave < count.notes.length; ++octave) {
			if (count.notes[octave] && count.notes[octave].length) {//octave is used
				content += crlf; //separate octaves with a blank line
				if (octave < octaveRange.min) {
					octaveRange.min = octave;
				}
				if (octave > octaveRange.max) {
					octaveRange.max = octave;
				}
				//save the notes of this octave
				for (var note = 0; note < count.notes[octave].length; ++note) {
					content += count.notes[octave][note].text + crlf;
				}
			}
		}
		//add summary
		content += crlf + (octaveRange.max - octaveRange.min + 1) + ' octaves with ' + count.bells + ' bells used';
		content += ' ranging from ' + count.notes[octaveRange.min][0].text;
		content += ' to ' + count.notes[octaveRange.max][count.notes[octaveRange.max].length - 1].text;
		content += ' with ' + count.flats + ' ' + ((count.flats === 1)? 'flat' : 'flats');
		content += ' and ' + count.sharps + ' ' + ((count.sharps === 1)? 'sharp' : 'sharps');
		content += crlf;
		//get filename
		var filename = (curScore.title != "")? curScore.title : Date.now();
		filename = filename.replace(/ /g, "_").replace(/"/g, "").replace(/\//g, "-").replace(/\\/g, "-").replace(/\?/g, "").replace(/!/g, "");
		filename = exportDirectory.text + "//" + filename + ".txt";
		console.log(filename);
		
		//export
		textWriter.source = filename;
		textWriter.write(content);
	}
}
