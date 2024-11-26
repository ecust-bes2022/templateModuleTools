import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: mainWindow
    visible: true
    width: 800
    height: 600
    
    // 动态加载的属性
    property string moduleTitle: "未设置标题"
    property url modulePath: ""
    
    title: moduleTitle
    
    Loader {
        id: moduleLoader
        anchors.fill: parent
        source: modulePath
        
        onStatusChanged: {
            if (status === Loader.Error) {
                console.error("模块加载失败:", modulePath)
            }
        }
    }
} 