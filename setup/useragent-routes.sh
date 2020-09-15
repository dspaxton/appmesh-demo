#!/bin/bash
source cfvars
aws appmesh --region $REGION create-route --cli-input-json file://useragent-routes.json
