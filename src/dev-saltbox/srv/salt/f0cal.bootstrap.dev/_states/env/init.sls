{% set env_name = pillar["cli"]["env"] %}
{% set python_exe = salt['pillar.get']("cli:python", "/usr/bin/python3.7") %}

{% set code_dir = pillar["cli"]["code_dir"] %}
{% set project = salt['file.read']("%s/project.yml"|format(code_dir)) | load_yaml %}

{% set env = project.envs | selectattr("name", "equalto", env_name) | first %}
{% set envs_default = project.envs_default %}
{% do envs_default.update(env) %}
{% set env = envs_default %}

{% set venv_dir = "%s/%s" | format(code_dir, env.path) %}
{% set build_dir = "%s/_cache/%s" | format(code_dir, env_name) %}

{% set skip_list = salt['pillar.get']("cli:skip", None) %}
{% set pip_exe = "%s/bin/pip" | format(venv_dir) %}

{{ build_dir }}/.pyvenv:
  file.managed:
    - makedirs: True
    - mode: 777
    - contents: |
        #! /bin/bash
        {{ python_exe }} -m venv $@

{{ venv_dir }}:
  virtualenv.managed:
    - venv_bin: {{ build_dir }}/.pyvenv
    - require:
        - file: {{ build_dir }}/.pyvenv

{{ build_dir }}/setup_requirements.txt:
  file.managed:
    - source: salt://{{ slspath }}/setup_requirements.txt
    - makedirs: True
    - template: jinja
    - context:
        project: {{ project | tojson() }}
        env: {{ env | tojson() }}

{{ build_dir }}/requirements.txt:
  file.managed:
    - source: salt://{{ slspath }}/dev_requirements.txt
    - template: jinja
    - makedirs: True
    - context:
        project: {{ project | tojson() }}
        env: {{ env | tojson() }}

{{ build_dir }}/constraints.txt:
  file.managed:
    - source: salt://{{ slspath }}/dev_constraints.txt
    - template: jinja
    - makedirs: True
    - context:
        project: {{ project | tojson() }}
        env: {{ env | tojson() }}

pip_upgrade:
  cmd.run:
    - name: {{ pip_exe }} install --upgrade pip wheel
    - require:
        - virtualenv: {{ venv_dir }}

setup_pip_install:
  cmd.run:
    - name : {{ pip_exe }} install -r {{ build_dir }}/setup_requirements.txt
    - require:
        - file: {{ build_dir }}/setup_requirements.txt
        - cmd: pip_upgrade

pip_install:
  cmd.run:
    - name: {{ pip_exe }} install -r {{ build_dir }}/requirements.txt -c {{ build_dir }}/constraints.txt
    - cwd: {{ code_dir }}
    - require:
        - file: {{ build_dir }}/requirements.txt
        - file: {{ build_dir }}/constraints.txt
        - cmd: setup_pip_install
        - cmd: pip_upgrade
    - env:
        - LC_CTYPE: 'en_US.UTF-8'
        - LANG: 'en_US.UTF-8'
