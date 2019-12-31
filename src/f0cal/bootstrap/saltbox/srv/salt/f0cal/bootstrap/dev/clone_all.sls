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

{{ url }}:
  git.latest:
    - target: {{ path }}
{% if branch %}
    - branch: {{ branch }}
{% endif %}
{% if https_user %}
    - https_user: {{ https_user }}
{% endif %}
    - unless:
        - ls {{ path }}

{% endfor %}
