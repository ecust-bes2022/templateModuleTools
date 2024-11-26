from PySide6.QtQml import QQmlApplicationEngine, qmlRegisterType
from PySide6.QtCore import QObject, Slot, QUrl, QDir, Property, Signal, QThread, QThreadPool
from PySide6.QtGui import QGuiApplication
import os
import json
import importlib.util
import sys
import traceback

class ModuleInfo(QObject):
    def __init__(self, info_dict, parent=None):
        super().__init__(parent)
        self._info = info_dict
    
    @Property(str, constant=True)
    def id(self):
        return self._info.get('id', '')
    
    @Property(str, constant=True)
    def name(self):
        return self._info.get('name', '')
    
    @Property(str, constant=True)
    def path(self):
        return self._info.get('path', '')
    
    @Property(str, constant=True)
    def version(self):
        return self._info.get('version', '')
    
    @Property(str, constant=True)
    def description(self):
        return self._info.get('description', '')
    
    @Property(str, constant=True)
    def icon(self):
        return self._info.get('icon', '')

class ModuleThread(QThread):
    def __init__(self, module, parent=None):
        super().__init__(parent)
        self.module = module
        
    def run(self):
        if hasattr(self.module, 'run_in_thread'):
            self.module.run_in_thread()

class ModuleLoader(QObject):
    modulesChanged = Signal()
    
    def __init__(self):
        super().__init__()
        self.modules = {}  # 存储模块实例
        self.module_instances = {}  # 存储模块的QML实例
        self.module_threads = {}
        self.thread_pool = QThreadPool()
        self.engine = None
        self._module_list = []
        print("ModuleLoader初始化...")
        self.load_module_config()
    
    def __del__(self):
        self.cleanup()
    
    @Slot()
    def cleanup(self):
        print("清理模块加载器资源...")
        # 停止所有模块线程
        for module_path, thread in self.module_threads.items():
            try:
                if thread.isRunning():
                    thread.quit()
                    thread.wait()
                    print(f"停止模块线程: {module_path}")
            except Exception as e:
                print(f"停止模块线程出错 {module_path}: {e}")
        
        self.module_threads.clear()
        
        # 清理模块资源
        for module_path, module in self.modules.items():
            try:
                if hasattr(module, 'cleanup'):
                    module.cleanup()
            except Exception as e:
                print(f"清理模块出错 {module_path}: {e}")
        
        self.modules.clear()
        self._module_list.clear()
        self.engine = None
        print("模块加载器资源清理完成")
    
    @Property('QVariantList', notify=modulesChanged)
    def moduleList(self):
        return self._module_list
    
    def load_module_config(self):
        try:
            print("加载模块配置文件...")
            with open('modules.json', 'r', encoding='utf-8') as f:
                config = json.load(f)
                self._module_list = [
                    ModuleInfo(module_info) 
                    for module_info in config.get('modules', [])
                    if module_info.get('enabled', True)
                ]
                print(f"已加载 {len(self._module_list)} 个模块配置")
                self.modulesChanged.emit()
        except Exception as e:
            print(f"加载模块配置失败: {e}")
            traceback.print_exc()
    
    def setEngine(self, engine):
        print("设置QML引擎...")
        self.engine = engine
        
    @Slot(str, result=bool)
    def loadModule(self, module_path):
        try:
            print(f"\n开始加载模块: {module_path}")
            
            # 如果模块已经加载过，直接返回缓存的实例
            if module_path in self.module_instances:
                print(f"模块已加载: {module_path}")
                return True
                
            if module_path not in self.modules:
                if not os.path.exists(module_path):
                    print(f"创建模块目录: {module_path}")
                    os.makedirs(module_path, exist_ok=True)
                
                module_name = os.path.basename(module_path)
                print(f"模块名称: {module_name}")
                
                # 查找.so文件
                so_files = [f for f in os.listdir(module_path) if f.endswith('.so') or f.endswith('.cpython-310-darwin.so')]
                if not so_files:
                    print(f"找不到编译后的模块文件(.so): {module_path}")
                    return False
                    
                so_file = os.path.join(module_path, so_files[0])
                print(f"加载编译模块: {so_file}")
                
                try:
                    # 添加模块路径到Python路径
                    if module_path not in sys.path:
                        sys.path.append(module_path)
                        print(f"添加模块路径到sys.path: {module_path}")
                    
                    # 导入编译后的模块
                    print(f"导入模块: {module_name}")
                    module_spec = importlib.util.spec_from_file_location(module_name, so_file)
                    module = importlib.util.module_from_spec(module_spec)
                    module_spec.loader.exec_module(module)
                    
                    if hasattr(module, 'register_types'):
                        print(f"注册模块类型: {module_name}")
                        module.register_types()
                        self.modules[module_path] = module
                    else:
                        print(f"警告: 模块没有register_types函数: {module_name}")
                
                except Exception as e:
                    print(f"模块加载错误: {e}")
                    traceback.print_exc()
                    return False
                
            # 创建并缓存模块实例
            module = self.modules[module_path]
            if hasattr(module, 'create_instance'):
                print(f"创建模块实例: {module_path}")
                instance = module.create_instance()
                self.module_instances[module_path] = instance
                
                # 如果模块需要线程
                if hasattr(instance, 'needs_thread') and instance.needs_thread:
                    print(f"启动模块线程: {module_path}")
                    thread = QThread()
                    instance.moveToThread(thread)
                    self.module_threads[module_path] = thread
                    thread.started.connect(instance.start_thread)
                    thread.start()
            else:
                print(f"警告: 模块没有create_instance函数: {module_path}")
                
            print(f"模块加载完成: {module_path}\n")
            return True
                
        except Exception as e:
            print(f"模块加载错误: {e}")
            traceback.print_exc()
            return False

if __name__ == "__main__":
    try:
        app = QGuiApplication(sys.argv)
        engine = QQmlApplicationEngine()
        
        module_loader = ModuleLoader()
        module_loader.setEngine(engine)
        
        # 确保在应用退出前清理资源
        app.aboutToQuit.connect(module_loader.cleanup)
        
        # 将moduleLoader实例注册到QML上下文中
        context = engine.rootContext()
        context.setContextProperty("moduleLoaderInstance", module_loader)
        
        # 添加QML导入路径
        engine.addImportPath(".")
        engine.addImportPath(os.path.abspath("."))
        
        # 加载主QML文件
        qml_file = os.path.join(os.path.dirname(__file__), "main.qml")
        print(f"正在加载QML文件: {qml_file}")
        if not os.path.exists(qml_file):
            print(f"错误: QML文件不存在: {qml_file}")
            sys.exit(-1)
            
        engine.load(QUrl.fromLocalFile(os.path.abspath(qml_file)))
        
        # 检查QML加载状态
        if not engine.rootObjects():
            print("错误: 无法加载QML文件")
            sys.exit(-1)
            
        print("QML界面加载成功，开始运行应用...")
        sys.exit(app.exec())
        
    except Exception as e:
        print(f"程序运行出错: {e}")
        traceback.print_exc()
        sys.exit(-1)