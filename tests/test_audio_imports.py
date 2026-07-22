import importlib.util
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))


def test_pydub_imports_without_pyaudioop_dependency():
    module = importlib.import_module("pydub")
    assert module.AudioSegment is not None
