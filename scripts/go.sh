#!/bin/bash
# This script should be placed in /etc/profile.d
# It define default values for go

export GOPATH=$HOME/go
export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin
