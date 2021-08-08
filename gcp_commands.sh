# set zone / region, project
gclud auth list
gcloud projects list
gcloud config set compute/zone us-east1-b
gcloud config set compute/region us-east1
gcloud config set project my-project


#### Virtual machine instance
# create vm instance
gcloud compute instances create nucleus-jumphost --machine-type f1-micro ## or if this doesn't work, set it up manually in the ui


### Kubernetes service cluster
# create a kubernetes cluster
gcloud container clusters create my-cluster
gcloud container clusters get-credentials my-cluster

# deploy and image
kubectl create deployment hello-server --image=gcr.io/google-samples/hello-app:2.0
# expose the app on port 8080 
kubectl expose deployment hello-server --type=LoadBalancer --port 8080
watch -n 1 kubectl get service ## check until an external ip has been assigned

#### HTTP load balancer
# Create startup script
cat << EOF > startup.sh
#! /bin/bash
apt-get update
apt-get install -y nginx
service nginx start
sed -i -- 's/nginx/Google Cloud Platform - '"\$HOSTNAME"'/' /var/www/html/index.nginx-debian.html
EOF

# Create an instance template
gcloud compute instance-templates create nginx-template --metadata-from-file startup-script=startup.sh

# Create a target pool
gcloud compute target-pools create nginx-pool

# Create managed instance group
gcloud compute instance-groups managed create nginx-group --base-instance-name nginx --size 2 --template nginx-template --target-pool nginx-pool
gcloud compute instances list

# Create firewall rule to allow traffic (80/tcp)
gcloud compute firewall-rules create www-firewall --allow tcp:80
gcloud compute forwarding-rules create nginx-lb --ports=80 --target-pool nginx-pool
gcloud compute forwarding-rules list

# Create a health check
gcloud compute http-health-checks create http-basic-check
gcloud compute instance-groups managed set-named-ports nginx-group --named-ports http:80

# Create a backend service, and attach the managed instance group
gcloud compute backend-services create nginx-backend --protocol HTTP --http-health-checks http-basic-check --global
gcloud compute backend-services add-backend nginx-backend --instance-group nginx-group --global

# Create a URL map, and target the HTTP proxy to route requests to your URL map
gcloud compute url-maps create web-map --default-service nginx-backend
gcloud compute target-http-proxies create http-lb-proxy --url-map web-map

# Create a forwarding rule
gcloud compute forwarding-rules create http-content-rule --global --target-http-proxy http-lb-proxy --ports 80
gcloud compute forwarding-rules list

