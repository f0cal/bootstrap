
project:
  salt.runner:
    - name: state.orchestrate
    - arg:
        - _states.project
    - pillar: {{ pillar | tojson() }}
    - saltenv: {{ saltenv }}

clone:
  salt.runner:
    - name: state.orchestrate
    - arg:
        - _states.clone
    - pillar: {{ pillar | tojson() }}
    - saltenv: {{ saltenv }}
    - require:
        - salt: project

env:
  salt.runner:
    - name: state.orchestrate
    - arg:
        - _states.env
    - pillar: {{ pillar | tojson() }}
    - saltenv: {{ saltenv }}
    - require:
        - salt: clone

test:
  salt.runner:
    - name: state.orchestrate
    - arg:
        - _states.test
    - pillar: {{ pillar | tojson() }}
    - saltenv: {{ saltenv }}
    - require:
        - salt: env

# TODO: Re-enable after fixing these tests
# TODO: ensure optional so we can test that bootstrapped install runs without the tests.
# run_integration_tests:
#   salt.runner:
#     - name: state.orchestrate
#     - arg:
#         - integration_tests
#     - pillar: {{ pillar }}
#     - saltenv: {{ saltenv }}
#     - require:
#         - salt: install_repos
#         # - salt: run_unit_tests

# TODO: Re-enable after fixing integration tests.
# git_push:
#   salt.runner:
#     - name: state.orchestrate
#     - arg:
#         - git_push
#     - pillar: {{ pillar }}
#     - saltenv: {{ saltenv }}
#     - require:
#         - salt: run_integration_tests

# pypi_push:
#   salt.runner:
#     - name: state.orchestrate
#     - arg:
#         - pypi_push
#     - pillar: {{ pillar }}
#     - saltenv: {{ saltenv }}
#     - require:
#         - salt: git_push
