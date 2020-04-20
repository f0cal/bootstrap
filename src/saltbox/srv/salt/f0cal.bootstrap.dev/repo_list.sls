{% set url = "git@github.com:f0cal/project.git" %}
{% set code_dir = pillar['cli']['code_dir'] %}
{% set branch = salt['pillar.get']("cli:branch", None) %}

{% set dir_exists = salt['file.directory_exists'](code_dir) %}
# {% set file_exists = salt['file.file_exists'](code_dir) %}

# {{ code_dir }}/project.yml:
#   file.managed:
#       - source: salt://{{ tpldir }}/project.yml
#       - makedirs: True
#       - template: jinja
#       - unless:
#           - ls {{ code_dir }}/project.yml

{% if dir_exists %}

git_clone_project:
  cmd.run:
    - name: cd {{ code_dir }} && git clone {{ url }} .
    - unless: ls {{ code_dir }}/project.yml
    - onlyif: test -z "$(ls -A {{ code_dir }})"

{% else %}

git_clone_project:
  git.cloned:
    - name: {{ url }}
    - target: {{ code_dir }}
{% if branch %}
    - branch: {{ branch }}
{% endif %}

{% endif %}

{{ code_dir }}/project.yml:
  file.exists:
    - require:
        - git_clone_project
