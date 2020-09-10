source ../../setup/cfvars
docker build -t $ACCOUNTNUMBER.dkr.ecr.$REGION.amazonaws.com/$(basename $PWD) .
docker push $ACCOUNTNUMBER.dkr.ecr.$REGION.amazonaws.com/$(basename $PWD)
