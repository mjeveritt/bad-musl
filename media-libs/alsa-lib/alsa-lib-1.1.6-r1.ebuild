# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

PYTHON_COMPAT=( python{2_7,3_{4,5,6}} )

inherit autotools multilib multilib-minimal python-single-r1

DESCRIPTION="Advanced Linux Sound Architecture Library"
HOMEPAGE="https://alsa-project.org/"
SRC_URI="mirror://alsaproject/lib/${P}.tar.bz2"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="amd64 arm ~arm64 ~mips ppc x86"
IUSE="alisp debug doc elibc_uclibc python +thread-safety"

RDEPEND="python? ( ${PYTHON_DEPS} )"
DEPEND="${RDEPEND}
	doc? ( >=app-doc/doxygen-1.2.6 )"

REQUIRED_USE="python? ( ${PYTHON_REQUIRED_USE} )"

PATCHES=(
	"${FILESDIR}/${P}-missing_files.patch" #652422
)

pkg_setup() {
	use python && python-single-r1_pkg_setup
}

src_prepare() {
	find . -name Makefile.am -exec sed -i -e '/CFLAGS/s:-g -O2::' {} + || die
	# https://bugs.gentoo.org/509886
	use elibc_uclibc && { sed -i -e 's:oldapi queue_timer:queue_timer:' test/Makefile.am || die; }
	# https://bugs.gentoo.org/545950
	sed -i -e '5s:^$:\nAM_CPPFLAGS = -I$(top_srcdir)/include:' test/lsb/Makefile.am || die
	default
	eautoreconf
}

multilib_src_configure() {
	local myeconfargs=(
		--disable-maintainer-mode
		--disable-resmgr
		--enable-aload
		--enable-rawmidi
		--enable-seq
		--enable-shared
		# enable Python only on final ABI
		$(multilib_native_use_enable python)
		$(use_enable alisp)
		$(use_enable thread-safety)
		$(use_with debug)
		$(usex elibc_uclibc --without-versioned '')
		$(usex elibc_musl --without-versioned '')
	)

	ECONF_SOURCE="${S}" \
	econf "${myeconfargs[@]}"
}

multilib_src_compile() {
	emake

	if multilib_is_native_abi && use doc; then
		emake doc
		grep -FZrl "${S}" doc/doxygen/html | \
			xargs -0 sed -i -e "s:${S}::"
	fi
}

multilib_src_install() {
	emake DESTDIR="${D}" install
	if multilib_is_native_abi && use doc; then
		docinto html
		dodoc -r doc/doxygen/html/.
	fi
}

multilib_src_install_all() {
	find "${ED}" \( -name '*.a' -o -name '*.la' \) -delete || die
	dodoc ChangeLog doc/asoundrc.txt NOTES TODO
}
