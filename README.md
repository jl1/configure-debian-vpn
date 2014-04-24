configure-debian-vpn
====================

For use with Rackspace Cloud Servers Debian Wheezy 7.

configure server
----------------

 - Create an instance
 - Connect to instance over ssh
 - `echo -e "Host github.com \n   ForwardAgent yes" >> ~/.ssh/config`
 - `apt-get update`
 - `apt-get install -y git`
 - `git clone git@github.com:jl1/configure-debian-vpn ~/vpn`
 - `cd ~/vpn`
 - `./run.sh`

create vpn dialup connection on windows 7/8
---------------------------------------

 - Control panel networking
 - create vpn using IP
 - edit connection properties
 - options -> Unclude Windows logon domain = unchecked
 - security -> Type of VPN = L2TP/IPSec
 - security -> Advanced settings -> Use preshared key = paste value from script output.
 - security -> Data encryption = Maximum
 - security -> Allow these protocols -> Challenge checked, Microsoft CHAPv2 checked
 - OK!
 - dial the connection, paste in username and password values outputted by script.
