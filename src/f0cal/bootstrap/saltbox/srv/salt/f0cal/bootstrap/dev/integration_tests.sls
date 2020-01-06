{% set code_dir = pillar['cli']['code_dir'] %}
{% set f0cal_env = salt['pillar.get']("cli:f0cal_env", "dev") %}

integration_tests:
  cmd.run:
    - name: run-parts {{ code_dir }}/tests/integration --arg {{ code_dir }} --arg {{ f0cal_env }}
    - cwd: {{ code_dir }}/device-farm
    - env:
        - LC_CTYPE: 'en_US.UTF-8'
        - LANG: 'en_US.UTF-8'
