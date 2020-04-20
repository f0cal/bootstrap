{% set venv_dir = salt['pillar.get']("cli:venv_dir", None) %}
{% set python_exe = salt['pillar.get']("cli:python", None) %}
{% if venv_dir %}
{% set temp_dir = "%s/tmp" | format(venv_dir) %}
{% else %}
{% set temp_dir = salt['temp.dir']() %}
{% endif %}
{% set requirements_file = "%s/requirements.txt" | format(temp_dir) %}
{% set constraints_file = "%s/constraints.txt" | format(temp_dir) %}
{% set pip_exe = "pip" %}

{% if venv_dir %}
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
{% set pip_exe = "%s/bin/pip" | format(venv_dir) %}
{% endif %}

{{ requirements_file }}:
  file.managed:
    - source: salt://{{ tpldir }}/requirements.txt
    - template: jinja
    - makedirs: True

{{ constraints_file }}:
  file.managed:
    - source: salt://{{ tpldir }}/constraints.txt
    - template: jinja
    - makedirs: True

pip_upgrade:
  cmd.run:
    - name: {{ pip_exe }} install --upgrade pip
pip_prereqs:
  pip.installed:
    - bin_env: {{ pip_exe }}
    - pkgs:
      - black
      - pyyaml
      - jinja2

pip_install:
  cmd.run:
    - name: {{ pip_exe }} install -r {{ requirements_file }} -c {{ constraints_file }}
    - require:
        - file: {{ requirements_file }}
        - file: {{ constraints_file }}
        - cmd: pip_upgrade
