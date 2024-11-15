#!/bin/bash

mv demo-cymbal-air-20-oauth.tf.step2 demo-cymbal-air-20-oauth.tf
mv demo-cymbal-air-92-oauth-vars.tf.step2 demo-cymbal-air-92-oauth-vars.tf

./set-vars.sh

terraform apply