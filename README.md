# Plank, a discussion board designed for Dropbox #

Plank is a local web server designed to serve a simple discussion board to your local browser. It is built to use a shared Dropbox folder as a single database that is then distributed to each user.

Plank uses Sinatra to provide a simple web interface to the discussion board and DirtyDB (an experimental file store) for storing all the necessary data in a shared folder.

Plank is designed to use Dropbox as the central database, meaning there is no reliance on hosted web forum or publicly accessible forum. Instead it all runs from the comfort of your local machine and the shared Dropbox folder.

Each row/entry/etc for each class is stored as a single file reducing the need for merging or collisions. It currently uses MessagePack to provide the serialisation and deserialisation.

## Getting started ##

To make life easier I suggest making a soft sym link to the plank executable:

`sudo ln -s /path/to/plank/clone/plank /usr/bin/plank`


And then from the terminal you can **cd** to your shared Dropbox folder, start plank simply with

`plank`

and Plank will create the DB if needed as well as locally create a user settings file. Once you open up the forum at the usual web address of http://localhost:4567 you will be asked to create a quick profile and then you are free to go.

## What it currently provides ##

* A simple thread & post interface
* Ability to email participants of new posts using the gem mail (and sendmail)

### What it will provide in the future ###

* Ability to upload files into your shared Dropbox
* Better collaborative interface
* A good UI
* Improved AJAX2.0 speccy refreshing/submitting
* A better way to bootup the server (Cocoa app, etc)

## What will you you need? ##

Ruby and the follows gems (or just use Bundler)
* sinatra
* mail
* msgpack
* Not a Windows machine