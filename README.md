# What
This is to show name constraints and how they can be created in `openssl`

# Why
This stuff is hard.

# How
1. Run `make build`
2. Install `./out/root/cert.crt` as a trusted root certificate in your local trust store.  It will be called "Example Root CA"
3. Install `my.example.com` in your HOSTS file to refer to 127.0.0.1
4. Install `bad.tld` in your HOSTS file to refer to 127.0.0.1
5. Run `make nginx`
6. Go to [https://my.example.com](https://my.example.com)
7. Run `make bad-nginx`
8. Go to [https://bad.tld:8443](https://bad.tld:8443)

# Uninstall
1. `docker rm nginx --force`
2. `docker rm bad-nginx --force`
3. Remove `my.example.com` in your HOSTS file
4. Remove `bad.tld` in your HOSTS file
6. Remove the "Example Root CA" certificate from your local trust store.