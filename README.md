logstash-book
=============

Repo storing work done walking through "The LogStash Book" by James Turnbull.

Origins
=======

I deal with a ton of logs all day at work. Something that would make these less of a burden to handle, mangle, and extract useful information from would be handy. One of the vague recollections I have of watching Etsy present on topics like DevOps was how they shot almost all sorts of things into a search engine. Chat, error messages, notifications, all sent to a search engine, so that data could be had later on. Stumbled upon discussion of [LogStash](http://logstash.net) so I dove in and began stepping through [Mr. Turnbull's book](http://www.logstashbook.com) from start to finish. 

Initially was tearing my Macbook to shreds, trying to deploy ElasticSearch and other items, even though the conventions within the book presumed a Linux environment. Thought use of [Vagrant](http://www.vagrantup.com) would be a good idea, since could easily bring up and tear down VMs more easily than shove the dependencies onto my laptop. This also makes it easy to configure an analogous network topology as described in the text. The instructions presume Linux systems, so using Vagrant and snagging Ubuntu base boxes worked out pretty well. Afterwards, I was mostly able to execute the commands exactly as seen in book, without having to map them onto Mac OS X. If I hate what I have done, can recreate the OS in 3 minutes or so.

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

I have not learned enough about Puppet or Chef to use these to provision the boxes. I use plain old shell commands to do things like `apt-get` and get the machines into a working configuration. Since Vagrant supports use of NFS, I use the `data` directory in this repo to store the configuration files, then direct the shell provisioning scripts to copy the files stored there onto the running VM.  Inside of the shell provisioning script, we direct that `data` be mounted in the VMs as `/vagrant_data.` The shell provisioning scripts also do the work of starting up the daemons as well. 


Book Text
=========

I tried to follow the book as closely as possible, including the hostnames and IP addresses used in the text. Some modifications had to be made; for example, the IP address for the `logstash_central` machine has to be set to 10.0.0.2, rather than 10.0.0.1, since Vagrant reserves 10.0.0.1 for the host system itself. Am guessing the presumption was that this would be set up on hardware, or maybe that there was greater control over IP addressing with different VM software. 

The starting point of the initial commits of files ends with the "Filtering Events with LogStash" chapter.  I unfortunately did not track history as I was working on this. Going forward, the files should have commit messages reflecting what was changed and why.
