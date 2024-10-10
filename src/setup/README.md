### cloudformation-template.yaml

File contains the necessary pre-requisites for the terraform role to work.
This needs to be run locally to ensure there is a bucket, dynamodb table, role, and policies tying it all together for this repo to use

### tf-manage-backend.sh

Allows for the easy creation, update, or delete of the template

## To run this:

1. Make any necessary changes to the cloudformation tempalte
2. Run `./tf-manage-backend.sh`
3. Answer the prompts
   - For this repo it would be
     - name of the app: airbyte-poc
     - repo: eraliod/airbyte-poc
     - bucket unique identifier: something to make the bucket unique because aws ucket names must be globally unique. (e.g., "rand123", "[github username]")
