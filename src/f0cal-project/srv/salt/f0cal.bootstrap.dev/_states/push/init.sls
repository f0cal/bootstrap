{% import "_macros/project/project_yaml.jinja" as Project with context %}
{% set project = Project.from_env() | load_yaml %}

{% set code_dir = project.code_dir %}

{%- for repo in project.repos -%}
{% set cmd = "git -C %s/%s rev-parse --verify --short HEAD" | format(code_dir, repo.name) %}
{% set rev = salt['cmd.run'](cmd) %}
{% do repo.update({'rev': rev}) %}
{% set cmd = "git -C %s/%s rev-parse --abbrev-ref HEAD" | format(code_dir, repo.name) %}
{% set branch = salt['cmd.run'](cmd) %}
{% do repo.update({'branch': branch}) %}
{%- endfor -%}

{% set cmd = "git -C %s rev-parse --abbrev-ref HEAD" | format(code_dir) %}
{% set project_branch = salt['cmd.run'](cmd) %}

{% for repo in project.repos %}
git-diff--{{ code_dir }}/{{ repo.name }}:
  cmd.run:
    - name: |
        git -C {{ code_dir }}/{{ repo.name }} diff --exit-code > /dev/null && \
        git -C {{ code_dir }}/{{ repo.name }} diff --cached --exit-code > /dev/null
{% endfor %}

{{ code_dir }}/project.yml:
  file.managed:
    - source: salt://{{ slspath }}/project.yml
    - makedirs: True
    - template: jinja
    - context:
        code_dir: {{ code_dir }}
        project: {{ project | tojson() }}
    - require:
{% for repo in project.repos %}
      - cmd: git-diff--{{ code_dir }}/{{ repo.name }}
{% endfor %}

project-add:
  cmd.run:
    - name: git -C {{ code_dir }} add project.yml
    - require:
        - file: {{ code_dir }}/project.yml

project-commit:
  cmd.run:
    - name: git -C {{ code_dir }} commit -m "Automated commit"
    - require:
        - cmd: project-add

{% for repo in project.repos %}
{{ repo.name }}-push:
  cmd.run:
    - name: git -C {{ code_dir }}/{{ repo.name }} push origin {{ repo.branch }}
    - require:
        - cmd: project-commit
{% endfor %}

project-push:
  cmd.run:
    - name: git -C {{ code_dir }} push origin {{ project_branch }}
    - require:
{% for repo in project.repos %}
        - cmd: {{ repo.name }}-push
{% endfor %}
