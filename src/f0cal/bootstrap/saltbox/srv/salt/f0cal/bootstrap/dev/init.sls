
write_repo_list:
  salt.runner:
    - name: state.orchestrate
    - arg:
        - dev.repo_list
    - pillar: {{ pillar }}
    - saltenv: {{ saltenv }}

clone_repos:
  salt.runner:
    - name: state.orchestrate
    - arg:
        - dev.clone_all
    - pillar: {{ pillar }}
    - saltenv: {{ saltenv }}
    - require:
        - salt: write_repo_list

install_repos:
  salt.runner:
    - name: state.orchestrate
    - arg:
        - dev.venv
    - pillar: {{ pillar }}
    - saltenv: {{ saltenv }}
    - require:
        - salt: clone_repos

# run_unit_tests:
#   salt.runner:
#     - name: state.orchestrate
#     - arg:
#         - dev.test
#     - pillar: {{ pillar }}
#     - saltenv: {{ saltenv }}
#     - require:
#         - salt: install_repos

run_integration_tests:
  salt.runner:
    - name: state.orchestrate
    - arg:
        - dev.integration_tests
    - pillar: {{ pillar }}
    - saltenv: {{ saltenv }}
    - require:
        - salt: install_repos
        # - salt: run_unit_tests

git_push:
  salt.runner:
    - name: state.orchestrate
    - arg:
        - dev.git_push
    - pillar: {{ pillar }}
    - saltenv: {{ saltenv }}
    - require:
        - salt: run_integration_tests

pypi_push:
  salt.runner:
    - name: state.orchestrate
    - arg:
        - dev.pypi_push
    - pillar: {{ pillar }}
    - saltenv: {{ saltenv }}
    - require:
        - salt: git_push
