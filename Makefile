.PHONY: test-av test-rs install install-svc setup-install setup-test setup clean-test uninstall

test-av: setup-test
	-./antivirusd.sh ./test/monitor/ ./test/quarantine/ 5

test-rs: setup
	-./restore.sh ./test/monitor/ ./test/quarantine/

install: setup-install
	cp ./antivirusd.sh /opt/antivirus/antivirusd

install-svc: setup-install
	cp ./antivirus-cron.sh /opt/antivirus/antivirus
	./service-setup.sh

RUNNING_USER := $(shell whoami)

setup-install: setup
	sudo mkdir -p /opt/antivirus/quarantine/
	sudo chown -R $(RUNNING_USER):$(RUNNING_USER) /opt/antivirus
	cp ./restore.sh /opt/antivirus/restore

setup-test: setup
	mkdir -p ./test/monitor/
	mkdir -p ./test/quarantine/
	touch ./test/monitor/a.bat
	touch ./test/monitor/b.txt
	touch ./test/monitor/c.pdf
	echo "virus" > ./test/monitor/c.pdf

setup:
	chmod +x ./antivirusd.sh
	chmod +x ./antivirus-cron.sh
	chmod +x ./restore.sh

clean-test:
	-rm -rf ./test/
	-rm directory-info.new
	-rm directory-info.last
	-rm allowlist

uninstall:
	-sudo rm -rf /opt/antivirus/
	-sudo ./service-setup.sh --uninstall