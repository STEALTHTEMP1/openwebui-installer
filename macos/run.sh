#!/bin/bash
# Simple helper to run the macOS Swift package
# Works on macOS and Linux as long as Swift is installed
DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR" || exit 1
swift run
