from modules.calculator.calculator import Calculator, register_types as register_calculator
from modules.serial.serial import SerialHandler, register_types as register_serial

"""
无UI模块测试
"""
def test_calculator():
    print("测试计算器模块...")
    calc = Calculator()
    calc.calculate("1 + 2")
    print(f"计算结果: {calc.result}")
    
def test_serial():
    print("\n测试串口模块...")
    serial = SerialHandler()
    print(f"可用串口列表: {serial.portList}")
    print(f"连接状态: {serial.isConnected}")
    
if __name__ == "__main__":
    print("开始测试编译后的模块...")
    test_calculator()
    test_serial()
    print("\n测试完成!") 