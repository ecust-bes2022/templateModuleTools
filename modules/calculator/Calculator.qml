import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Calculator 1.0

Item {
    id: root
    
    property string currentExpression: "0"
    
    Component.onCompleted: {
        console.log("Calculator component loaded")
    }
    
    Rectangle {
        anchors.fill: parent
        color: "white"
        
        Calculator {
            id: calculator
            
            Component.onCompleted: {
                console.log("Calculator created")
            }
        }
        
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 10
            
            TextField {
                id: display
                Layout.preferredWidth: 200
                text: root.currentExpression
                readOnly: true
                horizontalAlignment: Text.AlignRight
                font.pixelSize: 20
            }
            
            TextField {
                id: resultDisplay
                Layout.preferredWidth: 200
                text: calculator ? calculator.result : "0"
                readOnly: true
                horizontalAlignment: Text.AlignRight
                font.pixelSize: 16
                color: "gray"
            }
            
            GridLayout {
                id: buttonGrid
                columns: 4
                rowSpacing: 5
                columnSpacing: 5
                
                property var buttons: [
                    "C", "(", ")", "/",
                    "7", "8", "9", "*",
                    "4", "5", "6", "-",
                    "1", "2", "3", "+",
                    "0", "00", ".", "="
                ]
                
                Repeater {
                    model: buttonGrid.buttons
                    Button {
                        text: modelData
                        Layout.preferredWidth: 45
                        Layout.preferredHeight: 45
                        
                        onClicked: {
                            if (text === "=") {
                                calculator.calculate(root.currentExpression)
                                root.currentExpression = calculator.result
                            } 
                            else if (text === "C") {
                                root.currentExpression = "0"
                                calculator.clear()
                            }
                            else {
                                if (root.currentExpression === "0" || root.currentExpression === "错误") {
                                    root.currentExpression = text
                                } else {
                                    root.currentExpression += text
                                }
                            }
                        }
                    }
                }
            }
        }
    }
} 