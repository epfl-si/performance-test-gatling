## Gatling tests on AWS EC2

### Setup
    ./bin/setup.sh

### ec2.py
Is a wrapper script for common operations on ec2 nodes. Before using it, load the virtual environment or install the `requirements.txt` on your system:

    |aws-ec2>source ENV/bin/activate
    (ENV) |aws-ec2>./ec2.py -h
    usage: ec2.py [-h] [-t TYPE] [-p PROFILE] [-c COUNT] [-w] [-i] [-L LOGFILE]
                  [-v]
                  command [command ...]

    Manage Amazon EC2 servers.

    positional arguments:
      command               Command to be executed: available commands are: list,
                            create, start, stop, destroy

    optional arguments:
      -h, --help            show this help message and exit
      -t TYPE, --type TYPE  Select EC2 instance type. Default=t2.micro for create
                            and 'any' for start.
      -p PROFILE, --profile PROFILE
                            AWS profile to use for authentication (see
                            ~/.aws/credentials).
      -c COUNT, --count COUNT
                            Number of instances to [create|start].
      -w, --wait            Wait for long command to completed (create, start,
                            stop)
      -i, --ip              For 'list' command: list only ip addresses or running
                            nodes.
      -L LOGFILE, --logfile LOGFILE
                            log into file instead of stderr
      -v, --loglevel        increase program verbosity

    An attempt to simplify the Boto3 API for AWS

As you can see from the help output above, the main commands are: `list`, `create`, `start`, `stop`, `destroy`.
When creating new nodes, one needs to specify how many `-c COUNT`, and of which type `-t TYPE`. Most common types are the following:

| Name         | vCPUs   |  Mem(Gb)  |   NetBW        |
| ------------ | ------- | --------- | -------------- |
| t2.micro     |     1   |     1     |   Low          |
| ..           |    ..   |    ..     |   ..           |
| t2.large     |     2   |     8     |   Low          |
| t2.xlarge    |     4   |    16     |   Moderate     |
| m5.large     |     2   |     8     |   up to 10Gbit |
| m5.xlarge    |     4   |    16     |   up to 10Gbit |
| m5.24xlarge  |     8   |    32     |   up to 10Gbit |
| ..           |    ..   |    ..     |   ..           |
| m5.12xlarge  |    48   |   192     |   10Gbit       |
| m5.24xlarge  |    96   |   348     |   25Gbit       |

Hence, to create 2 instances of `t2.micro` (create will automatically also start the instances):

    (ENV) |aws-ec2> ./ec2.py -c 2 -t t2.micro create
    (ENV) |aws-ec2>./ec2.py list
    Pending:
       1  i-000da30c5ac3cc796   t2.micro  N/A
       2  i-05562d06fb4604d96   t2.micro  N/A

    (ENV) |aws-ec2>./ec2.py list
    Running:
       1  i-000da30c5ac3cc796   t2.micro  18.195.229.53   initializing    initializing        
       2  i-05562d06fb4604d96   t2.micro  35.157.172.192  initializing    initializing        

    (ENV) |aws-ec2>./ec2.py list
    Running:
       1  i-000da30c5ac3cc796   t2.micro  18.195.229.53   ok            ok
       2  i-05562d06fb4604d96   t2.micro  35.157.172.192  initializing  initializing        

    (ENV) |aws-ec2>./ec2.py list
    Running:
       1  i-000da30c5ac3cc796   t2.micro  18.195.229.53   ok            ok
       2  i-05562d06fb4604d96   t2.micro  35.157.172.192  ok            ok

Once the machine is running, they can be configured:

    (ENV) |aws-ec2> ./bin/provision.sh

And then you can ssh into them for running the tests:

    (ENV) |aws-ec2> $(././ec2.py ssh) 18.195.229.53 'cd data && ./run.sh ActuHome'

