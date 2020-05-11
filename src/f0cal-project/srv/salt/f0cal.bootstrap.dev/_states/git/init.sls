{% import "_macros/project/project_yaml.jinja" as Project with context %}
{% set project = Project.from_env() | load_yaml %}

{% set git_args = pillar['cli']['git_args'] %}
{% set code_dir = project.code_dir %}


{% for repo in Project.with_defaults(project, "repos") | load_yaml %}
{% set path = Project.abspath(repo.name) %}

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
