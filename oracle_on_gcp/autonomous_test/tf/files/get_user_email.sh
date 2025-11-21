#!/bin/bash
set -e
email=$(gcloud auth list --format="value(account)" | head -n 1)
printf '{"email":"%s"}' "$email"
