logstash-book
=============

Repo storing work done walking through "The LogStash Book" by James Turnbull.

Origins
=======

I deal with a ton of logs all day at work. Something that would make these less of a burden to handle, mangle, and extract useful information from would be handy. Stumbled upon discussion of LogStash and began stepping through Mr. Turnbull's book from start to finish. 

Initially started following through the book and tearing my Macbook apart with trying to deploy things. Thought use of Vagrant would be a good idea, since could easily bring up and tear down VMs more easily than shove the dependencies onto my laptop. This also makes it easy to configure an analogous network topology as described in the text. The instructions presume Linux systems, so Vagrant and Ubuntu boxes worked out pretty well. Execute the commands exactly as seen in book, without having to translate them.

Vagrant
=======

I create two different Vagrant instances, storing each of them in a separate directory underneath the "vagrant" directory. To bring up the "logstash_central" machine:

```
cd vagrant/logstash_central
vagrant up
```

To bring up the "logstash_shipper" machine:

```
cd vagrant/logstash_shipper
vagrant up
```

If you want to start from scratch, you can destroy the box entirely or just reload it:

```
cd vagrant/logstash_shipper
vagrant reload
```

Shell Provisioning
==================

I have not learned enough about Puppet or Chef to use these to provision the boxes. I use plain old shell commands to do things like "apt-get" and get the machines into a working configuration. Since Vagrant supports use of NFS, I use the "data" directory to store the files, then directory the shell provisioning scripts to copy the files stored there onto the system.  Inside of the shell provisioning script, we direct that "data" be mounted in the VMs as "/vagrant_data." The shell provisioning scripts also do the work of starting up the daemons as well. 


Book Text
=========

I tried to follow the book as closely as possible, including the hostnames and IP addresses used in the text. Some modifications had to be made; for example, the IP address for the logstash_central machine has to be set to 10.0.0.2, rather than 10.0.0.1, since Vagrant reserves 10.0.0.1 for the host system itself. Am guessing the presumption was that this would be set up on hardware, or maybe that there was greater control over IP addressing with different VM software. 

The starting point of the initial commits of files ends with the "Filtering Events with LogStash" chapter.  I unfortunately did not track history as I was working on this. Going forward, the files should have commit messages reflecting what was changed and why.
