# Quick start

```bash
curl bootstrap.f0cal.com/master | python3 - --help
```
or

```
git clone https://github.com/f0cal/bootstrap && \
  ./bootstrap/bin/bootstrap.py --help
```

# About

`bin/bootstrap.py` is a small CLI installer for various other pieces of `f0cal`
code. Its purpose is to quickly build a virtual environement and install the
code required for both end users and developers. Under the hood, it uses
`saltstack` to perform orchestrations on the local OS.

# Learn more

[https://f0cal.com/docs](https://f0cal.com/docs#bootstrap)


# Basic usage

```
`usage: bootstrap.py [-h] [--venv-dir VENV_DIR]
                    [--skip {farm,my-device,my-code}] [--temp-dir TEMP_DIR]
                    [--log-level {DEBUG,TRACE}] [--no-clean-up]
                    [--constraints-file CONSTRAINTS_FILE]
                    [--run-state RUN_STATE] [--state-kwarg STATE_KWARG]
                    [--saltbox-repo SALTBOX_REPO]
                    [--bootstrap-repo BOOTSTRAP_REPO] [--salt-repo SALT_REPO]

optional arguments:
  -h, --help            show this help message and exit

Install options:
  These options control what is installed and where.

  --venv-dir VENV_DIR   Filesystem path at which to create a Python3 virtual
                        environement.
  --skip {farm,my-device,my-code}
                        Skip an application component. May be used multiple
                        times.

Developer options:
  ADVANCED. These are for power users, and typically only required for
  debugging.

  --temp-dir TEMP_DIR   The temporary directory that this script uses for
                        self-setup.
  --log-level {DEBUG,TRACE}
  --no-clean-up         Leave TEMP_DIR for debugging purposes; it is otherwise
                        deleted.
  --constraints-file CONSTRAINTS_FILE
                        Use a pip constraints file when installing.
  --run-state RUN_STATE
                        Run a non-standard salt state.
  --state-kwarg STATE_KWARG
                        Run a non-standard salt state.

Alternate locations:
  ADVANCED. Use an alternate version of <package> during bootstrap. Accepts
  either a PATH on the local filesystem or PIP_URL. PIP_URL must be
  propertly formatted for consumption by pip. Learn more:
  https://pip.pypa.io/en/stable/reference/pip_install/#examples

  --saltbox-repo SALTBOX_REPO
  --bootstrap-repo BOOTSTRAP_REPO
  --salt-repo SALT_REPO
```
