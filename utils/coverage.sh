#!/bin/zsh
forge coverage --report lcov && ekhtml lcov.info --branch-coverage --output-dir coverage

