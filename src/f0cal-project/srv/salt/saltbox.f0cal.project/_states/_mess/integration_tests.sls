{% set code_dir = pillar['cli']['code_dir'] %}
{% set f0cal_env = salt['pillar.get']("cli:f0cal_env", "dev") %}
{% set test_dir = "%s/tests/integration" | format(code_dir) %}

{% for exe in salt['file.readdir'](test_dir) | sort | reject('eq', '.') | reject('eq', '..')  %}

integration_test--{{ loop.index  }}:
  cmd.run:
    - name: {{ test_dir }}/{{ exe }} {{ code_dir }} {{ f0cal_env }}
    - cwd: {{ code_dir }}/device-farm
    - env:
        - LC_CTYPE: 'en_US.UTF-8'
        - LANG: 'en_US.UTF-8'

{% endfor %}