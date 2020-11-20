#!/bin/bash

set -e
echo "Running $0"
echo "Ensure expected cli are available (from /usr/bin)"
mysqlsh --version
