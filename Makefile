# if this session isn't interactive, then we don't want to allocate a
# TTY, which would fail, but if it is interactive, we do want to attach
# so that the user can send e.g. ^C through.
INTERACTIVE := $(shell [ -t 0 ] && echo 1 || echo 0)
ifeq ($(INTERACTIVE), 1)
	DOCKER_FLAGS += -t
endif

.PHONY: help
help:
	@echo -e "$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\x1b[36m\1\\x1b[m:\2/' | column -c2 -t -s :)"

.PHONY: build
build: clean gen-output build-root sign-root build-intermediate sign-intermediate build-certificate sign-certificate build-certificate-bundle build-bad sign-bad build-bad-bundle ## Builds all

.PHONY: build-root
build-root:
	@openssl genrsa -out ./out/root/key.pem 4096
	@openssl req \
	-sha256 \
	-new \
	-key ./out/root/key.pem \
	-out ./out/root/csr.csr \
	-subj "/C=AU/ST=ACT/L=Canberra/O=Example/OU=DevOps/CN=Example Root CA"

.PHONY sign-root:
sign-root:
	openssl x509 \
	-req \
	-days 10000 \
	-in ./out/root/csr.csr \
	-signkey ./out/root/key.pem \
	-out ./out/root/cert.crt
	-extensions v3_ca \
	-extfile root.conf

.PHONY: build-intermediate
build-intermediate:
	@openssl genrsa -out ./out/intermediate/key.pem 4096
	@openssl req \
	-sha256 \
	-new \
	-key ./out/intermediate/key.pem \
	-out ./out/intermediate/csr.csr \
	-subj "/C=AU/ST=ACT/L=Canberra/O=Example/OU=DevOps/CN=Example Intermediate 1"

.PHONY: sign-intermediate
sign-intermediate:
	@openssl x509 \
	-req \
	-sha256 \
	-days 186 \
	-in ./out/intermediate/csr.csr \
	-CA ./out/root/cert.crt \
	-CAkey ./out/root/key.pem \
	-CAcreateserial \
	-out ./out/intermediate/cert.crt \
    -extfile intermediate.conf

.PHONY: build-certificate
build-certificate:
	@openssl genrsa -out ./out/certificate/key.pem 4096
	@openssl req \
	-sha256 \
	-new \
	-key ./out/certificate/key.pem \
	-out ./out/certificate/csr.csr \
	-subj "/C=AU/ST=ACT/L=Canberra/O=Example/OU=DevOps/CN=my.example.com"

.PHONY: sign-certificate
sign-certificate:
	@openssl x509 \
	-req \
	-sha256 \
	-days 10 \
	-in ./out/certificate/csr.csr \
	-CA ./out/intermediate/cert.crt \
	-CAkey ./out/intermediate/key.pem \
	-CAcreateserial \
	-out ./out/certificate/cert.crt \
	-extensions req_ext \
	-extfile certificate.conf

.PHONY: build-certificate-bundle
build-certificate-bundle:
	@cat ./out/certificate/cert.crt ./out/intermediate/cert.crt > ./out/certificate/cert.bundle

.PHONY: build-bad
build-bad:
	@openssl genrsa -out ./out/bad/key.pem 4096
	@openssl req \
	-sha256 \
	-new \
	-key ./out/bad/key.pem \
	-out ./out/bad/csr.csr \
	-subj "/C=AU/ST=ACT/L=Canberra/O=Example/OU=DevOps/CN=bad.tld"

.PHONY: sign-bad
sign-bad:
	@openssl x509 \
	-req \
	-sha256 \
	-days 10 \
	-in ./out/bad/csr.csr \
	-CA ./out/intermediate/cert.crt \
	-CAkey ./out/intermediate/key.pem \
	-CAcreateserial \
	-out ./out/bad/cert.crt \
	-extensions req_ext \
	-extfile bad.conf

.PHONY: build-bad-bundle
build-bad-bundle:
	@cat ./out/bad/cert.crt ./out/intermediate/cert.crt > ./out/bad/cert.bundle

.PHONY: gen-output
gen-output:
	@mkdir -p out
	@mkdir -p out/root
	@mkdir -p out/intermediate
	@mkdir -p out/certificate
	@mkdir -p out/bad

clean: ## Clean the output directory
	@rm -fr out
	@rm -f .srl

.PHONY: nginx
nginx: ## Runs nginx using the certificate
	@docker run -d \
		--name nginx \
		-v $(CURDIR)/out/certificate:/etc/nginx/certs:ro \
		-v $(CURDIR)/nginx.conf:/etc/nginx/nginx.conf:ro \
		-p 443:443 \
		nginx

.PHONY: nginx-bad
nginx-bad: ## Runs nginx using the bad certificate
	@docker run -d \
		--name bad-nginx \
		-v $(CURDIR)/out/bad:/etc/nginx/certs:ro \
		-v $(CURDIR)/nginx-bad.conf:/etc/nginx/nginx.conf:ro \
		-p 8443:443 \
		nginx
