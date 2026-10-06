.PHONY: runav runrs install installsvc setup

test-av: setup-test
	./antivirusd.sh ./test/monitor/ ./test/quarantine/ 5

test-rs: setup-test
	./restore.sh ./test/monitor/ ./test/quarantine/

install: setup-install
	sudo cp ./antivirusd.sh /opt/antivirus/antivirusd

install-svc: setup-install
	sudo cp ./antivirus-cron.sh /opt/antivirus/antivirus
	sudo ./service-setup.sh

setup-install: setup
	sudo mkdir -p /opt/antivirus/quarantine/
	sudo cp ./restore.sh /opt/antivirus/restore

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

clean: uninstall
	rm -rf ./test/
	rm directory-info.new
	rm directory-info.last

uninstall:
	sudo rm -rf /opt/antivirus/
	sudo service-setup.sh --uninstall