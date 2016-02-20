//=============================================================================
//  MuseScore
//  Linux Music Score Editor
//  $Id:$
//
//  Count Notes plugin
//
//  Copyright (C)2011 Mike Magatagan
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License version 2.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
//=============================================================================

//
// This is ECMAScript code (ECMA-262 aka "Java Script")
//
var g_pitch = [];   // Pitch array

var g_form;             // Dialog
var g_bells = 0;        // Number of Bells used
var g_sharps = 0;       // Number of Sharps used
var g_flats = 0;        // Number of Flats used
var g_minOctave = 99;   // Lowest Octave used
var g_maxOctave = 0;    // Highest Octave used
var g_minPitch = 0;     // Lowest Pitch used
var g_maxPitch = 0;     // Highest Pitch used

// Array with the note information used for output
//
var g_notes = ["N/A", "Fbb", "Cbb", "Gbb", "Dbb", "Abb", "Ebb", "Bbb",
                      "Fb",  "Cb",  "Gb",  "Db",  "Ab",  "Eb",  "Bb",
                      "F",   "C",   "G",   "D",   "A",   "E",   "B",
                      "F#",  "C#",  "G#",  "D#",  "A#",  "E#",  "B#",
                      "F##", "C##", "G##", "D##", "A##", "E##", "B##"];

//---------------------------------------------------------
//    init
//    this function will be called on startup of mscore
//---------------------------------------------------------

function init()
      {
      // print("test script init");
      }

//-------------------------------------------------------------------
//    run
//    this function will be called when activating the
//    plugin menu entry
//
//    global Variables:
//    pluginPath - contains the plugin path; file separator is "/"
//-------------------------------------------------------------------

function run()
      {
      var cursor = new Cursor(curScore);
      for (idx = 0; idx < 127; idx++) g_pitch[idx] = 0;
      for (var staff = 0; staff < curScore.staves; ++staff) {
            cursor.staff = staff;
            for (var v = 0; v < 4; v++) {
                  cursor.voice = v;
                  cursor.rewind();  // set cursor to first chord/rest

                  while (!cursor.eos()) {
                        if (cursor.isChord()) {
                              var chord = cursor.chord();
                              var n     = chord.notes;
                              for (var i = 0; i < n; i++) {
                                  var note = chord.note(i);
                                  var pitch = note.pitch;
                                  var tone = note.tpc;
                                  g_pitch[pitch] = tone + 2;    // Allow for -1 and 0 in Tonal Pitch Class
                                  }
                              }
                        cursor.next();
                        }
                  }
            }
            Save();
      }

function Save() {
          var idx, unit;

          // Open a file selection dlg
          //
          var fName = QFileDialog.getSaveFileName(g_form, "Select .txt file to create", "C:\\Temp\\", "TXT file (*.txt)", 0);
          if (fName == null || fName == "") return;

          // Open data file as a text stream
          //
          var file = new QFile(fName);
          if (file.exists()) file.remove();
          if (!file.open(QIODevice.ReadWrite)) {
              QMessageBox.critical(g_form, "File Error", "Could not create output file " + fName);
              return;
          }
          var textStream = new QTextStream(file);
          textStream.writeString("Notes Used:" + "\r\n");

          for (idx = 0; idx < 127; idx++) {
              if (!g_pitch[idx]) continue;

              if (!g_minPitch) g_minPitch = idx;
              g_maxPitch = idx;

              var octave = 0;
              if (idx < 12)         octave = 0;
              else if (idx < 24)    octave = 1;
              else if (idx < 36)    octave = 2;
              else if (idx < 48)    octave = 3;
              else if (idx < 60)    octave = 4;
              else if (idx < 72)    octave = 5;
              else if (idx < 84)    octave = 6;
              else if (idx < 96)    octave = 7;
              else if (idx < 108)   octave = 8;
              else if (idx < 120)   octave = 9;
              else octave = 10;

              if (octave) {
                  g_bells++;
                  if (g_pitch[idx] < 15) g_flats++;
                  if (g_pitch[idx] > 21) g_sharps++;
                  if (octave < g_minOctave) g_minOctave = octave;
                  if (octave > g_maxOctave) {
                      g_maxOctave = octave;
                      textStream.writeString("\r\n");
                  }
              }

              textStream.writeString(g_notes[g_pitch[idx]] + octave + "\r\n");
          }

          textStream.writeString("\r\n" + ((g_maxOctave - g_minOctave) + 1) + " octaves with " + g_bells + " bells used ranging from " + g_notes[g_pitch[g_minPitch]] + g_minOctave + " to " + g_notes[g_pitch[g_maxPitch]] + g_maxOctave + " with " + g_flats +" flats and " + g_sharps + " sharps\r\n");

          file.close();
      };

//---------------------------------------------------------
//    menu:  defines were the function will be placed
//           in the MuseScore menu structure
//---------------------------------------------------------

var mscorePlugin = {
      menu: 'Plugins.Notes.Count Notes',
      init: init,
      run:  run
      };

mscorePlugin;

