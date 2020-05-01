{% set code_dir = pillar['cli']['code_dir'] %}
{% set git_args = pillar['cli']['git_args'] %}

{% set project_yml = "%s/project.yml" | format(code_dir) %}
{% set project = salt["file.read"](project_yml) | load_yaml %}

{% set defaults = project.repos_default %}
{% for repo in project.repos %}
{% set path = "%s/%s" | format(code_dir, repo.name) %}

git -C {{ path }} {{ git_args | join(" ") }}:
  cmd.run:
    - onlyif:
        - ls {{ path }}/.git

{% endfor %}

{% set path = code_dir %}
git -C {{ path }} {{ git_args | join(" ") }}:
  cmd.run:
    - onlyif:
        - ls {{ path }}/.git
