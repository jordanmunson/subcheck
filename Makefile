default:
	@echo "You need to give 'make install' as input"
installman:
	mkdir -p //usr/local/share/man/man8
	cp -f ./man/subcheck.8.gz //usr/local/share/man/man8/

install: installman
	rm -f //usr/local/bin/subcheck.pl
	cp -f subcheck.pl all-checksub //usr/local/bin
	chmod 755 //usr/local/bin/subcheck.pl
	chmod 755 //usr/local/bin/all-checksub

uninstall:
	rm -f //usr/local/share/man/man8/subcheck.8.gz
	rm -f //usr/local/bin/subcheck.pl
	rm -f //usr/local/bin/all-checksub
