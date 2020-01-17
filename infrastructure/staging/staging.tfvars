bucket_name = "strava-feedme"
region = "eu-west-1"
environment = "staging"
appname = "strava-feedme"

state_bucket = "strava-feedme-remotestate"
state_file = "state/env=staging/strava_feedme_eu-west-1_staging.tfstate"

image_name = "metabase/metabase"
image_tag = "latest"

vpc_cidr             = "10.0.0.0/16"
public_subnets_cidr  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnets_cidr = ["10.0.10.0/24", "10.0.20.0/24"]
availability_zones =  ["eu-west-1a", "eu-west-1b"]
http_inbound_eni_ip = "151.96.254.3/32"

allocated_storage = 20
instance_class = "db.t2.micro"
database_name = "stravafeedme"
database_username = "agasta"
database_password = ""

