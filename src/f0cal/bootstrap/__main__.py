#! /usr/bin/env python3

import argparse
import contextlib
import importlib
import json
import os
import platform
import shlex
import shutil
import site
import subprocess
import sys
import tempfile
import types
import venv


class EnvBase(types.SimpleNamespace):
    @classmethod
    def from_ambient(cls):
        return cls(sys=vars(sys).copy(), environ=vars(os.environ).copy(), is_venv=False)

    @classmethod
    def from_venv_path(cls, path):
        return cls(path=path)

    def activate(self):
        raise NotImplementedError()


class InsideEnv(EnvBase):
    def activate(self):
        return self._activate_venv(self.path)

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


class OutsideEnv(EnvBase):
    def activate(self):
        pass


class Venv:
    def __init__(self, path):
        self._path = path
        self._created = False
        self._outside_env = OutsideEnv.from_ambient()
        self._inside_env = InsideEnv.from_venv_path(self._path)

    @property
    @contextlib.contextmanager
    def active(self):
        try:
            self.activate()
            yield self
        finally:
            self.deactivate()

    def create(self):
        assert not self._created
        venv.create(self._path, with_pip=True)
        self._created = True

    def activate(self):
        self._inside_env.activate()

    def deactivate(self):
        self._outside_env.activate()

    @classmethod
    def from_path(cls, path):
        return cls(path)


class InstallerBase:

    REQUIREMENTS = {}
    REQUIREMENTS["f0cal.bootstrap"] = "f0cal.bootstrap"

    CONSTRAINTS = {}
    CONSTRAINTS[
        "plugnparse"
    ] = "git+https://github.com/f0cal/core#subdirectory=plugnparse&egg=plugnparse"
    CONSTRAINTS["saltbox"] = "git+https://github.com/f0cal/saltbox#egg=saltbox"
    CONSTRAINTS[
        "f0cal.bootstrap"
    ] = "git+https://github.com/f0cal/bootstrap#egg=f0cal.bootstrap"

    TMP_PREFIX = "f0cal-bootstrap-"

    @classmethod
    def from_temp_dir(cls, temp_dir=None, clean_up=None):
        return cls(temp_dir, clean_up)

    def __init__(self, temp_dir=None, clean_up=True):
        self._temp_dir = temp_dir or tempfile.mkdtemp(prefix=self.TMP_PREFIX)
        self._clean_up = clean_up
        self._venv = Venv.from_path(self._temp_dir)
        self._requirements = self.REQUIREMENTS.copy()
        self._constraints = self.CONSTRAINTS.copy()

    @property
    def path(self):
        return self._temp_dir

    @property
    def venv(self):
        return self._venv

    def __enter__(self):
        return self

    def __exit__(self, *args, **dargs):
        if not self._clean_up:
            return
        shutil.rmtree(self.path)

    def _run_exe(self, cmd_str):
        subprocess.check_call(shlex.split(cmd_str))

    def _render_file(self, path, _list):
        with open(path, "w") as _file:
            contents = "\n".join(_list)
            _file.write(contents)

    def unpack_to_venv(self, bootstrap_repo=None, saltbox_repo=None, salt_repo=None):

        if bootstrap_repo is not None:
            self._constraints["f0cal.bootstrap"] = self.scrub_url(
                bootstrap_repo, "f0cal.bootstrap"
            )
        if saltbox_repo is not None:
            self._constraints["saltbox"] = self.scrub_url(saltbox_repo, "saltbox")
        if salt_repo is not None:
            self._constraints["salt"] = self.scrub_url(salt_repo, "salt")

        self.venv.create()
        self._run_exe(f"{self.path}/bin/pip install --upgrade pip")
        requirements_path = os.path.join(self.path, "requirements.txt")
        self._render_file(requirements_path, self._requirements.values())
        constraints_path = os.path.join(self.path, "constraints.txt")
        self._render_file(constraints_path, self._constraints.values())
        self._run_exe(
            f"{self.path}/bin/pip install -r {requirements_path} -c {constraints_path}"
        )

    @classmethod
    def supports(cls):
        raise NotImplementedError()

    @staticmethod
    def scrub_url(url, pkg):
        if ":" not in url:
            url = os.path.abspath(url)
            assert os.path.exists(url)
            assert os.path.isdir(url)
            return f"-e file://{url}#egg={pkg}"
        return url

    @staticmethod
    def assert_python36():
        assert sys.version_info >= (
            3,
            6,
        ), "Sorry, this script relies on v3.6+ language features."

    @staticmethod
    def check_venv_is_active():
        in_virtualenv = hasattr(sys, "real_prefix")
        in_venv = hasattr(sys, "base_prefix") and sys.base_prefix != sys.prefix
        if in_virtualenv or in_venv:
            print(
                "ERROR: Found active virtualenv or venv. Deactivate before bootstrap, "
                "since bootstrap creates its own venv."
            )
            sys, exit(1)


class DebianInstaller(InstallerBase):
    @classmethod
    def supports(self, platform_tuple):
        dist, version_num, version_name = platform_tuple
        return dist in ["Ubuntu", "Debian"]

    @classmethod
    def assert_prereqs(cls):
        assert subprocess.getstatusoutput("dpkg-query -W")[0] == 0

        print(f"\nVerifying a compatible c compiler is present:")
        compilers = {"gcc", "clang"}
        found_compiler = False
        for compiler in compilers:
            try:
                subprocess.check_call(shlex.split(f"dpkg-query -W {compiler}"))
                found_compiler = True
                break
            except subprocess.CalledProcessError:
                continue
        if not found_compiler:
            sys.exit(
                f"ERROR: Did not find compatible c compiler among {str(compilers)}."
            )

        try:
            print(f"\nVerifying other required apt packages are present:")
            subprocess.check_call(
                shlex.split(f"dpkg-query -W python3 git python3-dev python3-venv rsync")
            )
        except (ModuleNotFoundError, subprocess.CalledProcessError):
            sys.exit("ERROR: One or more required apt packages not found.")


class FormulaBase(types.SimpleNamespace):
    @classmethod
    def from_kwargs(cls, **kwargs):

        if os.geteuid() != 0:
            assert kwargs.get("venv_dir", None) is not None, (
                "If you're not root, you probably need to give a --venv-dir! "
                "If you're already in one, use --venv-dir=${VIRTUALENV}."
            )

        if "python" not in kwargs:
            kwargs["python"] = sys.executable
        constraints_file = kwargs.pop("constraints_file", None)
        if constraints_file is not None:
            kwargs["contraints"] = constraints_file.read()
        kwargs["cwd"] = os.getcwd()

        salt_kwargs = dict(k.split("=") for k in kwargs.pop("salt_kwarg", None) or [])
        kwargs.update(salt_kwargs)
        return cls(**kwargs)

    @property
    def saltbox_command(self):
        pillar = json.dumps(dict(cli=self.__dict__))
        cmd = [
            "salt-run",
            "state.orchestrate",
            self._NAME,
            "saltenv=bootstrap",
            f"pillar={pillar}",
        ]
        if self.log_level is not None:
            cmd += ["--log-level", self.log_level]
        return cmd


class UserFormula(FormulaBase):
    _NAME = "user"


class DevFormula(FormulaBase):
    _NAME = "dev"


INSTALLERS = [DebianInstaller]
FORMULAS = {"user": UserFormula, "dev": DevFormula}


def install(
    salt_formula=None,
    temp_dir=None,
    clean_up=True,
    saltbox_repo=None,
    bootstrap_repo=None,
    log_level=None,
    salt_repo=None,
    **kwargs,
):

    my_platform = platform.dist()
    possible_installers = list(filter(lambda _i: _i.supports(my_platform), INSTALLERS))

    if len(possible_installers) == 0:
        raise NotImplementedError(
            f"Sorry, this installer does not support {my_platform}. See"
            "https://github.com/f0cal/bootstrap for additional options."
        )

    Installer = possible_installers.pop()
    Formula = FORMULAS[salt_formula or "user"]

    Installer.assert_prereqs()
    with Installer.from_temp_dir(temp_dir=temp_dir, clean_up=clean_up) as installer:
        _venv_packages = dict(
            bootstrap_repo=bootstrap_repo,
            saltbox_repo=saltbox_repo,
            salt_repo=salt_repo,
        )
        installer.unpack_to_venv(**_venv_packages)
        with installer.venv.active:
            saltbox = importlib.__import__("saltbox")
            f0b = importlib.import_module("f0cal.bootstrap")
            config = saltbox.SaltBoxConfig.from_env(use_install_cache=False)
            with saltbox.SaltBox.installer_factory(config) as api:
                api.add_package(f0b.saltbox_path())
            config = saltbox.SaltBoxConfig.from_env(block=False)
            with saltbox.SaltBox.executor_factory(config) as api:
                formula = Formula.from_kwargs(log_level=log_level, **kwargs)
                return api.execute(*formula.saltbox_command)


def main():

    InstallerBase.assert_python36()

    parser = argparse.ArgumentParser()

    _descr = """These options control what is installed and where."""
    install_group = parser.add_argument_group("Install options", description=_descr)

    install_group.add_argument(
        "--venv-dir",
        type=lambda x: os.path.abspath(x),
        default=".venv",
        help="Filesystem path at which to create a Python3 virtual environement.",
    )

    # install_group.add_argument('--clone-dir', default=None, help="Filesystem path at which to clone f0cal code.")

    install_group.add_argument(
        "--skip",
        default=[],
        action="append",
        choices=["farm", "my-device", "my-code"],
        help="Skip an application component. May be used multiple times.",
    )

    _descr = """ADVANCED. These are for power users, and typically only required for debugging."""
    dev_group = parser.add_argument_group("Developer options", description=_descr)

    dev_group.add_argument(
        "--temp-dir",
        default=None,
        help="The temporary directory that this script uses for self-setup.",
    )
    dev_group.add_argument("--log-level", default=None, choices=["debug", "trace"])
    dev_group.add_argument(
        "--no-clean-up",
        dest="clean_up",
        default=True,
        action="store_false",
        help="Leave TEMP_DIR for debugging purposes; it is otherwise deleted.",
    )
    dev_group.add_argument(
        "--constraints-file",
        default=None,
        type=argparse.FileType("r"),
        help="Use a pip constraints file when installing.",
    )
    dev_group.add_argument(
        "--salt-formula", default=None, help="Run a non-standard salt formula."
    )
    dev_group.add_argument(
        "--salt-kwarg",
        default=None,
        action="append",
        help="Named argument to a non-standard salt formula.",
    )

    _descr = """ADVANCED. Use an alternate version of <package> during bootstrap. Accepts
    either a PATH on the local filesystem or PIP_URL. PIP_URL must be propertly
    formatted for consumption by pip. Learn more:
    https://pip.pypa.io/en/stable/reference/pip_install/#examples"""
    alt_group = parser.add_argument_group("Alternate locations", description=_descr)

    alt_group.add_argument("--saltbox-repo", default=None, help="")
    alt_group.add_argument("--bootstrap-repo", default=None, help="")
    alt_group.add_argument("--salt-repo", default=None, help="")

    ns = parser.parse_args()

    return install(**vars(ns))


if __name__ == "__main__":
    main()
