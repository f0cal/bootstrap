#! /usr/bin/env python3

import sys
import site
import os
import venv
import argparse
import tempfile
import shlex
import subprocess
import shutil

class Installer:

    REQUIREMENTS = {}
    REQUIREMENTS['f0cal.bootstrap'] = "git+https://github.com/f0cal/bootstrap#egg=f0cal.bootstrap"

    CONSTRAINTS = {}
    CONSTRAINTS['plugnparse'] = "git+https://github.com/f0cal/f0cal#subdirectory=plugnparse&egg=plugnparse"
    CONSTRAINTS['saltbox'] = "git+https://github.com/f0cal/saltbox#egg=saltbox"

    TMP_PREFIX = "f0cal-bootstrap-"

    def __init__(self, install_dir=None, clean_up=True):
        self._install_dir = install_dir or tempfile.mkdtemp(prefix=self.TMP_PREFIX)
        self._create_venv()
        self._clean_up = clean_up

    @property
    def path(self):
        return self._install_dir

    def _create_venv(self):
        venv.create(self.path, with_pip=True)

    def activate_venv(self):
        self._activate_venv(self.path)

    def __enter__(self):
        return self

    def __exit__(self, *args, **dargs):
        if not self._clean_up:
            return
        shutil.rmtree(self._install_dir)

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

    def _render_constraints(self, path):
        with open(path, 'w') as cfile:
            contents = "\n".join(self.CONSTRAINTS.values())
            cfile.write(contents)

    def _render_requirements(self, path):
        with open(path, 'w') as rfile:
            contents = "\n".join(self.REQUIREMENTS.values())
            rfile.write(contents)

    def preinstall(self):
        self._run_exe(f"{self.path}/bin/pip install --upgrade pip")
        # for pkg_str in self.PREINSTALL_PKGS.values():
        #     self._run_exe(f"{self.path}/bin/pip install {pkg_str}")
        # if self.REQUIREMENTS:
        requirements_path = os.path.join(self.path, 'requirements.txt')
        # if self.CONSTRAINTS:
        self._render_requirements(requirements_path)
        constraints_path = os.path.join(self.path , 'constraints.txt')
        self._render_constraints(constraints_path)
        self._run_exe(f"{self.path}/bin/pip install -r {requirements_path} -c {constraints_path}")

def scrub_url(url, pkg):
    if ":" not in url:
        url = os.path.abspath(url)
        assert os.path.exists(url)
        assert os.path.isdir(url)
        return f"file://{url}#egg={pkg}"
    return url

def install(install_dir=None, clean_up=True, saltbox_repo=None,
            bootstrap_repo=None, state=None, log_level=None, salt_repo=None):

    state = state or "f0cal.installed"
    cmd = ["salt-run", 'state.orchestrate', state, "saltenv=bootstrap"]
    if log_level is not None:
        cmd += ['--log-level', log_level]

    if bootstrap_repo is not None:
        Installer.REQUIREMENTS['f0cal.bootstrap'] = scrub_url(bootstrap_repo, 'f0cal.bootstrap')
    if saltbox_repo is not None:
        Installer.CONSTRAINTS['saltbox'] = scrub_url(saltbox_repo, 'saltbox')
    if salt_repo is not None:
        Installer.CONSTRAINTS['salt'] = scrub_url(salt_repo, 'salt')

    with Installer(install_dir=install_dir, clean_up=clean_up) as installer:
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
    assert sys.version_info >= (3, 6), "Sorry, this script relies on v3.6+ language features."

    parser = argparse.ArgumentParser()
    parser.add_argument('--install-dir', default=None)
    parser.add_argument('--no-clean-up', dest='clean_up', default=True, action='store_false')
    parser.add_argument('--saltbox-repo', default=None)
    parser.add_argument('--bootstrap-repo', default=None)
    parser.add_argument('--salt-repo', default=None)
    parser.add_argument('--state', default=None)
    parser.add_argument('--log-level', default=None)
    ns = parser.parse_args()

    return install(**vars(ns))

if __name__ == '__main__':
    main()
