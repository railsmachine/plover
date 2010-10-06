### Plover

Plover is a capistrano script that let's you spin up and shutdown ec2 servers on the fly, and will handle mapping the roles for you.  We use it at RailsMachine to spin up staging servers for client code testing.  It relies on cloud-init from Ubuntu, the fog gem, and capistrano to do the heavy lifting.

### Installing Plover

Plover is a capistrano plugin, so just install it like any other rails plugin and be sure to load the recipe in your rake file.

`script/plugin install git@github.com:railsmachine/plover.git`

### Configuring Plover

Plover uses a simple yaml file (config/plover.yml) to configure options, here is a quick example:


    aws_access_key_id: XXXXXXXXXX
    aws_secret_access_key: XXXXXXXXXXXXXXXXXXX
    groups:
      - my_app
      - ssh
    servers:
    - flavor_id: m1.small
      image_id: ami-2d4aa444
      role: db
      name: db1.staging.railsmachine.com
      group: db
      options:
        primary: true
    - flavor_id: m1.small
      image_id: ami-2d4aa444
      role: db
      name: db2.staging.railsmachine.com
      group: db
      options:
        slave: true
    - flavor_id: m1.small
      image_id: ami-2d4aa444
      role: app
      name: app1.staging.railsmachine.com
      groups:
        - app
        - web


Plover will use this configuration to spin up and write out the config/plover_servers.yml file, which contains the server id and dns name of the instance.  Plover also uses cloud-init to configure the instance on boot, here is an example cloud-init to run apt-get upgrade and do a custom command:

    #cloud-config
    apt_upgrade: true
    runcmd:
     - [ wget, "http://slashdot.org", -O, /tmp/index.html ]
     
[Learn more about Ubuntu cloud-init](https://help.ubuntu.com/community/CloudInit)

### Using Plover

Once it is configured, Plover is very easy to use.

`cap plover:provision`

and

`cap plover:shutdown`