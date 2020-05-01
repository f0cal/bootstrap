{% set code_dir = pillar['cli']['code_dir'] %}
{% set project_yml = "%s/project.yml" | format(code_dir) %}
{% set project = salt["file.read"](project_yml) | load_yaml %}

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
        project: {{ project }}
    - require:
{% for repo in project.repos %}
      - cmd: git-diff--{{ code_dir }}/{{ repo.name }}
{% endfor %}

