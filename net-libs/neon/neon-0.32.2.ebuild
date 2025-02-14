# Copyright 2001-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit autotools libtool multilib-minimal

DESCRIPTION="HTTP and WebDAV client library"
HOMEPAGE="https://notroj.github.io/neon/"
SRC_URI="https://notroj.github.io/neon/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0/27"
KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~ia64 ~mips ~ppc ~ppc64 ~riscv ~s390 ~sparc ~x86 ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE="doc expat gnutls kerberos libproxy nls pkcs11 ssl static-libs zlib"
RESTRICT="test"

RDEPEND="expat? ( dev-libs/expat:0=[${MULTILIB_USEDEP}] )
	!expat? ( dev-libs/libxml2:2=[${MULTILIB_USEDEP}] )
	kerberos? ( virtual/krb5:0=[${MULTILIB_USEDEP}] )
	libproxy? ( net-libs/libproxy:0=[${MULTILIB_USEDEP}] )
	nls? ( virtual/libintl:0=[${MULTILIB_USEDEP}] )
	ssl? (
		gnutls? (
			app-misc/ca-certificates
			net-libs/gnutls:0=[${MULTILIB_USEDEP}]
		)
		!gnutls? (
			dev-libs/openssl:0=[${MULTILIB_USEDEP}]
		)
		pkcs11? ( dev-libs/pakchois:0=[${MULTILIB_USEDEP}] )
	)
	zlib? ( sys-libs/zlib:0=[${MULTILIB_USEDEP}] )"
DEPEND="${RDEPEND}"
BDEPEND="
	app-text/docbook-xml-dtd:4.5
	app-text/xmlto
	virtual/pkgconfig
"

MULTILIB_CHOST_TOOLS=(
	/usr/bin/neon-config
)

src_prepare() {
	# Use CHOST-prefixed version of xml2-config for cross-compilation.
	sed -e "s/AC_CHECK_PROG(XML2_CONFIG,/AC_CHECK_TOOL(XML2_CONFIG,/" -i macros/neon-xml-parser.m4 || die "sed failed"

	# Fix compatibility with OpenSSL >=1.1.
	sed -e "s/RSA_F_RSA_PRIVATE_ENCRYPT/RSA_F_RSA_OSSL_PRIVATE_ENCRYPT/" -i src/ne_pkcs11.c || die "sed failed"

	eapply_user

	AT_M4DIR="macros" eautoreconf

	elibtoolize

	multilib_copy_sources
}

multilib_src_configure() {
	local myconf=()

	if has_version sys-libs/glibc; then
		einfo "Enabling SSL library thread-safety using POSIX threads..."
		myconf+=(--enable-threadsafe-ssl=posix)
	fi

	if use expat; then
		myconf+=(--with-expat)
	else
		myconf+=(--with-libxml2)
	fi

	if use ssl; then
		if use gnutls; then
			myconf+=(--with-ssl=gnutls --with-ca-bundle="${EPREFIX}/etc/ssl/certs/ca-certificates.crt")
		else
			myconf+=(--with-ssl=openssl)
		fi
	fi

	econf \
		--enable-shared \
		$(use_with kerberos gssapi) \
		$(use_with libproxy) \
		$(use_enable nls) \
		$(use_with pkcs11 pakchois) \
		$(use_enable static-libs static) \
		$(use_with zlib) \
		"${myconf[@]}"
}

multilib_src_install() {
	emake DESTDIR="${D}" install-{config,headers,lib,man,nls}

	if multilib_is_native_abi && use doc; then
		(
			docinto html
			dodoc -r doc/html/*
		)
	fi
}

multilib_src_install_all() {
	find "${D}" -name "*.la" -type f -delete || die

	dodoc AUTHORS BUGS NEWS README.md THANKS TODO
}
