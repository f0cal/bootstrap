{% set code_dir = pillar['cli']['code_dir'] %}
{% set project_yml = "%s/project.yml" | format(code_dir) %}
{% set project = salt["file.read"](project_yml) | load_yaml %}

{% set defaults = project.repos_default %}

{% for repo in project.repos %}
{% set name = repo.get("name", defaults.get("name", None)) %}
{% set branch = repo.get("branch", defaults.get("branch", None)) %}
{% set https_user = repo.get("https_user", defaults.get("https_user", None)) %}
{% set url = repo.get("url", defaults.get("url", None)) %}
{% set path = "%s/%s" | format(code_dir, name) %}
{% set repo.rev = salt['cmd.run']("git rev-parse --verify --short HEAD", cwd=path) %}

repo-{{ name }}-is-porcelain--after:
  cmd.run:
    - name: test -z "$(git status --porcelain)"
    - cwd: {{ path }}

{% endfor %}

{{ code_dir }}/project.yml:
  file.managed:
    - source: salt://{{ tpldir }}/project.yml
    - makedirs: True
    - template: jinja
    - context:
        project: {{ project }}
    - require:
{% for repo in project.repos %}
{% set name = repo.get("name", defaults.get("name", None)) %}
        - repo-{{ name }}-is-porcelain--after
{% endfor %}

