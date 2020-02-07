{% set code_dir = pillar['cli']['code_dir'] %}
{% set project_yml = "%s/project.yml" | format(code_dir) %}
{% set project = salt["file.read"](project_yml) | load_yaml %}

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
    - source: salt://{{ slspath }}/index.html
    - template: jinja
    - context:
        egg: {{ egg }}
        repo: {{ project.repos | selectattr('name', 'equalto', egg.repo) | first }}

{% endfor %}
