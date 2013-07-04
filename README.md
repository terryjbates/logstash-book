logstash-book
=============

Repo storing work done walking through "The LogStash Book" by James Turnbull.

Origins
=======

I deal with a ton of logs all day at work. Something that would make these less of a burden to handle, mangle, and extract useful information from would be handy. One of the vague recollections I have of watching Etsy present on topics like DevOps was how they shot almost all sorts of things into a search engine. Chat, error messages, notifications, all sent to a search engine, so that data could be had later on. Stumbled upon discussion of [LogStash](http://logstash.net) so I dove in and began stepping through [Mr. Turnbull's book](http://www.logstashbook.com) from start to finish. 

Initially was tearing my Macbook to shreds, trying to deploy ElasticSearch and other items, even though the conventions within the book presumed a Linux environment. Thought use of [Vagrant](http://www.vagrantup.com) would be a good idea, since could easily bring up and tear down VMs more easily than shove the dependencies onto my laptop. This also makes it easy to configure an analogous network topology as described in the text. The instructions presume Linux systems, so using Vagrant and snagging Ubuntu base boxes worked out pretty well. Afterwards, I was mostly able to execute the commands exactly as seen in book, without having to map them onto Mac OS X. If I hate what I have done, can recreate the OS in 3 minutes or so.

Vagrant
=======

I use two different Vagrant VMs. The first being *central*, the system housing the LogStash program, the ElasticSearch and Redis servers as well. The *shipper* is the system shipping log data over to the *central* system. 

```
vagrant up central
```

To bring up the "logstash_shipper" machine:

```
vagrant up shipper
```

If you want to start from scratch, you can destroy the box entirely or just reload it:

```
vagrant reload central
vagrant reload shipper
```

Puppet Provisioning
==================

I initially did not learn enough about Puppet or Chef to use these to provision the boxes. I started out using plain old shell commands to do things like `apt-get` and get the machines into a working configuration. I was being silly and made a separate NFS mounted directory called `/vagrant_data`, forgetting that there already is an existing mount under `/vagrant.` For ease of use, I have stashed all the config files and packages used in provisioinng in the top-level directory.

Since I have learned Puppet well enough to actually use it, I created a `manifests` directory and crafted separate .pp files for both `central` and `shipper.` Modifying `Vagrantfile` and mirroring the current set of systems should make it easy to drop in different hosts and then have them shoot data to `central.`


Book Text
=========

I tried to follow the book as closely as possible, including the hostnames and IP addresses used in the text. Some modifications had to be made; for example, the IP address for the `central` machine has to be set to 10.0.0.2, rather than 10.0.0.1, since Vagrant reserves 10.0.0.1 for the host system itself. Am guessing the presumption was that this would be set up on hardware, or maybe that there was greater control over IP addressing with different VM software. 

