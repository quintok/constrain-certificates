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

# What do I need to know?
1. in intermediate.conf is the crux of the code.  It uses name constraints saying `.example.com` is the only valid dns under this CA.  That's why 'bad' doesn't work

# Things I learnt
1. Chrome doesn't like v1 CAs, which is why I had to use `-extensions v3_ca` and added the `root.conf` file.
2. `conf` files are very complicated and can do a *lot*
3. `openssl s_client -connect` is pretty quiet about the failure for bad.tld.  The second last line says "Verify return code" which is 20 for bad.tld.  Otherwise you wouldn't know.
4. Not everything bothers to check the trust chain for name constraints