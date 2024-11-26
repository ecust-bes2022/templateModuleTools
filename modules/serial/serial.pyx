from PySide6.QtQml import qmlRegisterType
from PySide6.QtCore import QObject, Property, Signal, Slot, QTimer, QThread, QMutex, QMutexLocker
from PySide6.QtSerialPort import QSerialPort, QSerialPortInfo

def register_types():
    qmlRegisterType(SerialHandler, "Serial", 1, 0, "SerialHandler")
    
def create_instance():
    return SerialHandler()

class SerialHandler(QObject):
    portListChanged = Signal()
    connectionStateChanged = Signal()
    receivedDataChanged = Signal()
    errorOccurred = Signal(str)
    initializationCompleted = Signal()
    needs_thread = True
    
    def __init__(self, parent=None):
        super().__init__(parent)
        self._ports = []
        self._is_connected = False
        self._received_data = ""
        self._serial = QSerialPort()
        self._serial.readyRead.connect(self._on_ready_read)
        self._serial.errorOccurred.connect(self._on_error)
        self._refresh_timer = None
        self._running = False
        self._initialized = True
        self._connect_mutex = QMutex()
        
        print("串口模块初始化完成")
        self.refresh_ports()

    @Slot()
    def start_thread(self):
        self._running = True
        print("串口模块线程已启动")
        
        # 在工作线程中定期刷新端口列表
        while self._running:
            if self._serial and self._is_connected:
                self._serial.waitForReadyRead(100)
            else:
                self.refresh_ports()
                QThread.msleep(1000)  # 每秒刷新一次

    def cleanup(self):
        print("清理串口资源...")
        try:
            if hasattr(self, '_serial') and self._serial:
                if self._is_connected:
                    self.disconnect_serial()
                self._serial.deleteLater()
                self._serial = None
            if hasattr(self, '_refresh_timer') and self._refresh_timer:
                self._refresh_timer.stop()
                self._refresh_timer.deleteLater()
                self._refresh_timer = None
        except Exception as e:
            print(f"清理串口资源时发生错误: {e}")
        print("串口资源清理完成")

    def _is_usb_port(self, port_info):
        port_name = port_info.portName().lower()
        return ("usb" in port_name or "usbserial" in port_name) and port_name.startswith("cu.")

    @Property(list, notify=portListChanged)
    def portList(self):
        return self._ports

    @Property(bool, notify=connectionStateChanged)
    def isConnected(self):
        return self._is_connected

    @Property(str, notify=receivedDataChanged)
    def receivedData(self):
        return self._received_data

    @Slot()
    def refresh_ports(self):
        available_ports = QSerialPortInfo.availablePorts()
        new_ports = [
            port.portName() 
            for port in available_ports 
            if self._is_usb_port(port)
        ]
        
        if new_ports != self._ports:
            self._ports = new_ports
            self.portListChanged.emit()
            print(f"可用USB串口列表已更新: {self._ports}")

    @Slot(str, int, result=bool)
    def connect_serial(self, port_name, baud_rate):
        if not self._initialized:
            self.errorOccurred.emit("串口正在初始化，请稍后重试")
            return False
            
        if not port_name:
            self.errorOccurred.emit("请选择串口")
            return False
            
        try:
            if self._is_connected:
                self.disconnect_serial()
            
            self._serial.setPortName(port_name)
            self._serial.setBaudRate(baud_rate)
            
            self._serial.setDataBits(QSerialPort.DataBits.Data8)
            self._serial.setParity(QSerialPort.Parity.NoParity)
            self._serial.setStopBits(QSerialPort.StopBits.OneStop)
            self._serial.setFlowControl(QSerialPort.FlowControl.NoFlowControl)
            
            if self._serial.open(QSerialPort.OpenModeFlag.ReadWrite):
                self._is_connected = True
                self.connectionStateChanged.emit()
                print(f"串口连接成功: {port_name}, 波特率: {baud_rate}")
                return True
            else:
                error = self._serial.error()
                error_msg = f"无法打开串口 {port_name}: {self._serial.errorString()}"
                self.errorOccurred.emit(error_msg)
                print(error_msg)
                return False
                
        except Exception as e:
            self.errorOccurred.emit(f"串口连接错误: {str(e)}")
            print(f"串口连接错误: {e}")
            return False

    @Slot()
    def disconnect_serial(self):
        if not hasattr(self, '_serial') or not self._serial:
            return
            
        if self._is_connected:
            try:
                self._serial.close()
                self._is_connected = False
                self.connectionStateChanged.emit()
                print("串口已断开连接")
            except Exception as e:
                print(f"断开串口时发生错误: {e}")

    @Slot(str)
    def send_data(self, data):
        if not self._serial:
            self.errorOccurred.emit("串口未初始化")
            return
            
        try:
            if self._is_connected:
                bytes_written = self._serial.write(data.encode())
                if bytes_written == -1:
                    self.errorOccurred.emit(f"发送数据失败: {self._serial.errorString()}")
                else:
                    print(f"发送数据成功: {data}")
            else:
                self.errorOccurred.emit("串口未连接")
        except Exception as e:
            self.errorOccurred.emit(f"发送数据错误: {str(e)}")
            print(f"发送数据错误: {e}")

    def _on_ready_read(self):
        if not self._serial:
            return
        
        try:
            locker = QMutexLocker(self._connect_mutex)
            
            while self._serial.canReadLine():
                raw_data = self._serial.readAll().data()
                
                ascii_str = ""
                hex_str = ""
                
                for byte in raw_data:
                    hex_str += f"{byte:02X} "
                    
                    if 32 <= byte <= 126:
                        ascii_str += chr(byte)
                    else:
                        ascii_str += "."
                
                hex_lines = []
                ascii_lines = []
                bytes_per_line = 16
                
                for i in range(0, len(hex_str.split()), bytes_per_line):
                    hex_line = hex_str.split()[i:i + bytes_per_line]
                    hex_lines.append(" ".join(hex_line))
                    
                    ascii_line = ascii_str[i:i + bytes_per_line]
                    ascii_lines.append(ascii_line)
                
                display_text = ""
                for hex_line, ascii_line in zip(hex_lines, ascii_lines):
                    hex_padding = " " * (48 - len(hex_line))
                    display_text += f"{hex_line}{hex_padding} | {ascii_line}\n"
                
                self._received_data = display_text.strip()
                self.receivedDataChanged.emit()
                print(f"接收到数据:\n{self._received_data}")
                
        except Exception as e:
            self.errorOccurred.emit(f"接收数据错误: {str(e)}")
            print(f"接收数据错误: {e}")

    def _on_error(self, error):
        if not self._serial:
            return
            
        if error != QSerialPort.SerialPortError.NoError:
            error_msg = f"串口错误: {self._serial.errorString()}"
            self.errorOccurred.emit(error_msg)
            print(error_msg)
            
            if error in [QSerialPort.SerialPortError.DeviceNotFoundError,
                        QSerialPort.SerialPortError.PermissionError,
                        QSerialPort.SerialPortError.DeviceError]:
                self.disconnect_serial()