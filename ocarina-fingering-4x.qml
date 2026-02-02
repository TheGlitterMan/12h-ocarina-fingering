// --------------------------------------------
// MuseScore plugin: 12H Ocarina Fingering
// 
// Updated for MuseScore 4.4 with QtQuick 2.2
// --------------------------------------------

import MuseScore 3.0
import QtQuick 2.2
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

MuseScore {
    menuPath: "Plugins.Ocarina Fingering";
    title: "12H Ocarina Fingering";
    version: "1.1";
    description: "Add fingering for 12 hole ocarinas to the score using a dialog box.";
    pluginType: "dialog";
    
    width:  300;
    height: 480;
    
    property real xOrg: 0.65;
    property real yOrg: 3.5;
    
    function addFingerings() {
        class FontObject {
            constructor(name, defaultSize, keyList, extrema = [" ", " "]) {
                this.fontFace = name;
                this.defaultSize = defaultSize;
                this.keyList = keyList;
                this.extrema = extrema;
            }
        }
        
        var fonts = [
            new FontObject("Ocarina TwelveH Alpha", 20, ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U"], ["Z", "Y"]),
            new FontObject("OcarinaT12Custom", 20, ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U"], ["Z", "Y"]),
            new FontObject("Open 12 Hole Ocarina 1", 20, ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U"], ["Z", "Y"]),
            new FontObject("Open 12 Hole Ocarina 2", 20, ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U"], ["Z", "Y"]),
            new FontObject("12 hole taiwanese", 35, ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "A"])
        ];
        
        var fScale = txtSize.value / 100;
        var xOff = txtXoff.value + xOrg;
        var yOff = txtYoff.value + yOrg;
        
        var startStaff, endStaff, endTick;
        var fullScore = false;
        var cursor = curScore.newCursor();
        cursor.rewind(1); 

        if (!cursor.segment) {
            fullScore = true;
            startStaff = 0;
            endStaff = curScore.nstaves - 1;
        } else {
            startStaff = cursor.staffIdx;
            cursor.rewind(2); 
            endTick = (cursor.tick === 0) ? curScore.lastSegment.tick + 1 : cursor.tick;
            endStaff = cursor.staffIdx;
        }
        
        var dFont = fonts[txtFont.currentIndex];
        var pitches = [45, 40, 50, 47, 43, 42]; 
        var octaves = chkTrue.checked ? (3 - txtType.currentIndex) : 1;
        var iPitch = pitches[txtKey.currentIndex] + (octaves * 12) + txtCust.value;
        
        curScore.startCmd();
        
        for (var staff = startStaff; staff <= endStaff; staff++) {
            for (var voice = 0; voice < 4; voice++) {
                cursor.rewind(fullScore ? 0 : 1);
                cursor.voice = voice;
                cursor.staffIdx = staff;

                while (cursor.segment && (fullScore || cursor.tick < endTick)) {
                    if (cursor.element && cursor.element.type === Element.CHORD) {
                        var graceChords = cursor.element.graceNotes;
                        for (var i = 0; i < graceChords.length; i++) {
                            cursor.add(noteToText(-2.5 * (graceChords.length - i) + xOff, yOff, graceChords[i].notes, dFont, iPitch));
                        }
                        cursor.add(noteToText(xOff, yOff, cursor.element.notes, dFont, iPitch));
                    }
                    cursor.next();
                }
            }
        }
        curScore.endCmd();
    }
    
    function noteToText(offsetX, offsetY, notes, fontObj, iPitch) {
        var text = newElement(Element.STAFF_TEXT);
        text.autoplace = true;
        text.align = Align.HCenter;
        text.placement = Element.BELOW;
        text.offsetY = offsetY;
        text.offsetX = offsetX;
        text.fontFace = fontObj.fontFace;
        text.fontSize = fontObj.defaultSize * (txtSize.value / 100);
        
        var tuning = fontObj.keyList;
        var resultText = "";
        
        for (var i = 0; i < notes.length; i++) {
            var pitch = notes[i].pitch;
            if (pitch === undefined || notes[i].tieBack) continue;
            
            var glyph = "";
            if (pitch < iPitch) glyph = fontObj.extrema[0];
            else if (pitch >= iPitch + tuning.length) glyph = fontObj.extrema[1];
            else glyph = tuning[pitch - iPitch];
            
            resultText = (i === 0) ? glyph : glyph + "\n" + resultText;
        }
        text.text = resultText;
        return text;
    }

    ScrollView {
        anchors.fill: parent
        
        ColumnLayout {
            width: parent.width - 30
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8

            Label { text: "Font Face"; font.bold: true }
            ComboBox {
                id: txtFont
                Layout.fillWidth: true
                model: ["Ocarina TwelveH Alpha", "OcarinaT12Custom", "Open 12 Hole Ocarina 1", "Open 12 Hole Ocarina 2", "12 hole taiwanese"]
            }

            Label { text: "Font Scale (%)"; font.bold: true }
            SpinBox { id: txtSize; from: 1; to: 500; value: 100; editable: true; Layout.fillWidth: true }

            Label { text: "Offsets (X / Y)"; font.bold: true }
            RowLayout {
                SpinBox { id: txtXoff; from: -50; to: 50; value: 0; editable: true; Layout.fillWidth: true }
                SpinBox { id: txtYoff; from: -50; to: 50; value: 0; editable: true; Layout.fillWidth: true }
            }

            Label { text: "Ocarina Type"; font.bold: true }
            ComboBox {
                id: txtType
                currentIndex: 1
                Layout.fillWidth: true
                model: ["Soprano", "Tenor/Alto", "Bass", "Contrabass"]
            }

            Label { text: "Key"; font.bold: true }
            ComboBox {
                id: txtKey
                model: ["C", "G", "F", "D", "Bb", "A"]
                Layout.fillWidth: true
            }

            CheckBox {
                id: chkTrue
                text: "Use true pitch"
                checked: false
            }

            Label { text: "Custom Transposition"; font.bold: true }
            SpinBox { id: txtCust; from: -24; to: 24; value: 0; editable: true; Layout.fillWidth: true }

            RowLayout {
                Layout.topMargin: 10
                Button {
                    text: "Apply"
                    highlighted: true
                    Layout.fillWidth: true
                    onClicked: addFingerings()
                }
                Button {
                    text: "Undo"
                    Layout.fillWidth: true
                    onClicked: cmd("undo")
                }
            }
        }
    }
}
