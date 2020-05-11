{% set allow_unclean = pillar['cli']['allow_unclean'] %}
{% set https_user = pillar['cli']['https_user'] %}

{% import "_macros/project/project_yaml.jinja" as Project with context %}
{% set project = Project.from_env() | load_yaml %}
{% for repo in project.repos %}
{% set url = repo.url %}
{% set name = repo.name %}
{% set path = Project.abspath(name) %}
{% set branch = repo.branch %}

{{ url }}:
  git.cloned:
    - target: {{ path }}
{% if branch %}
    - branch: {{ branch }}
{% endif %}
{% if https_user %}
    - https_user: {{ https_user }}
{% endif %}
    - unless:
        - ls {{ path }}

{% if not allow_unclean %}
repo-{{ name }}-is-porcelain--before:
  cmd.run:
    - name: test -z "$(git status --porcelain)"
    - cwd: {{ path }}
{% endif %}


{% endfor %}
