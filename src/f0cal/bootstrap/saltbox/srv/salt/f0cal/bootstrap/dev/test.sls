{% set code_dir = pillar['cli']['code_dir'] %}
{% set project_yml = "%s/project.yml" | format(code_dir) %}
{% set project = salt["file.read"](project_yml) | load_yaml %}

{% set defaults = project.tests_default %}

{% for test in project.tests %}
{% set run = test.get("run", defaults.get("run", None)) %}

{{ run }}:
  cmd.run:
    - cwd: {{ code_dir }}/{{ test.cwd }}

{% endfor %}
