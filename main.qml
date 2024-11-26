import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: window
    visible: true
    width: 800
    height: 600
    title: "工具集合"
    
    property var moduleLoader: null
    property var loadedComponents: ({})  // 用于缓存已加载的组件
    
    Component.onCompleted: {
        moduleLoader = moduleLoaderInstance
    }
    
    RowLayout {
        anchors.fill: parent
        spacing: 0
        
        Rectangle {
            Layout.preferredWidth: 200
            Layout.fillHeight: true
            color: "#f0f0f0"
            
            ListView {
                anchors.fill: parent
                model: window.moduleLoader ? window.moduleLoader.moduleList : []
                delegate: ItemDelegate {
                    width: parent.width
                    height: 40
                    
                    Label {
                        anchors.fill: parent
                        anchors.margins: 10
                        text: modelData.name
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    ToolTip.visible: hovered
                    ToolTip.text: modelData.description
                    
                    onClicked: {
                        if (window.moduleLoader) {
                            var modulePath = modelData.path
                            var moduleName = modulePath.split('/').pop()
                            var qmlFile = modulePath + "/" + moduleName.charAt(0).toUpperCase() + moduleName.slice(1) + ".qml"
                            
                            // 如果模块未加载，先加载模块
                            if (!loadedComponents[qmlFile]) {
                                if (window.moduleLoader.loadModule(modulePath)) {
                                    // 创建并缓存组件
                                    var component = Qt.createComponent(qmlFile)
                                    if (component.status === Component.Ready) {
                                        loadedComponents[qmlFile] = component.createObject(stackView)
                                    }
                                }
                            }
                            
                            // 显示对应的组件
                            if (loadedComponents[qmlFile]) {
                                stackView.replace(loadedComponents[qmlFile])
                            }
                        }
                    }
                }
            }
        }
        
        StackView {
            id: stackView
            Layout.fillWidth: true
            Layout.fillHeight: true
            initialItem: Rectangle {
                color: "white"
                Label {
                    anchors.centerIn: parent
                    text: "请选择要使用的工具"
                }
            }
            
            // 禁用StackView的默认动画
            pushEnter: Transition { }
            pushExit: Transition { }
            popEnter: Transition { }
            popExit: Transition { }
        }
    }
} 