# Yet Another Backup Utility for Codea #

## Introduction ##

This is yet another backup utility for the awesome iPad programming
program [Codea](http://codea.io).  The purpose of this one is to
transfer files between a computer and an iPad or between two iPads
without using external services (such as github).

## Usage ##

The file `Main` needs to be saved into a fresh project in Codea on the
iPad.  Some configuration is necessary.

Firstly, it needs a list of the available projects.  As Codea does not
yet have a method to list all projects, this needs to be hard-coded
in.  It is possible to use AirCode to get such a list on a computer
which then can be copied across to the iPad.  (Note that it is
possible to make this list incomplete; this can be useful to exclude
certain projects from the process.)

The iPad can act as server or client, the `isServer` boolean decides
this.  When the other machine is the computer, the iPad has to be the
server.  When two iPads are being used, one needs to be the server and
the other the client.

The logic of the process is as follows:

1. The server opens a socket, displaying the ip and port for the
client to connect to.
2. The client connects to this ip and port.
3. The client sends a message which determines the direction of the
flow of information (from server to client, or from client to server).
4. Based on this, two machines now redesignate themselves as _sender_
and _receiver_.
5. The receiver sends a list of projects and/or tabs to the sender.
6. The sender checks each project and tab against its filesystem, and
against its own list of projects or tabs.  The eventual list of tabs
to be sent is the intersection of these lists.  In these lists, a
project counts as all the tabs in that project.  A completely empty
list means "all possible (or allowed) tabs".
7. The sender starts sending the projects one by one.  Each
communication starts with the project and tab name and then a hash
(computed using a pure lua CRC32 implementation) is sent.  The
receiver compares the hash against the equivalent local one and
communicates the result back to the sender.
8. If the hashes are different, or the file doesn't exist on the
receiver, the file is sent.

Thus the information each program needs to know is as follows:

* *Server*: A list of projects and/or tabs to work with.
* *Client*: 
  * The ip address and port to connect to
  * The desired action ("send" or "get")
  * A list of projects and/or tabs to work with.

In addition, whichever will be the receiver has a `dryrun` flag which
means that it will skip the step at which it saves the received file
(but only that step, the file will still be transferred).

In the iPad program, this information is supplied by editing the code
at the top of the `Main` tab.  In the computer program, this
information is supplied on the command line.  The syntax is

~~~
  -help    Display this message
  -action  Action to take ("get" or "send")
  -ip      IP address of server
  -port    Port for connection
  -dryrun  Dry run
~~~
The options can be shortened to single letters, and the port and ip
address can be specified in a single option as, for example, `-i
10.0.0.3:41354`.  After the options are given, the list of projects
and/or tabs is given.

## History ##

The reason for this utility is that I used to backup my Codea projects
simply by connecting my iPad to my computer and copying the files onto
the computer.  To access the files, I used programs built on top of
the `libimobiledevice` library.  That worked fine when Codea allowed
access to the `Documents` directory, but that facility was
unfortunately removed.

This method seemed very straightforward to me.  Once the files were on
my computer, I could version control them or upload some to github or
whatever.  Such things were easy on a computer.

Although I've used projects like `AutoGist` and `Codea Community` for
sharing my projects, I find them a bit awkward for a general archiving
system.  Using third-party sites, even as reliable as github, for
simply transferring files a distance two feet feels overkill.  And I
didn't like having to have extra dependencies in my projects.

I did some experimenting with AirCode, but ran into a few issues.

Eventually, I realised that now that Codea had sockets, that would be
the easiest way to achieve my goals.
