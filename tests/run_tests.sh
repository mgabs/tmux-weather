#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")"

# Add the bats-core bin directory to the PATH
export PATH="$PWD/libs/bats-core/bin:$PATH"

# Run the tests
bats test.sh
