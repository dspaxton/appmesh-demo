#!/bin/bash
source cfvars
 helm upgrade -i appmesh-controller eks/appmesh-controller \
     --namespace appmesh-system \
     --set region=$AWS_REGION \
     --set serviceAccount.create=false \
     --set serviceAccount.name=appmesh-controller \
     --set tracing.enabled=true \
     --set tracing.provider=x-ray   
for x in $(kubectl -n my-apps get deployments.apps -o jsonpath='{.items..metadata.name}'); do 
    if [[ "$x" == ingress-gateway ]]; then
        echo "Not touching the ingress gateway"
    else
        echo "Modifying label on deployment $x"
        kubectl -n my-apps patch deployment $x  -p "{\"spec\":{\"template\":{\"metadata\":{\"labels\":{\"date\":\"`date +'%s'`\"}}}}}"
    fi
done 
