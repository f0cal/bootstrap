{% import "_macros/project/project_yaml.jinja" as Project with context %}
{% set project = Project.from_env() | load_yaml %}

{% set python_exe = salt['pillar.get']("cli:python", "/usr/bin/python3") %}

{% set project = Project.reduce(project, "envs", pillar["cli"]["env"]) | load_yaml %}

{% for env in Project.with_defaults(project, "envs") | load_yaml %}

{% set env_path = Project.abspath(env.path)  %}
{% if not pillar['cli']['path_override'] is none %}
{% set env_path = pillar['cli']['path_override'] %}
{% endif %}
{% set build_dir = Project.abspath(Project.build_dir(env.name, slspath)) %}
{% set pip_exe = "%s/bin/pip" | format(env_path) %}

{{ build_dir }}/.pyvenv:
  file.managed:
    - makedirs: True
    - mode: 777
    - contents: |
        #! /bin/bash
        PREFIX=$(python -c "print(__import__('sys').base_exec_prefix)")
        ${PREFIX}/bin/python3.7 -m venv $@

{{ env_path }}:
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

{{ build_dir }}/requirements.txt:
  file.managed:
    - source: salt://{{ slspath }}/dev_requirements.txt
    - template: jinja
    - makedirs: True
    - context:
        project: {{ project | tojson() }}

{{ build_dir }}/constraints.txt:
  file.managed:
    - source: salt://{{ slspath }}/dev_constraints.txt
    - template: jinja
    - makedirs: True
    - context:
        project: {{ project | tojson() }}

pip_upgrade:
  cmd.run:
    - name: {{ pip_exe }} install --upgrade pip==20.1.1 wheel setuptools
    - cwd: {{ project.code_dir }}
    - require:
        - virtualenv: {{ env_path }}

setup_pip_install:
  cmd.run:
    - name : {{ pip_exe }} install -r {{ build_dir }}/setup_requirements.txt
    - cwd: {{ project.code_dir }}
    - require:
        - file: {{ build_dir }}/setup_requirements.txt
        - cmd: pip_upgrade

pip_install:
  cmd.run:
    - name: {{ pip_exe }} install -r {{ build_dir }}/requirements.txt -c {{ build_dir }}/constraints.txt
    - cwd: {{ project.code_dir }}
    - require:
        - file: {{ build_dir }}/requirements.txt
        - file: {{ build_dir }}/constraints.txt
        - cmd: setup_pip_install
        - cmd: pip_upgrade
    - env:
        - LC_CTYPE: 'en_US.UTF-8'
        - LANG: 'en_US.UTF-8'

{% endfor %}
