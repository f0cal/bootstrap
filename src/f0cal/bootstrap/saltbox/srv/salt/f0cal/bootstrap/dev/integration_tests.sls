{% set code_dir = pillar['cli']['code_dir'] %}

integration_tests:
  cmd.run:
    - name: run-parts {{ code_dir }}/tests/integration --arg {{ code_dir }}
    - cwd: {{ code_dir }}/farm-api
    - env:
        - LC_CTYPE: 'en_US.UTF-8'
        - LANG: 'en_US.UTF-8'
