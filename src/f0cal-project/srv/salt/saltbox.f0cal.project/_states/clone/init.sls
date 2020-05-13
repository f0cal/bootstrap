{% set https_user = pillar['cli']['https_user'] %}
{% set https_pass = pillar['cli']['https_pass'] %}

{% import "_macros/project/project_yaml.jinja" as Project with context %}
{% set project = Project.from_env() | load_yaml %}
{% for repo in project.repos %}
{% set url = repo.url %}
{% set name = repo.name %}
{% set path = Project.abspath(name) %}
{% set branch = repo.branch %}
{% set rev = repo.rev %}

{{ url }}:
  git.cloned:
    - target: {{ path }}
{% if branch %}
    - branch: {{ branch }}
{% endif %}
{% if https_user %}
    - https_user: {{ https_user }}
{% endif %}
{% if https_pass %}
    - https_pass: {{ https_pass }}
{% endif %}

{% endfor %}
