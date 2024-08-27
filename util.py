from collections.abc import Iterable
from os import makedirs
import sys
from pathlib import Path
import shutil
from typing import List

def copy_libs(source: str, dest: str) -> None:
    source_path = Path(source).absolute()
    dest_path = Path(dest).absolute()
    del source, dest

    for dirpath, _, filenames in source_path.walk():
        for filename in filenames:
            if filename.endswith('wasm32-wasi.so'):
                suffix = dirpath.relative_to(source_path)
                source_ = source_path / suffix / filename
                dest_ = dest_path / suffix / filename
                makedirs(dest_.parent, exist_ok=True)
                shutil.copy(source_, dest_)
                print(dest_)


def generate_files(dest: str, name: str, dirname: str, version: str, *dependencies: str) -> None:
    makedirs(dest, exist_ok=True)
    deps = list(dependencies)
    deps.insert(0, f'{name}=={version}')
    del dependencies
    dep_str = '", "'.join(deps)
    del deps
    with open(Path(dest) / "MANIFEST.in", "w") as f:
        f.write(f"""recursive-include {dirname} *.so""")
    with open(Path(dest) / "pyproject.toml", "w") as f:
        f.write(f"""[build-system]
requires = ["setuptools >= 61.0"]
build-backend = "setuptools.build_meta"

[project]
name = "{name}-wasi"
version = "{version}"
requires-python = "== 3.12.*"
dependencies = ["{dep_str}"]

[tool.setuptools]
include-package-data = true

[tool.setuptools.packages.find]
where = ["."]
include = ["{dirname}"]
exclude = []
namespaces = true
""")


if __name__ == "__main__":
    thismodule = sys.modules[__name__]
    func = getattr(thismodule, sys.argv[1], None)
    if func:
        func(*sys.argv[2:])
