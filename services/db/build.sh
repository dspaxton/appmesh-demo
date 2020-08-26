source ../../setup/cfvars
sed  "s/ENDPOINT/$DOCDBENDPOINT/" app.template > app.py
docker build -t $ACCOUNTNUMBER.dkr.ecr.$REGION.amazonaws.com/$(basename $PWD) .
docker push $ACCOUNTNUMBER.dkr.ecr.$REGION.amazonaws.com/$(basename $PWD)
