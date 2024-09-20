#!/bin/bash

# Change to the root directory
cd ..

# Zip Lambda functions
for func in get_instagram_user_id get_post_comments get_user_post_ids get_all_sentiment_data get_instagram_user_info
do
    cd lambda_functions/$func || exit
    zip -j function.zip handler.py
    cd ../..
done

# Zip the Lambda layer
cd lambda_layers/common_layer || exit
zip -r layer.zip python/
cd ../..

# Change to the deploy directory
cd deploy || exit

# Run Terraform commands
terraform init
terraform plan -out=tfplan
terraform apply tfplan