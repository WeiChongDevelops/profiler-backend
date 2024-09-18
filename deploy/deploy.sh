#!/bin/bash

# Change to the root directory
cd ..

# Zip Lambda functions
for func in get_instagram_user_id get_post_comments get_user_post_ids
do
    cd lambda_functions/$func || exit
    zip -j function.zip handler.py
    cd ../..
done

# Change to the deploy directory
cd deploy || exit

# Run Terraform commands
terraform init
terraform plan -out=tfplan
terraform apply tfplan