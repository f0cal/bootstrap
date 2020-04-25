{% set code_dir = pillar['cli']['code_dir'] %}
{% set project_yml = "%s/project.yml" | format(code_dir) %}
{% set project = salt["file.read"](project_yml) | load_yaml %}

{% for repo in project.repos %}
status--{{ repo.name }}:
  cmd.run:
    - name: git -C {{ code_dir }}/{{ repo.name }} status --porcelain
    - unless: test -z "$(git -C {{ code_dir }}/{{ repo.name }} status --porcelain)"
{% endfor %}
