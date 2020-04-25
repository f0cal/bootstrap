{% set code_dir = pillar['cli']['code_dir'] %}
{% set project_yml = "%s/project.yml" | format(code_dir) %}
{% set project = salt["file.read"](project_yml) | load_yaml %}

{% set defaults = project.tests_default %}

{% for test in project.tests %}
{% set run = test.get("run", defaults.get("run", None)) %}
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

{% for test in project.tests %}
{% set script = test.get("script", defaults.get("script", None)) %}
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
