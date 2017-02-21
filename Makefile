default:
	@echo "You need to give 'make install' as input"
installman:
	mkdir -p /usr/share/man/man8
	cp -f ./man/subcheck.8.gz /usr/share/man/man8/

install: installman
	rm -f /usr/bin/subcheck.pl
	cp -f subcheck.pl all-checksub /usr/bin
	chmod 755 /usr/bin/subcheck.pl
	chmod 755 /usr/bin/all-checksub

uninstall:
	rm -f /usr/share/man/man8/subcheck.8.gz
	rm -f /usr/bin/subcheck.pl
	rm -f /usr/bin/all-checksub
