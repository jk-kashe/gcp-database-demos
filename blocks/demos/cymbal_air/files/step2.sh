#!/bin/bash

cp demo-cymbal-air-20-oauth.tf.step2 demo-cymbal-air-20-oauth.tf
cp vars-demo-cymbal-air-oauth.tf.step2 vars-demo-cymbal-air-oauth.tf

./set-vars.sh

terraform apply