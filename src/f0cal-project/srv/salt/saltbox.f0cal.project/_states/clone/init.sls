{% set https_user = pillar['cli']['https_user'] %}
{% set https_pass = pillar['cli']['https_pass'] %}
{% set latest = pillar['cli']['latest'] %}
{% set shallow = pillar['cli']['shallow'] %}

{% import "_macros/project/project_yaml.jinja" as Project with context %}
{% set project = Project.from_env() | load_yaml %}
{% for repo in project.repos %}
{% set url = repo.url %}
{% set name = repo.name %}
{% set path = Project.abspath(name) %}
{% set branch = repo.branch %}
{% set rev = repo.rev %}

{{ url }}:
# IF directory is present take no action but must still have state otherwise command may fail
{% if  salt['file.directory_exists' ](path) %}
  test.nop: []
{% else %}
{% if latest %}
  git.latest:
    - branch: {{ branch }}
{% elif rev == 'latest' %}
  git.latest:
    - branch: {{ branch }}
    - rev: {{ branch }}
{% if shallow %}
    - depth: 1
{% endif %}
{% else %}
  git.detached:
    - rev: {{ rev }}
{% endif %}
    - target: {{ path }}
{% if https_user is not none %}
    - https_user: {{ https_user }}
{% endif %}
{% if https_pass is not none %}
    - https_pass: {{ https_pass }}
{% endif %}
{% endif %}
{% endfor %}
