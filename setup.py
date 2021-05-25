import setuptools
from distutils.core import setup
from distutils.extension import Extension
from Cython.Build import cythonize
from Cython.Distutils import build_ext
import numpy

extensions = [
    Extension("C_Connect4", ["Connect4.pyx"], include_dirs=[numpy.get_include()]),
    Extension("C_GenericAlgorithm", ["GenericAlgorithm.pyx"]),
    Extension("C_ia_sondage", ["ia_sondage.pyx"]),
    Extension("C_ia_count_alignments", ["ia_count_alignments.py"]),
    Extension("C_ia_potential_alignments", ["ia_potential_alignments.pyx"]),
    Extension("C_championship", ["championship.py"])
    # à renommer selon les besoins
]

setup(
    cmdclass={'build_ext': build_ext},
    ext_modules=cythonize(extensions),
)