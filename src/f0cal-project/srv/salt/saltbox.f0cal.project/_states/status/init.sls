{% import "_macros/project/project_yaml.jinja" as Project with context %}
{% set project = Project.from_env() %}

{# {% set code_dir = pillar['cli']['code_dir'] %}
{# {% set project_yml = "%s/project.yml" | format(code_dir) %}
{# {% set project = salt["file.read"](project_yml) | load_yaml %}

{% for repo in project.repos %}
status--{{ repo }}:
  cmd.run:
    - name: git -C repo.path status --porcelain
    - unless: test -z "$(git -C {{ repo.path  }} status --porcelain)"
{% endfor %}
