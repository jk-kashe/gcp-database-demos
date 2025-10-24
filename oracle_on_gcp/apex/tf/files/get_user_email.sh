#!/bin/bash

# Get the first email address from the gcloud auth list
gcloud auth list --format="value(account)" | head -n 1