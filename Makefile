GIT_ROOT=.
GIT_EMAIL=55534323+yukikurage@users.noreply.github.com
GIT_NAME=yukikurage

PROJECT=isuumo

NGINX_LOG=/var/log/nginx/access.log

KATARIBE_CFG=/etc/kataribe.toml

DB_HOST=127.0.0.1
DB_PORT=3306
DB_USER=isucon
DB_PASS=isucon
DB_NAME=$(PROJECT)

SLOW_LOG=/var/log/mysql/mysql-slow.log

SLACKCAT_CNL=isucon

LOGS_DIR=/etc/logs

DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/932953641252446238/a9k7cAOO0V0QFZBaURgdgxFnfVVNrNYOgKhpVh_8Q146oTMscx3kvYPwU2Ar10tqd0HX

NGINX_CONFIG=/etc/nginx/nginx.conf
MYSQLD_CONFIG=/etc/mysql/mysql.conf.d/mysqld.cnf
#################################################################################
PPROF=go tool pprof
KATARIBE=kataribe -f $(KATARIBE_CFG)
MYSQL=sudo mysql -h$(DB_HOST) -P$(DB_PORT) -u$(DB_USER) -p$(DB_PASS) $(DB_NAME)
SLACKCAT=slackcat --channel $(SLACKCAT_CNL)
WHEN:=$(shell date +%H:%M:%S)
#################################################################################

.PHONY: pullres
pullres: pull restart

.PHONY: pull
pull:
	cd $(GIT_ROOT) && \
		git pull origin master

.PHONY: commit
commit:
	cd $(GIT_ROOT) && \
		git commit -a

.PHONY: push
push:
	cd $(GIT_ROOT) && \
		git push

.PHONY: restart
restart: restart-nginx restart-mysql restart-app

.PHONY: restart-app
restart-app:
	cd ~/$(PROJECT)/webapp/go && make all
	sudo systemctl restart $(PROJECT).go.service

.PHONY: restart-nginx
restart-nginx: copy-config-nginx
	sudo rm -f $(NGINX_LOG)
	sudo nginx -t
	sudo nginx -s reload
	sudo systemctl restart nginx

.PHONY: restart-mysql
restart-mysql: copy-config-mysqld
	sudo rm -f $(SLOW_LOG)
	sudo systemctl restart mysql

##########################################################################################

.PHONY: copy-config
copy-config: copy-config-nginx copy-config-mysqld

.PHONY: copy-config-nginx
copy-config-nginx:
	sudo cp nginx.conf $(NGINX_CONFIG)

.PHONY: copy-config-mysqld
copy-config-mysqld:
	sudo cp mysqld.cnf $(MYSQLD_CONFIG)

##########################################################################################

.PHONY: dstat
dstat:
	dstat -a -m

.PHONY: mysql
mysql:
	$(MYSQL)

.PHONY: log
log:
	sudo journalctl -u $(PROJECT).go.service

.PHONY: pprof
pprof:
	$(PPROF) -png -output pprof.png http://localhost:6060/debug/pprof/profile?seconds=60
	curl -X POST -F img=@pprof.png $(DISCORD_WEBHOOK_URL)

.PHONY: slow
slow:
	sudo cat $(SLOW_LOG) | mysqldumpslow -s t -t 10 | curl -X POST -H "Content-Type: application/json" -d "{\"content\":\"$(cat)\"}" $(DISCORD_WEBHOOK_URL)

.PHONY: alp
alp:
	cat $(NGINX_LOG) | alp ltsv -m '/api/estate/[0-9]+,/api/chair/[0-9]+,/api/recommended_estate/[0-9]+,/api/estate/req_doc/[0-9]+,/api/chair/buy/[0-9]+' --sort avg -r

.PHONY: alp-sum
alp-sum:
	cat $(NGINX_LOG) | alp ltsv -m '/api/estate/[0-9]+,/api/chair/[0-9]+,/api/recommended_estate/[0-9]+,/api/estate/req_doc/[0-9]+,/api/chair/buy/[0-9]+' --sort sum -r

################################################################################################

.PHONY: install-tools
install-tools: install-git install-unzip install-kataribe install-myprofiler install-pt install-dstat install-graphviz install-slackcat

.PHONY: install-git
install-git:
	sudo apt install -y git # TODO
	git config --global user.email "$(GIT_EMAIL)"
	git config --global user.name "$(GIT_NAME)"

.PHONY: install-unzip
install-unzip:
	sudo apt install -y unzip # TODO

.PHONY: install-kataribe
install-kataribe:
	wget https://github.com/matsuu/kataribe/releases/download/v0.4.1/kataribe-v0.4.1_linux_amd64.zip -O kataribe.zip
	mkdir -p tmp_kataribe
	unzip -o kataribe.zip -d tmp_kataribe
	rm -f kataribe.zip
	sudo cp tmp_kataribe/kataribe /usr/local/bin/
	rm -rf tmp_kataribe
	sudo chmod +x /usr/local/bin/kataribe
	kataribe -generate
	sudo cp kataribe.toml $(KATARIBE_CFG)
	rm -f kataribe.toml

.PHONY: install-myprofiler
install-myprofiler:
	wget https://github.com/KLab/myprofiler/releases/latest/download/myprofiler.linux_amd64.tar.gz -O myprofiler.tar.gz
	tar xf myprofiler.tar.gz
	rm -f myprofiler.tar.gz
	sudo cp myprofiler /usr/local/bin/
	rm -f myprofiler
	sudo chmod +x /usr/local/bin/myprofiler

.PHONY: install-pt
install-pt:
	sudo apt install -y percona-toolkit # TODO

.PHONY: install-dstat
install-dstat:
	sudo apt install -y dstat # TODO

.PHONY: install-graphviz
install-graphviz:
	sudo apt install -y graphviz # TODO

.PHONY: install-slackcat
install-slackcat:
	wget https://github.com/bcicen/slackcat/releases/download/1.7.2/slackcat-1.7.2-linux-amd64 -O slackcat
	sudo cp slackcat /usr/local/bin/
	rm -f slackcat
	sudo chmod +x /usr/local/bin/slackcat
	slackcat --configure
