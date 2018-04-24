Performance test gatling
========================

Performance test toolbox with Gatling for IDevelop web applications

Install
-------

```bash
git clone https://github.com/epfl-idevelop/performance-test-gatling.git
cd performance-test-gatling
./bin/install.sh
```

Run
---

Default simulation:

```bash
./gatling/bin/gatling.sh
```

IDevelop simulation:

```bash
./gatling/bin/gatling.sh -sf simulations/
```

IDevelop cluster simulation with gathering of results:

```bash
./bin/cluster-run.sh <simulation_name>
```
Example: `./bin/cluster-run.sh WwwProxy`

Within Docker image with `docker-compose`:
```bash
docker-compose up
```
eventually, pass the list of tests using the `TESTS` environment variable:

```bash
TESTS="TestWwwProxy WwwProxy" docker-compose up
```

The docker image entry script (`bin/docker-ep.sh`) will take care of setting up the simulation directory (`/sim`) either by just acknowledging that it is present (mounted with `docker run -v $PWD:/sim` or by docker-compose), or by pulling a remote git repository. Then it will just source all the scripts passed as command line. The script that is responsible for just running the simulations is `bin/run.sh` and is the one called by docker-compose by default. The scripts are either already present in the `/sim` directory or can be downloaded from an URL.

Run on Amazon AWS Batch service:
--------------------------------
On AWS, we cannot rely on the local mounted volume for storing simulations. Therefore, upon completion the simulation results must be sent to a remote location. Currently the only implemented solution is to save results into an S3 bucket using the `bin/cp2s3.sh` script to be sourced _after_ the standard `bin/run.sh`. Three parameters have to be provided as as environment variables:
  - `S3_BUCKET`: the name of the destination S3 bucket;
  - `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`: credential of an user with write access to the bucket. In theory it should be possible to inherit the credential of the user that is running the job, but I haven't figured out yet how to do this. In any case it is better to generate an IAM user for this purpose and avoid using the master access keys. The user will have access to AWS Batch via the standard `AWSBatchFullAccess` policy), as well as write access to the specific S3 bucket via a custom made policy (e.g. `results_bucket_rw` in our case) which can be created with
  ```bash
  aws create-policy --cli-input-json file://results_bucket_rw.json
  ```
  Where the json file looks like:

  ```json
  {
   "Version": "2012-10-17",
   "Statement": [
       {
           "Sid": "VisualEditor0",
           "Effect": "Allow",
           "Action": "s3:ListBucket",
           "Resource": "arn:aws:s3:::YOUR_S3_BUCKET"
       },
       {
           "Sid": "VisualEditor1",
           "Effect": "Allow",
           "Action": [
               "s3:PutObject",
               "s3:GetObject",
               "s3:DeleteObject"
           ],
           "Resource": "arn:aws:s3:::YOUR_S3_BUCKET/*"
       }
   ]
 }
  ```

It is convenient to configure the newly created IAM user as an alternative profile for CLI:

```bash
aws configure --profile gatling
    AWS Access Key ID [****************LY4Q]:
    AWS Secret Access Key [****************2eRv]:
    Default region name [eu-central-1]:
    Default output format [None]:

```

In order to run AWS batch jobs, the following things have to be configured from the [AWS console](https://eu-central-1.console.aws.amazon.com/batch):
 * __Compute environment__: just give it a name and accept all the defaults.
 * __Job Queue__: juste give it a name and assign the newly created compute environment to it.
 * __Job definition__: this is the real thing. The important parameters are the following
   - __image__: `multiscan/idevelop-gatling:latest`
   - __command__: `-f https://github.com/epfl-idevelop/performance-test-gatling.git run.sh cp2s3.sh`
   - __environment variables__: `TESTS`, `NREP`, `S3_BUCKET`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
   - __ReadOnlyFilesystem__: false
 The job definition can be created from CLI with
 ```bash
    aws batch register-job-definition --job-definition-name gatling --type container --cli-input-json file://gatling_job_def.json
  ```
  where the json file content is the following (with AWS_KEYS removed):
  ```JSON
  {
    "jobDefinitionName": "gatling",
    "jobDefinitionArn": "arn:aws:batch:eu-central-1:524888908611:job-definition/gatling:5",
    "revision": 5,
    "status": "ACTIVE",
    "type": "container",
    "parameters": {},
    "retryStrategy": {
        "attempts": 1
    },
    "containerProperties": {
        "image": "multiscan/idevelop-gatling:latest",
        "vcpus": 1,
        "memory": 512,
        "command": [
            "-f",
            "https://github.com/epfl-idevelop/performance-test-gatling.git",
            "-b",
            "awsdocker",
            "sync.sh",
            "run.sh",
            "cp2s3.sh"
        ],
        "volumes": [],
        "environment": [
            {
                "name": "S3_BUCKET",
                "value": "PUT YOUR HERE"
            },
            {
                "name": "AWS_ACCESS_KEY_ID",
                "value": "PUT YOUR HERE"
            },
            {
                "name": "AWS_SECRET_ACCESS_KEY",
                "value": "PUT YOUR HERE"
            },
        ],
        "mountPoints": [],
        "readonlyRootFilesystem": false,
        "ulimits": []
    }
  }
  ```


Once everything is set, you can start the job using the `aws_submit.sh` script:
```bash
|> ./bin/aws_submit.sh -h

Start Gatling job on AWS.
Options:
  -n NAME    Job name prefix (actual job name will be NAME_datetime)
  -c COUNT   Number of job instances to start [1]
  -t TEST    Name of the gatgling test (class) to start [TestWwwProxy]
  -p PROFILE Name of the profile in ~/.aws/credentials to use (can be repeated)
  -e         Shortcut for -p gatling-eu
  -u         Shortcut for -p gatling-us
  -s SECONDS Period of time between synchronization checks. If present
             triggers syncrhonization.
  -S URL     Countdown server address
  -x SECONDS Timeout for synchronization.
  -m         Add one to worker clients so they can be triggered manually
  -o ORIGIN  Origin for simulation files. Examples:
             a) '-b awsdocker https://github.com/epfl-idevelop/performance-test-gatling.git'
             b) 's3://idevelop-gatling-results/simulations'
  -g         Shortcut for default github origin (example a above)
  -a         Shortcut for default s3 origin (example b above)

```

Example (4 instances of `WwwProxy` test in the dacenter in europe):
```
./bin/aws_submit.sh -e -n myjob -t WwwProxy -c 4
```

Unfortunately, the instances of a job array are not guaranteed to run concurrently. Therefore, we have a synchronisation script (`sync.sh`) that uses a simple web service for keeping track of the jobs that are started. For this, the script needs few more input values: the URL for the synchronisation web service, and, optionally a timeout and check interval. This mechanism can be used to start concurrent jobs on multiple datacenters. Example (last two args are optional):
```
./bin/aws_submit.sh -e -n myjob -t WwwProxy -c 4 -S -s 60 -x 3600 -S http://countdown.epfl.ch/
```


Developers
----------

  * [Olivier Bieler](https://github.com/obieler)
  * [William Belle](https://github.com/williambelle)

Documentation
-------------
  * [Gatling documentation](https://gatling.io/docs/current/)
  * For asking questions, join the [Google Group](https://groups.google.com/forum/#!forum/gatling).

License
-------

Apache License 2.0

(c) ECOLE POLYTECHNIQUE FEDERALE DE LAUSANNE, Switzerland, VPSI, 2018.

See the [LICENSE](LICENSE) file for more details.
