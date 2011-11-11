#!/bin/bash

mkdir -p ac
test -f AUTHORS   || touch AUTHORS
test -f COPYING   || touch COPYING
test -f ChangeLog || touch ChangeLog
test -f NEWS      || touch NEWS
test -f NOTICE    || touch NOTICE
test -f README    || cp -f README.rdoc README

function download() {
    if [ ! -f "$2" ];then
        wget "$1/$2" -O "$2" || exit 1
    fi
}

mkdir -p deps
mkdir -p deps/ruby
mkdir -p plugins
cd deps
download "http://ftp.ruby-lang.org/pub/ruby/1.9" "ruby-1.9.2-p290.tar.bz2"
download "http://rubygems.org/downloads" "json-1.5.2.gem"
download "http://rubygems.org/downloads" "msgpack-0.4.4.gem"
download "http://rubygems.org/downloads" "iobuffer-0.1.3.gem"
download "http://rubygems.org/downloads" "cool.io-1.0.0.gem"
download "http://rubygems.org/downloads" "http_parser.rb-0.5.1.gem"
download "http://rubygems.org/downloads" "yajl-ruby-1.0.0.gem"
cd ..

echo "#!/bin/sh

##
## Generated by autogen.sh
##

bundle exec rake || exit 1

version=\`cat VERSION\`
dst=fluentd-\$version
rm -rf \$dst
mkdir \$dst || exit 1
cp -fpR lib bin \$dst/ || exit 1
mkdir -p \$dst/deps || exit 1
mkdir -p \$dst/pkg || exit 1
cp pkg/fluentd-\$version.gem \$dst/pkg/
cp deps/*.gem deps/ruby-*.tar.bz2 \$dst/deps/
cp README.rdoc README COPYING NEWS ChangeLog AUTHORS INSTALL NOTICE \\
    configure.in Makefile.in Makefile.am configure aclocal.m4 \\
    Rakefile VERSION fluent.conf make_dist.sh \\
    \$dst/ || exit 1
cp -f README.rdoc \$dst/README || exit 1
mkdir -p \$dst/ac || exit 1
cp ac/* \$dst/ac/ || exit 1
tar czvf \$dst.tar.gz \$dst || exit 1
rm -rf \$dst
" > make_dist.sh
chmod 755 make_dist.sh

if [ x`uname` = x"Darwin" ]; then
    glibtoolize --force --copy
else
    libtoolize --force --copy
fi
aclocal
#autoheader
automake --add-missing --copy
autoconf

rmdir deps/ruby 2>/dev/null

