#! /usr/bin/env python3

import sys
assert sys.version_info >= (3, 6), "Sorry, this script relies on v3.6+ language features."

import site
import os
import venv
import argparse
import tempfile
import shlex
import subprocess

REQUIREMENTS = """
f0cal.bootstrap
"""

CONSTRAINTS = """
git+https://github.com/f0cal/bootstrap#egg=f0cal.bootstrap
"""

PREINSTALL_LIST = [
    "git+https://github.com/f0cal/f0cal#subdirectory=plugnparse&egg=plugnparse",
    "git+https://github.com/f0cal/saltbox#egg=saltbox",
]

class Installer:
    def __init__(self):
        self._tempdir = tempfile.TemporaryDirectory()
        self._create_venv()

    @property
    def path(self):
        return self._tempdir.name

    def _create_venv(self):
        venv.create(self.path, with_pip=True)

    def activate_venv(self):
        self._activate_venv(self.path)

    def __enter__(self):
        self._tempdir.__enter__()
        return self

    def __exit__(self, *args, **dargs):
        return self._tempdir.__exit__(*args, **dargs)

    @staticmethod
    def _activate_venv(env_dir):
        """Activate virtualenv for current interpreter:

        Use exec(open(this_file).read(), {'__file__': this_file}).

        This can be used when you must use an existing Python interpreter, not the virtualenv bin/python.
        """

        try:
            __file__
        except NameError:
            raise AssertionError(
                "You must use exec(open(this_file).read(), {'__file__': this_file}))"
            )

        # prepend bin to PATH (this file is inside the bin directory)
        bin_dir = os.path.join(env_dir, "bin")
        os.environ["PATH"] = os.pathsep.join(
            [bin_dir] + os.environ.get("PATH", "").split(os.pathsep)
        )

        base = os.path.dirname(bin_dir)

        # virtual env is right above bin directory
        os.environ["VIRTUAL_ENV"] = base

        # add the virtual environments site-package to the host python import mechanism
        IS_PYPY = hasattr(sys, "pypy_version_info")
        IS_JYTHON = sys.platform.startswith("java")
        if IS_JYTHON:
            site_packages = os.path.join(base, "Lib", "site-packages")
        elif IS_PYPY:
            site_packages = os.path.join(base, "site-packages")
        else:
            IS_WIN = sys.platform == "win32"
            if IS_WIN:
                site_packages = os.path.join(base, "Lib", "site-packages")
            else:
                site_packages = os.path.join(
                    base, "lib", "python{}".format(sys.version[:3]), "site-packages"
                )

        prev = set(sys.path)
        site.addsitedir(site_packages)
        sys.real_prefix = sys.prefix
        sys.prefix = base

        # Move the added items to the front of the path, in place
        new = list(sys.path)
        sys.path[:] = [i for i in new if i not in prev] + [i for i in new if i in prev]

    def _run_exe(self, cmd_str):
        subprocess.check_call(shlex.split(cmd_str))

    def preinstall(self):
        requirements_path = os.path.join(self.path, 'requirements.txt')
        open(requirements_path, 'w').write(REQUIREMENTS)
        constraints_path = os.path.join(self.path , 'constraints.txt')
        open(constraints_path, 'w').write(CONSTRAINTS)
        self._run_exe(f"{self.path}/bin/pip install --upgrade pip")
        for pkg_str in PREINSTALL_LIST:
            self._run_exe(f"{self.path}/bin/pip install {pkg_str}")
        self._run_exe(f"{self.path}/bin/pip install -r {requirements_path} -c {constraints_path}")

def main():
    parser = argparse.ArgumentParser()
    ns = parser.parse_args()

    with Installer() as installer:
        installer.preinstall()
        installer.activate_venv()
        import saltbox

if __name__ == '__main__':
    main()
