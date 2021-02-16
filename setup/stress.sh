source cfvars
LOADBALANCER=$(kubectl get svc -n my-apps ingress-gateway -o jsonpath="{.status.loadBalancer.ingress[0].hostname}")
cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: stress
  labels:
    app: stress
    version: v1
spec:
  replicas: 1
  selector:
    matchLabels:
      app: stress
      version: v1
  template:
    metadata:
      labels:
        app: stress
        version: v1
    spec:
      containers:
      - name: stress
        image: ${ACCOUNTNUMBER}.dkr.ecr.${AWS_REGION}.amazonaws.com/stress
        imagePullPolicy: Always
        env:
        - name: TARGET
          value: ${LOADBALANCER}
EOF
