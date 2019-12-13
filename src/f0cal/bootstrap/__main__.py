#! /usr/bin/env python3

import argparse
import json
import os
import shlex
import shutil
import site
import subprocess
import sys
import tempfile
import venv


class Installer:

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

    def __init__(self, temp_dir=None, clean_up=True):
        self._temp_dir = temp_dir or tempfile.mkdtemp(prefix=self.TMP_PREFIX)
        self._create_venv()
        self._clean_up = clean_up

    @property
    def path(self):
        return self._temp_dir

    def _create_venv(self):
        venv.create(self.path, with_pip=True)

    def activate_venv(self):
        self._activate_venv(self.path)

    def __enter__(self):
        return self

    def __exit__(self, *args, **dargs):
        if not self._clean_up:
            return
        shutil.rmtree(self.path)

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

    def _render_file(self, path, _list):
        with open(path, "w") as _file:
            contents = "\n".join(_list)
            _file.write(contents)

    def preinstall(self):
        self._run_exe(f"{self.path}/bin/pip install --upgrade pip")
        requirements_path = os.path.join(self.path, "requirements.txt")
        self._render_file(requirements_path, self.REQUIREMENTS.values())
        constraints_path = os.path.join(self.path, "constraints.txt")
        self._render_file(constraints_path, self.CONSTRAINTS.values())
        self._run_exe(
            f"{self.path}/bin/pip install -r {requirements_path} -c {constraints_path}"
        )


def scrub_url(url, pkg):
    if ":" not in url:
        url = os.path.abspath(url)
        assert os.path.exists(url)
        assert os.path.isdir(url)
        return f"-e file://{url}#egg={pkg}"
    return url


def install(
    run_state=None,
    temp_dir=None,
    clean_up=True,
    saltbox_repo=None,
    bootstrap_repo=None,
    log_level=None,
    salt_repo=None,
    **kwargs,
):

    if "python" not in kwargs:
        kwargs["python"] = sys.executable
    constraints_file = kwargs.pop("constraints_file", None)
    if constraints_file is not None:
        kwargs["contraints"] = constraints_file.read()
    kwargs["cwd"] = os.getcwd()

    state_kwargs = dict(k.split("=") for k in kwargs.pop("state_kwarg", None) or [])
    kwargs.update(state_kwargs)

    run_state = run_state or "user"
    pillar = json.dumps(dict(cli=kwargs))
    cmd = [
        "salt-run",
        "state.orchestrate",
        run_state,
        "saltenv=bootstrap",
        f"pillar={pillar}",
    ]
    if log_level is not None:
        cmd += ["--log-level", log_level]

    if bootstrap_repo is not None:
        Installer.CONSTRAINTS["f0cal.bootstrap"] = scrub_url(
            bootstrap_repo, "f0cal.bootstrap"
        )
    if saltbox_repo is not None:
        Installer.CONSTRAINTS["saltbox"] = scrub_url(saltbox_repo, "saltbox")
    if salt_repo is not None:
        Installer.CONSTRAINTS["salt"] = scrub_url(salt_repo, "salt")

    with Installer(temp_dir=temp_dir, clean_up=clean_up) as installer:
        installer.preinstall()
        installer.activate_venv()
        import saltbox
        import f0cal.bootstrap

        config = saltbox.SaltBoxConfig.from_env(use_install_cache=False)
        with saltbox.SaltBox.installer_factory(config) as api:
            api.add_package(f0cal.bootstrap.saltbox_path())
        config = saltbox.SaltBoxConfig.from_env(block=False)
        with saltbox.SaltBox.executor_factory(config) as api:
            return api.execute(*cmd)


def main():
    assert sys.version_info >= (
        3,
        6,
    ), "Sorry, this script relies on v3.6+ language features."

    try:
        print(f"Verifying required apt packages are present:")
        subprocess.check_call(shlex.split(f"dpkg-query -W gcc python3 git python3-dev python3-venv rsync"))
    except (ModuleNotFoundError, subprocess.CalledProcessError) as e:
        sys.exit("One or more required apt packages not found.")

    parser = argparse.ArgumentParser()

    _descr = """These options control what is installed and where."""
    install_group = parser.add_argument_group("Install options", description=_descr)

    install_group.add_argument(
        "--venv-dir",
        type=lambda x: os.path.abspath(x),
        default=None,
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
    dev_group.add_argument("--log-level", default=None, choices=["DEBUG", "TRACE"])
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
        "--run-state", default=None, help="Run a non-standard salt state."
    )
    dev_group.add_argument(
        "--state-kwarg",
        default=None,
        action="append",
        help="Run a non-standard salt state.",
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
