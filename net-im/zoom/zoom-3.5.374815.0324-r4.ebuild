# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit desktop eutils xdg-utils

DESCRIPTION="Video conferencing and web conferencing service"
HOMEPAGE="https://zoom.us/"
SRC_URI="amd64? ( https://zoom.us/client/${PV}/${PN}_x86_64.tar.xz -> ${P}_x86_64.tar.xz )
	x86? ( https://zoom.us/client/${PV}/${PN}_i686.tar.xz -> ${P}_i686.tar.xz )"
S="${WORKDIR}/${PN}"

LICENSE="all-rights-reserved Apache-2.0" # Apache-2.0 for icon
SLOT="0"
KEYWORDS="-* ~amd64 ~x86"
IUSE="pulseaudio"
RESTRICT="mirror bindist strip"

RDEPEND="dev-libs/glib:2
	dev-libs/icu
	dev-qt/qtcore:5
	dev-qt/qtdbus:5
	dev-qt/qtdeclarative:5
	dev-qt/qtgraphicaleffects:5
	dev-qt/qtgui:5
	dev-qt/qtnetwork:5
	dev-qt/qtpositioning:5
	dev-qt/qtprintsupport:5
	dev-qt/qtquickcontrols:5[widgets]
	dev-qt/qtscript:5
	dev-qt/qtwebchannel:5
	dev-qt/qtwebengine:5
	dev-qt/qtwidgets:5
	media-libs/libglvnd
	media-libs/libjpeg-turbo
	media-sound/mpg123
	sys-apps/dbus
	sys-apps/util-linux
	x11-libs/libX11
	x11-libs/libxcb
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXtst
	x11-libs/xcb-util-image
	x11-libs/xcb-util-keysyms
	pulseaudio? ( media-sound/pulseaudio )
	!pulseaudio? ( media-libs/alsa-lib )"

BDEPEND="!pulseaudio? ( dev-util/bbe )"

QA_PREBUILT="opt/zoom/*"

src_prepare() {
	default
	if ! use pulseaudio; then
		# For some strange reason, zoom cannot use any ALSA sound devices if
		# it finds libpulse. This causes breakage if media-sound/apulse[sdk]
		# is installed. So, force zoom to ignore libpulse.
		bbe -e 's/libpulse.so/IgNoRePuLsE/' zoom >zoom.tmp || die
		mv zoom.tmp zoom || die
	fi
}

src_install() {
	insinto /opt/zoom
	exeinto /opt/zoom
	doins -r json sip timezones translations
	doins *.pcm *.pem *.sh Embedded.properties version.txt
	use amd64 && doins icudtl.dat
	doexe zoom{,.sh,linux} zopen ZoomLauncher
	dosym {"../../usr/$(get_libdir)",/opt/zoom}/libmpg123.so
	dosym {"../../usr/$(get_libdir)",/opt/zoom}/libturbojpeg.so #715106

	make_wrapper zoom ./zoom /opt/zoom
	make_desktop_entry "zoom %U" Zoom zoom-videocam "" \
		"MimeType=x-scheme-handler/zoommtg;application/x-zoom;"
	# The tarball doesn't contain an icon, so take a generic camera icon
	# from https://github.com/google/material-design-icons, modified to be
	# white on a blue background
	doicon -s scalable "${FILESDIR}"/zoom-videocam.svg
	doicon -s 24 "${FILESDIR}"/zoom-videocam.xpm
}

pkg_postinst() {
	xdg_desktop_database_update
	xdg_icon_cache_update
}

pkg_postrm() {
	xdg_desktop_database_update
	xdg_icon_cache_update
}
