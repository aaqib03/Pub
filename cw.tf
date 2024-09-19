provider "aws" {
  region = "ap-south-1"  # Adjust this to your AWS region
}

# Data source to get EC2 instances based on the instance name tag
data "aws_instances" "filtered_instances" {
  filter {
    name   = "tag:Name"
    values = [var.instance_name]  # Replace with the instance name tag
  }

  instance_state_names = ["running", "stopped"]
}

# Fetch instance details to get the root volumes
data "aws_instance" "filtered_instance_details" {
  count       = length(data.aws_instances.filtered_instances.ids)
  instance_id = data.aws_instances.filtered_instances.ids[count.index]
}

# Output to display root volume IDs
output "root_volume_ids" {
  value = flatten([for instance in data.aws_instance.filtered_instance_details : [for root_device in instance.root_block_device : root_device.volume_id]])
}