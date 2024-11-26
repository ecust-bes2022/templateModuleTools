from setuptools import setup
from Cython.Build import cythonize
from Cython.Distutils import build_ext
import os

# 获取PySide6的include路径
try:
    from PySide6 import QtCore
    PYSIDE6_INCLUDE = os.path.dirname(QtCore.__file__)
except ImportError:
    PYSIDE6_INCLUDE = ""

setup(
    name='calculator',
    ext_modules=cythonize("calculator.pyx",
                         compiler_directives={'language_level': "3"}),
    include_dirs=[PYSIDE6_INCLUDE],
    cmdclass={'build_ext': build_ext},
    requires=['PySide6', 'Cython']
) 