#!./ENV/bin/python
# (c) All rights reserved. ECOLE POLYTECHNIQUE FEDERALE DE LAUSANNE,
# Switzerland, VPSI, 2018
import argparse
import boto3
import os
import yaml

# -----------------------------------------------
# EC2 Instance types (selection)
# Name 			vCPUs	Mem(Gb)		NetBW
# t2.micro		   1	   1 		Low
# ..
# t2.large		   2	   8		Low
# t2.xlarge		   4	  16		Moderate
# m5.large		   2	   8		up to 10Gbit
# m5.xlarge		   4	  16		up to 10Gbit
# m5.24xlarge	   8	  32		up to 10Gbit
# ..
# m5.12xlarge	  48	 192		10Gbit
# m5.24xlarge	  96	 348		25Gbit
# -----------------------------------------------

class MyEc2:
	def __init__(self, cfg):
		self.config = cfg
		self.session = boto3.Session(
			profile_name=self.config['profile'], 
			region_name=self.config['region']
		)
		self.ec2_client = self.session.client('ec2')
		self.ec2 = self.session.resource('ec2')

		self.imageId = None
		self.setup_kp()
		self.setup_security_group()

		self.instances_cache={}
		self.status_details_cache=None

	def status_details(self, reload=False):
		if self.status_details_cache is None or reload:
			result = self.ec2_client.describe_instance_status(IncludeAllInstances=True)
			self.status_details_cache={}
			for i in result['InstanceStatuses']:
				id=i['InstanceId']
				d = {
					'InstanceId': id,
					'InstanceState': i['InstanceState']['Name'],
					'InstanceStatus': i['InstanceStatus']['Status'],
					'SystemStatus': i['SystemStatus']['Status'] 
				}
				self.status_details_cache[id] = d
		return(self.status_details_cache)

	def list_available_ips(self):
                ips=[]
		for i in self.instances(status='running'):
			if i.public_ip_address:
				ips.append(i.public_ip_address)
		return(" ".join(ips))

	def list(self):
		result=""
		ii={}
		for i in self.ec2.instances.filter():
			s=i.state['Name']
			ii.setdefault(s, [])
			ii[s].append(i)
		sd=self.status_details()
		fmt="{:4d}  {:20s}  {:10s}   {:16s}    {:20s}  {:20s}\n"
		for s, ilist in ii.items():
			result += "{}:\n".format(s.capitalize())
			for j, i in enumerate(ilist):
				if i.public_ip_address is None:
					result += fmt.format(j+1, i.id, i.instance_type, "N/A", sd[i.id]['InstanceStatus'], sd[i.id]['SystemStatus'])
				else:
					result += fmt.format(j+1, i.id, i.instance_type, i.public_ip_address, sd[i.id]['InstanceStatus'], sd[i.id]['SystemStatus'])
		self.instances_cache = ii
		return(result)

	def instances(self, status='all', reload=False):
		if status not in self.instances_cache or reload:
			filters = [
				{
					'Name': 'instance-state-name', 
					'Values': [status]
				}
			]
			self.instances_cache[status] = []
			for instance in self.ec2.instances.filter(Filters=filters):
				self.instances_cache[status].append(instance)
		return(self.instances_cache[status])

	def create_instances(self, count=1, type='t2.micro', wait=True):
		# Determine the ami id
		if self.imageId is None:
			sel = self.ec2_client.describe_images(
				Owners = ['amazon'], 
				Filters = [
					{
						'Name': 'name',
						'Values': [self.config['ami_name']]
					},
					{
						'Name': 'root-device-type',
						'Values': ['ebs']
					},
					{
						'Name': 'virtualization-type',
						'Values': ['hvm']
					},
					{
						'Name': 'block-device-mapping.volume-type',
						'Values': ['standard']
					}
				]
			)['Images']
			if len(sel) > 0:
				self.imageId = sorted(sel, key=lambda x: x['CreationDate'])[-1]['ImageId']
			print("Using ami image: ".format(self.imageId))
		dd = self.ec2_client.run_instances(
	 		ImageId        = self.imageId,
	 		InstanceType   = type,
	 		MinCount       = count,
	 		MaxCount       = count,
	 		KeyName        = self.kp.name,
	 		SecurityGroups = [self.sg.group_name]
	 	)
		ilist=[]
		for d in dd['Instances']:
			i = self.ec2.Instance(d['InstanceId'])
			ilist.append(i)
		if wait:
			print("waiting for instances to be running state")
			for i in ilist:
				i.wait_until_running()
				i.reload()
				print("Instance {}  {}: {} / {}".format(i.id, i.state['Name'], i.public_ip_address, i.public_dns_name))
		return(ilist)

	def start_instances(self, count=1, type='any', wait=True):
		all_stopped = self.instances(status='stopped', reload=True)

		# for i in all_stopped:
		# 	print("Instance {}  {}: {}".format(i.id, i.state['Name'], i.instance_type))

		if type == 'any':
			ilist = all_stopped
		else:
			ilist = [i for i in all_stopped if i.instance_type == type]

		if len(ilist) == 0:
			print("There are no stopped instances.")
			return

		if count > len(ilist):
			print("Warning: not enough stopped instances. Will start {} instead of {}".format(len(ilist), count))

		ilist = ilist[:count]

		for i in ilist:
			i.start()
		if wait:
			print("waiting for instances to be running state")
			for i in ilist:
				i.wait_until_running()
				i.reload()
				print("Instance {}  {}: {} / {}".format(i.id, i.state['Name'], i.public_ip_address, i.public_dns_name))

	def stop_all_running_instances(self,wait=True):
		ilist = self.instances(status='running', reload=True)
		for i in ilist:
			i.stop()
		if wait:
			print("waiting for instances to be in stopped state")
			for i in ilist:
				i.wait_until_stopped()

	def terminate_all_instances(self):
		self.stop_all_running(wait=True)
		for i in self.ec2.instances:
			i.terminate()

	def setup_security_group(self):
		r=self.ec2_client.describe_security_groups(
			Filters=[{'Name': 'group-name', 'Values': ['devrun-ec2']}]
		)['SecurityGroups']
		if len(r) > 0:
			r = r[0]
		else:
			r = self.ec2_client.create_security_group(
				Description=self.config['sg_description'],
				GroupName=self.config['sg_name']
			)

		gid=r['GroupId']
		self.sg=self.ec2.SecurityGroup(gid)

	def setup_kp(self):
		self.kn = "ec2_{}".format(os.getlogin())
		# response = self.ec2_client.describe_key_pairs().filter(Filters=[""])
		# print(response)

		ssh_key_dir  = os.path.join(os.path.expanduser("~"), ".ssh/aws")
		self.ssh_key_path = os.path.join(
			ssh_key_dir, 
			"{}.pem".format(self.config['region'])
		)

		kp=self.ec2.KeyPair(self.kn)
		if not self.kp_exist(kp):
			d = self.ec2_client.create_key_pair(KeyName=self.kn)
			with open(self.ssh_key_path, 'w') as f:
				f.write(f.write(d['KeyMaterial']))
			kp=self.ec2.KeyPair(self.kn)

		if self.kp_exist(kp):
			self.kp = kp
		else:
			raise NameError('Inconsistency: key should at this point')

	def kp_exist(self, kp):
		try:
			fp=kp.key_fingerprint
			return True
		except:
			return False

if __name__ == '__main__':
	config={
		'region': 'eu-central-1',
		'profile': 'idevelop-ec2',
		'type': "t2.micro",
		'job': None,
		'subnet': "128.178.0.0/15",
		'sg_name': "devrun-ec2",
		'sg_description': 'SG to allow devrun access to ec2 instances',
		'ami_name': 'amzn-ami-hvm-2018.03.*'
	}

	parser = argparse.ArgumentParser(
	    description = 'Manage Amazon EC2 servers.',
	    epilog      = """ An attempt to simplify the Boto3 API for AWS\n"""

	)
	parser.add_argument("-t", "--type", action='store', dest='type', metavar='TYPE', help="Select EC2 instance type. Default=t2.micro for create and 'any' for start.", default=None)
	parser.add_argument("-p", "--profile", action='store', dest='profile', metavar='PROFILE', help="AWS profile to use for authentication (see ~/.aws/credentials).", default="idevelop-ec2")
	parser.add_argument("-c", "--count", action='store', dest='count', type=int, metavar='COUNT', help="Number of instances to [create|start].", default=1)
	parser.add_argument("-w", "--wait", action="store_true", help="Wait for long command to completed (create, start, stop)", default=False)
	parser.add_argument("-i", "--ip", action="store_true", help="For 'list' command: list only ip addresses or running nodes.", default=False)


	parser.add_argument("-L", "--logfile", help="log into file instead of stderr")
	parser.add_argument("-v", "--loglevel", help="increase program verbosity", action="count", default=0)
	parser.add_argument("command", nargs='+', help='Command to be executed: available commands are: list, create, start, stop, destroy')

	opts = parser.parse_args()

	ec2=MyEc2(config)

	for c in opts.command:
		if c == "list":
			if opts.ip:
				print(ec2.list_available_ips())
			else:
				print(ec2.list())
		elif c == "create":
			t = 't2.micro' if opts.type is None else opts.type
			ec2.create_instances(opts.count,  type=t, wait=opts.wait)
		elif c == "start":
			t = 'any' if opts.type is None else opts.type
			ec2.start_instances(opts.count, type=t, wait=opts.wait)
		elif c == "stop":
			ec2.stop_all_running_instances(opts.wait)
		elif c == "destroy":
			ec2.terminate_all_instances()
		elif c == "ssh":
			# print("ssh -i {} -l ec2-user -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no".format(ec2.ssh_key_path))
			print("ssh -i {} -l ec2-user".format(ec2.ssh_key_path))
		elif c == "pssh":
			# print("pssh -x '-i {} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no' -l ec2-user -H '{}' -i".format(ec2.ssh_key_path, ec2.list_available_ips()))
			print("pssh -x '-i {}' -l ec2-user -H '{}' -i".format(ec2.ssh_key_path, ec2.list_available_ips()))
		elif c == "pssh_opts":
			print("pssh -x '-i {}' -l ec2-user -H '{}' -i".format(ec2.ssh_key_path, ec2.list_available_ips()))
		else:
			print("Invalid command ", c)
			exit()
			
