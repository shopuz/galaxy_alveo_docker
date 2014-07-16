Vagrant + Galaxy + Alveo + Docker
==================================
This is an attempt to create and distribute a configured galaxy instance as a Docker instance. [Galaxy](http://galaxyproject.org) is configured with a number of tools provided at ``The Alveo Project`` [alveo.edu.au](alveo.edu.au).

Docker is an open platform for distributed applications. It provides an easy mechanism to create and distribute isolated self-contained images. More information about it is available at ``[Docker's Website](https://www.docker.com/)``.


## Required Tools
1. Vagrant - lightweight, reproducible and portable development environments
2. Galaxy - open, web-based platform for data intensive research
3. Docker - open platform for distributed applications for developers and sysadmins

## Usage
1. Create Vagrant virtualbox
First of all, lets create a virtualbox with vagrant inside which we will install docker and start using this image. To install vagrant, go to this page - [http://www.vagrantup.com/downloads](http://www.vagrantup.com/downloads) and download the suitable installer according to your OS. 

2. After installing vagrant, in order to create a virtual machine, we need a Vagrantfile. Create a folder named 'vagrant_galaxy' anywhere that you want to reside the virtual machine at. Open up your terminal / command prompt and navigate into the directory that you created. Inside this directory, issue the command ``vagrant init`` to initialize a virtual machine. This will create a file named 'Vagrantfile' inside the directory. 

Replace the content of ``Vagrantfile`` with the following code:

```
Vagrant.configure("2") do |config|
  config.vm.box = "raring"
  config.vm.box_url = "http://cloud-images.ubuntu.com/raring/current/raring-server-cloudimg-vagrant-amd64-disk1.box"
  # we'll forward the port 8000 from the VM to the port 8000 on the host (OS X)
  config.vm.network :forwarded_port, host: 8000, guest: 8000
  config.vm.synced_folder("vagrant_galaxy", "/vagrant")

  # add a bit more memory, it never hurts. It's VM specific and we're using Virtualbox here.
  config.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--memory", 2048]
  end
end
```

As you can see, we are creating a ubuntu-raring OS for our virtual machine inside which we shall install docker.

3. Now lets bootup the virtual machine with the command ``vagrant up``. This will download the Ubuntu OS, install on the virtual machine and make it ready for us to work with.

4. Log into the virtual machine with ``vagrant ssh``

5. Now that we are inside the virtual machine, lets install ``Docker``. Issue the following commands to do so.
```
# Install Docker with LXC
sudo apt-get install linux-image-extra-$(uname -r) software-properties-common
sudo sh -c "wget -qO- https://get.docker.io/gpg | apt-key add -"
sudo sh -c "echo deb http://get.docker.io/ubuntu docker main > /etc/apt/sources.list.d/docker.list"
sudo apt-get update
sudo apt-get install lxc-docker

```

6. After the docker is installed, now lets start using this image. Just issue the command ``docker run -d -p 8000:8080 shopuz/galaxy_alveo_docker``. To explain the command, it will run the image named shopuz/galaxy_alveo_docker in daemon mode (-d) by binding the port 8000 of host with 8080 of the docker image (-p 8000:8080). Wait a few minutes and go to your web browser to ``localhost:8000`` to see the galaxy alveo instance.


## Develop and Integrate new Galaxy Tools
The galaxy instance comes with a tool generator called ``Tool Factory`` by using which we can create new tools to integrate with galaxy. In this tutorial, we will create a new tool (python) which reverses the first line of the text file. First of all, lets upload the input file to galaxy instance. Run the galaxy instance with instructions given above, go to ``localhost:8000``. Log in with email: ``admin@galaxy.org`` and password : ``admin``. 

### Create a text file
Create a normal text file 'test_file.txt' with one line on it 'This is a test file.'

### Upload Input File
Click on ``Get Data`` on the left panel and click on ``Upload File``. Click on ``Choose File`` and then upload the text file (test_file.txt) you created above.

### Create the Tool
Click on Tool Generator on the Left panel and then click on Tool Factory. 
1. Select the uploaded file from history (test_file.txt)
2. Name the new tool as ``Reverse Text``
3. Select ``Generate a Galaxy Toolshed compatible toolshed.gz`` for creating downloadable tool in the section **Create a tar.gz file ready for local toolshed entry**.
4. You can leave other options as default except the **Interpreter** where you should select ``Python``.
5. Paste the following code into the text box:
```
# reverse order of columns in a tabular file
import sys
inp = sys.argv[1]
outp = sys.argv[2]
i = open(inp,'r')
o = open(outp,'w')
row = i.readline()
rs = row.rstrip().split('\t')
rs.reverse()
o.write('\t'.join(rs))
o.write('\n')
i.close()
o.close()
```

6. Finally Click on ``Execute`` button.
7. This should successfully create the new tool. 
8. From the right pane click on ``ReverseText.toolshed.gz`` and click on ``Save`` button to download the compressed file.
9. Uncompress the file and put it under ``vagrant_galaxy/new_tools``.
10. Edit the tool_conf.xml and add the following code :
```
<section name="Reverse Text" id="reverse_text">
    <tool file="new_tools/ReverseText/ReverseText.xml" />
</section>
```

11. Finally run the command:
`` docker run -i -t -p 8000:8080 -v /vagrant/new_tools:/mnt/galaxy/galaxy-app/tools/new_tools -v /vagrant/new_tools/tool_conf.xml:/mnt/galaxy/galaxy-app/tool_conf.xml shopuz/galaxy_alveo_docker``

12. You should see the integrated tool in your browser.

## Further Readings
Working with volumes in Docker Containers - [https://docs.docker.com/userguide/dockervolumes/](https://docs.docker.com/userguide/dockervolumes/)


## References
1. [https://github.com/bgruening/docker-recipes](https://github.com/bgruening/docker-recipes)
2. [https://ochronus.com/docker-primer-django/](https://ochronus.com/docker-primer-django/)
3. [https://github.com/kencochrane/django-docker](https://github.com/kencochrane/django-docker)
4. [Docker CheatSheet](https://gist.github.com/wsargent/7049221#containers)
5. [First Steps with Docker](http://www.alexecollins.com/content/first-steps-with-docker/)
6. [Docker Port Forwarding](http://fogstack.wordpress.com/2014/02/09/docker-on-osx-port-forwarding/)
7. [SSH Docker](http://jpetazzo.github.io/2014/06/23/docker-ssh-considered-evil/)


