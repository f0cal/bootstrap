{% import "_macros/project/project_yaml.jinja" as Project with context %}
{% set project = Project.from_env() %}

{% set out_dir = "%s/_pypi" | format(code_dir) %}

{% for egg in project.eggs %}
{% set name = egg.name %}
{% set repo = egg.repo %}
{% set subdir = "" %}
{% if egg.get("subdir", None ) %}
{% set subdir = "&subdirectory=%s" | format(egg.subdir) %}
{% endif %}

{{ out_dir }}/{{ name.replace(".", "-") }}:
  file.directory:
    - exists: True
    - makedirs: True

{{ out_dir }}/{{ name.replace(".", "-") }}/index.html:
  file.managed:
    - source: salt://{{ tpldir }}/index.html
    - template: jinja
    - context:
        egg: {{ egg }}
        repo: {{ project.repos | selectattr('name', 'equalto', egg.repo) | first }}

{% endfor %}