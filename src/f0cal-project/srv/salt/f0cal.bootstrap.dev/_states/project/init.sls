{% set url = salt['pillar.get']("cli:git_url", None) %}
{% set default_url = "git@github.com:f0cal/project.git" %}
{% set code_dir = pillar['cli']['code_dir'] %}
{% set branch = salt['pillar.get']("cli:branch", None) %}

{% set dir_exists = salt['file.directory_exists'](code_dir) %}
{% set dir_empty = salt['cmd.run']('test -z "$(ls -A {{ code_dir }})"') %}

{% if dir_exists and dir_empty %}

git_clone_project:
  cmd.script:
    - source: salt://{{ slspath }}/clone_into_empty.sh
    - args: {{ url|default(default_url, True) }} {{ code_dir }}

{% elif dir_exists %}

git_clone_project:
  cmd.script:
    - source: salt://{{ slspath }}/clone_into_nonempty.sh
    - args: {{ url|default(default_url, True) }} {{ code_dir }}
    - unless: ls {{ code_dir }}/.git

{% else %}

git_clone_project:
  git.cloned:
    - name: {{ url|default(default_url, boolean=true) }}
    - target: {{ code_dir }}
{% if branch %}
    - branch: {{ branch }}
{% endif %}

{% endif %}

{{ code_dir }}/project.yml:
  file.exists:
    - require:
        - git_clone_project
