import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Serial 1.0

Rectangle {
    id: root
    color: "#f0f0f0"
    
    SerialHandler {
        id: serialHandler
        
        onErrorOccurred: function(error) {
            if (errorDialog) {
                errorDialog.text = error
                errorDialog.open()
            }
        }
    }
    
    Dialog {
        id: errorDialog
        title: "错误"
        width: 300
        modal: true
        anchors.centerIn: parent
        
        property alias text: errorLabel.text
        
        contentItem: Label {
            id: errorLabel
            wrapMode: Text.WordWrap
            width: parent.width
        }
        
        standardButtons: Dialog.Ok
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        // 连接控制区域
        GroupBox {
            title: "串口设置"
            Layout.fillWidth: true
            
            GridLayout {
                columns: 4
                rowSpacing: 10
                columnSpacing: 10
                
                Label { text: "串口:" }
                ComboBox {
                    id: portComboBox
                    model: serialHandler ? serialHandler.portList : []
                    Layout.fillWidth: true
                }
                
                Label { text: "波特率:" }
                ComboBox {
                    id: baudComboBox
                    model: [9600, 19200, 38400, 57600, 1152000]
                    currentIndex: 4
                    Layout.fillWidth: true
                }
                
                Button {
                    id: connectButton
                    text: serialHandler && serialHandler.isConnected ? "断开" : "连接"
                    Layout.columnSpan: 2
                    Layout.fillWidth: true
                    
                    onClicked: {
                        if (!serialHandler.isConnected) {
                            serialHandler.connect_serial(portComboBox.currentText, baudComboBox.currentValue)
                        } else {
                            serialHandler.disconnect_serial()
                        }
                    }
                }
                
                Button {
                    text: "刷新"
                    Layout.columnSpan: 2
                    Layout.fillWidth: true
                    onClicked: serialHandler.refresh_ports()
                }
            }
        }

        // 发送区域
        GroupBox {
            title: "发送数据"
            Layout.fillWidth: true
            
            ColumnLayout {
                anchors.fill: parent
                
                TextArea {
                    id: sendText
                    Layout.fillWidth: true
                    Layout.preferredHeight: 80
                    placeholderText: "输入要发送的数据..."
                }
                
                Button {
                    text: "发送"
                    Layout.fillWidth: true
                    enabled: serialHandler && serialHandler.isConnected
                    onClicked: {
                        if (sendText.text.length > 0) {
                            serialHandler.send_data(sendText.text)
                        }
                    }
                }
            }
        }

        // 接收区域
        GroupBox {
            title: "接收数据"
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            ColumnLayout {
                anchors.fill: parent
                
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    
                    TextArea {
                        id: receiveText
                        readOnly: true
                        text: serialHandler ? serialHandler.receivedData : ""
                        wrapMode: TextArea.Wrap
                    }
                }
                
                Button {
                    text: "清空"
                    Layout.fillWidth: true
                    onClicked: receiveText.clear()
                }
            }
        }
    }
} 