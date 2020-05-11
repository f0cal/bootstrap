{% import "_macros/project/project_yaml.jinja" as Project with context %}
{% set project = Project.from_env() %}

{% for test in project.tests %}
{% if run %}

test-{{ loop.index }}:
  cmd.run:
    - name: {{ run }}
    - cwd: {{ code_dir }}
    - env:
        - LC_CTYPE: 'en_US.UTF-8'
        - LANG: 'en_US.UTF-8'
{% for key in test.args %}
        - {{ key }}: {{ test.args[key] }}
{% endfor %}


{% endif %}
{% endfor %}

{% if script %}
{% set script_name = salt["temp.file"]() %}

{{ script_name }}:
  file.managed:
    - contents:
{% for line in script.split("\n") %}
        - {{ line }}
{% endfor %}

script-test-{{ loop.index }}:
  cmd.run:
    - name: {{ script_name }}
    - cwd: {{ code_dir }}
    - require:
        - file: {{ script_name }}

{% endif %}
{% endfor %}
