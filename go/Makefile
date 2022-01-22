# 開始時に決めるもの
# systemctlのサービス名に使う
PROJECT=isucondition

NGINX_CONFIG=/etc/nginx/nginx.conf
MYSQLD_CONFIG=/etc/mysql/mariadb.conf.d/50-server.cnf

NGINX_LOG=/var/log/nginx/access.log

KATARIBE_CFG=/etc/kataribe.toml

DB_HOST=127.0.0.1
DB_PORT=3306
DB_USER=isucon
DB_PASS=isucon
DB_NAME=$(PROJECT)

SLOW_LOG=/var/log/mysql/mariadb-slow.log

LOGS_DIR=/etc/logs

GIT_ROOT=/home/isucon/webapp

# 開始前に決めるもの
GIT_EMAIL=daiusa3@icloud.com
GIT_NAME="Daiki Usami"

DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/934516652882673664/Aioc3f-YBWSCnl3L7lBqPiL388cGld5lPRDOahaIneOnh4c9nimB1nCng6OXlckueLVw

SLACKCAT_CNL=isucon

#################################################################################
PPROF=go tool pprof
KATARIBE=kataribe -f $(KATARIBE_CFG)
MYSQL=sudo mysql -h$(DB_HOST) -P$(DB_PORT) -u$(DB_USER) -p$(DB_PASS) $(DB_NAME)
SLACKCAT=slackcat --channel $(SLACKCAT_CNL)
WHEN:=$(shell date +%H:%M:%S)
#################################################################################

.PHONY: setup
setup: install-tools pull-link

.PHONY: pullbuild
pullres: pull build

.PHONY: build
build: restart-nginx restart-mysql restart-app

################################################################################

.PHONY: restart-app
restart-app:
	cd ~/webapp/go && go build
	sudo systemctl restart $(PROJECT).go.service

.PHONY: restart-nginx
restart-nginx:
	sudo rm -f $(NGINX_LOG)
	sudo nginx -t
	sudo nginx -s reload
	sudo systemctl restart nginx

.PHONY: restart-mysql
restart-mysql:
	sudo rm -f $(SLOW_LOG)
	sudo systemctl restart mysql
	sudo systemctl restart mysqld
	sudo systemctl restart mariadb

.PHONY: pull-link
pull-link: link-nginx link-mysql

.PHONY: link-nginx
link-nginx:
	sudo cp $(NGINX_CONFIG) $(GIT_ROOT)/nginx.conf
	sudo rm $(NGINX_CONFIG)
	sudo ln -s $(GIT_ROOT)/nginx.conf $(NGINX_CONFIG)

.PHONY: link-mysql
link-mysql:
	sudo cp $(MYSQLD_CONFIG) $(GIT_ROOT)/mysqld.cnf
	sudo rm $(MYSQLD_CONFIG)
	sudo ln -s $(GIT_ROOT)/mysqld.cnf $(MYSQLD_CONFIG)

################################################################################

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

################################################################################

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
	sudo mysqldumpslow -s t -t 10 > ~/temp/slowdump.txt
	# | curl -X POST -H "Content-Type: application/json" -d "{\"content\":\"$(cat)\"}" $(DISCORD_WEBHOOK_URL)
	curl -X POST -F txt=@$(HOME)/temp/slowdump.txt $(DISCORD_WEBHOOK_URL) -s -o /dev/null

.PHONY: alp
alp:
	cat $(NGINX_LOG) | alp --avg -r

.PHONY: alp-sum
alp-sum:
	cat $(NGINX_LOG) | alp --sum -r

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

.PHONY: install-alp
install-alp:
	wget https://github.com/tkuchiki/alp/releases/download/v0.3.1/alp_linux_amd64.zip
	unzip alp_linux_amd64.zip
	sudo install ./alp /usr/local/bin

.PHONY: install-slackcat
install-slackcat:
	wget https://github.com/bcicen/slackcat/releases/download/1.7.2/slackcat-1.7.2-linux-amd64 -O slackcat
	sudo cp slackcat /usr/local/bin/
	rm -f slackcat
	sudo chmod +x /usr/local/bin/slackcat
	slackcat --configure

