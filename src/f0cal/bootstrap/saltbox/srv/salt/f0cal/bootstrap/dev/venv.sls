{% set cwd = pillar["cli"]["cwd"] %}
{% set code_dir = salt['pillar.get']("cli:code_dir", cwd) %}
{% set venv_dir = "%s/_venv" | format(code_dir) %}
{% set skip_list = salt['pillar.get']("cli:skip", None) %}
{% set python_exe = salt['pillar.get']("cli:python", None) %}
{% set requirements_file = "%s/requirements.txt" | format(code_dir) %}
{% set constraints_file = "%s/constraints.txt" | format(code_dir) %}
{% set setup_file = "%s/setup_requirements.txt" | format(code_dir) %}
{% set pip_exe = "%s/bin/pip" | format(venv_dir) %}
{% set temp_dir = salt['temp.dir']() %}

venv_bin:
  file.managed:
    - makedirs: True
    - name: {{ temp_dir }}/.pyvenv
    - mode: 777
    - contents: |
        #! /bin/bash
        {{ python_exe}} -m venv $@

{{ venv_dir }}:
  virtualenv.managed:
    - venv_bin: {{ temp_dir }}/.pyvenv
    - require:
        - file: {{ temp_dir }}/.pyvenv

{{ requirements_file }}:
  file.managed:
    - source: salt://{{ slspath }}/dev_requirements.txt
    - template: jinja
    - makedirs: True

{{ constraints_file }}:
  file.managed:
    - source: salt://{{ slspath }}/dev_constraints.txt
    - template: jinja
    - makedirs: True

{{ setup_file }}:
  file.managed:
    - source: salt://{{ slspath }}/setup_requirements.txt
    - template: jinja
    - makedirs: True

pip_upgrade:
  cmd.run:
    - name: {{ pip_exe }} install --upgrade pip

# setup_pip_install:
#   cmd.run:
#     - name : {{ pip_exe }} install -r {{ setup_file }}
#     - require:
#         - file: {{ setup_file }}
#         - cmd: pip_upgrade

pip_install:
  cmd.run:
    - name: {{ pip_exe }} install -r {{ requirements_file }} -c {{ constraints_file }}
    - cwd: {{ code_dir }}
    - require:
        - file: {{ requirements_file }}
        - file: {{ constraints_file }}
        # - cmd: setup_pip_install
        - cmd: pip_upgrade
    - env:
        - LC_CTYPE: 'en_US.UTF-8'
        - LANG: 'en_US.UTF-8'
