#!/bin/bash

set -eu -o pipefail

# Push both stdout and stderr to /var/log/user-data.log
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
