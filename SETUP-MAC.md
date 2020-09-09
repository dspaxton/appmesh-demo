# Setting up a Mac for EKS App Mesh Demo 

#### Install kubectl
```
sudo curl --silent --location -o /usr/local/bin/kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.16.12/2020-07-08/bin/darwin/amd64/kubectl

sudo chmod +x /usr/local/bin/kubectl
```
This [link](https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html) will direct to the latest versions of kubectl.

#### Install of eksctl 

We need to download the [eksctl](https://eksctl.io/) binary:
```
curl --silent --location "https://github.com/weaveworks/eksctl/releases/download/latest_release/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp

sudo mv -v /tmp/eksctl /usr/local/bin

```

Confirm the eksctl command works:
```
eksctl version
```

Alternatively, if you have homebrew installed, you can execute 

```
brew install kubectl && brew install eksctl 
```

#### Install Helm
```
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 > get_helm.sh
chmod 700 get_helm.sh
./get_helm.sh
```
Now return to the [README.md](README.md) file to continue 
