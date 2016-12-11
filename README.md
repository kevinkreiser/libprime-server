[![Build Status](https://travis-ci.org/kevinkreiser/libprime-server.svg?branch=master)](https://travis-ci.org/kevinkreiser/libprime-server)

What is this?
-------------

Packaging for debian (ubuntu really) was a mystery to me until @sneetsher helped me to figure it out. Check out `build.sh` to see how we are now packing prime_server into its library, devel and bin packages. It also has links and notes about how to get those packages onto your PPA. Enjoy and thanks again @sneetsher!

What should I do?
-----------------

So you have a normal autotools project (maybe its c maybe its c++) and you want to turn it into a package behind a PPA. You want someone to be able to just add your ppa, and install your software without having to build it and know all the dependencies and all that fun stuff. Well I'm here to tell you you're out of luck.. You've probably searched around the internet to find a way to build this type of thing and ended up utterly confused. I was where you were and I'm hoping this README can help you.

The first thing you need to do is look at this [http://packaging.ubuntu.com/html/index.html](http://packaging.ubuntu.com/html/index.html)

It's got tons and tons of information in it but there are really only 2 parts that you'll probably need to worry about. The first thing you should do is follow the steps to setup a launchpad account: [http://packaging.ubuntu.com/html/getting-set-up.html](http://packaging.ubuntu.com/html/getting-set-up.html)

When you're done with that you should have your fingerprint and your launchpad login squared away. When you are ready to put some code and packages into launchpad you'll want to head over to: [https://launchpad.net/~](https://launchpad.net/~)

Click the link labled `Create new PPA` and give it a name. Mine was `prime_server`. Now you're ready to start building packages.

There is actually a pretty nice tutorial on how to do this but the example is a bit trivial such that it doesn't teach you quite enough to get going. Specifically I wanted to build libs, dev and bins packages but it only shows you how to do bins. Here's that step by step process: [http://packaging.ubuntu.com/html/packaging-new-software.html](http://packaging.ubuntu.com/html/packaging-new-software.html)

One thing that does come out of this is the creation and manual editing of the stuff in the `debian` directory. You'll want to do this at least once after which, you can squirrel that `debian` directory and your manual edits away because you can use it to create packages in an automated fashion.

After utterly failing at using that to do what I wanted I posed a [question](http://packaging.ubuntu.com/html/packaging-new-software.html) on askubuntu.com which @sneetsher was kind enough to hand hold me through. Most of what was needed was proper editing of the contents of the `debian` directory. The result of that is this [script](local.sh) and this [debian](debian) directory. You'll see that it will basically build packages on your system for your specific version of Ubuntu. Extra work is needed to sign these and push them up to your PPA. Which, you could do, but then only users who are running your version of Ubuntu could make use of them. That's why someone created `pbuilder`.

So `pbuilder` and its associated tools are awesome. They basically let you setup a vanilla environment of whatever version of Ubuntu you want (except Utopic for some reason...) for the purpose of testing out your package build. This is great because it basically lets you check to see if your package will be able to build on the launchpad servers. So with that information I threw together this [script](build.sh). This will produce all the stuff you need to push to your ppa but wont actually push anything.

To actually push stuff to your PPA you'll want to try out something like this [script](publish.sh). This puts a branch with your code in your PPA (which is required or your packages won't be usable by others). It then signs (using the fingerprint you made with your launchpad account) and pushes your package sources to your PPA. Once pushed launchpad will accept or reject them, if accepted they'll build and hopefully pass and become available via your PPA. If rejected you'll get an email telling you why.
