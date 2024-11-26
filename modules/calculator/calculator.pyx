from PySide6.QtQml import qmlRegisterType
from PySide6.QtCore import QObject, Property, Signal, Slot

def register_types():
    qmlRegisterType(Calculator, "Calculator", 1, 0, "Calculator")
    
def create_instance():
    return Calculator()

class Calculator(QObject):
    resultChanged = Signal()
    
    def __init__(self, parent=None):
        super().__init__(parent)
        self._result = "0"
        self._expression = ""
        print("CalculatorLogic initialized")
        
    @Property(str, notify=resultChanged)
    def result(self):
        return self._result
        
    @Slot(str)
    def calculate(self, expression):
        try:
            # 安全的表达式计算
            allowed_chars = set("0123456789+-*/.() ")
            if not all(c in allowed_chars for c in expression):
                raise ValueError("Invalid characters in expression")
                
            # 计算结果
            result = eval(expression)
            
            # 处理整数和浮点数的显示
            if isinstance(result, (int, float)):
                if result == int(result):
                    self._result = str(int(result))
                else:
                    self._result = f"{result:.8f}".rstrip('0').rstrip('.')
            else:
                raise ValueError("Invalid result type")
                
        except Exception as e:
            print(f"计算错误: {e}")
            self._result = "错误"
            
        self.resultChanged.emit()
    
    @Slot()
    def clear(self):
        self._result = "0"
        self.resultChanged.emit() 