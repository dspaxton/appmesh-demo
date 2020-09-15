#!/bin/bash
source cfvars
aws appmesh --region $REGION create-route --cli-input-json file://mac-routes.json
