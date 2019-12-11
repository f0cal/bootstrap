{% set code_dir = pillar['cli']['code_dir'] %}

{{ code_dir }}/project.yml:
  file.managed:
      - source: salt://{{ slspath }}/project.yml
      - template: jinja
      - unless:
          - ls {{ code_dir }}/project.yml
