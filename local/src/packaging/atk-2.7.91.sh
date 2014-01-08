#!/bin/bash
# vim: tabstop=4 fileformat=unix fileencoding=utf-8 filetype=sh

# license: Apatche v2.0

if [ "" = "${IN_PACKAGE_SCRIPT}" ]
then
	echo FAIL: \${XMINGW}/package から実行してください。
	exit 1
fi


# ARCH は package が設定している。
# XLIBRARY_SOURCES は xmingw のための環境変数鵜。 env.sh で設定している。
init_var() {
	# package に返す変数。
	MOD=atk
	if [ "" = "${VER}" ]
	then
	VER=2.7.91
	REV=1
	fi
	DIRECTORY="${MOD}-${VER}"

	# 内部で使用する変数。
	__ARCHIVEDIR="${XLIBRARY_SOURCES}/gtk+"
	__ARCHIVE="${MOD}-${VER}"

	__BINZIP=${MOD}-${VER}-${REV}-bin_${ARCH}
	__DEVZIP=${MOD}-dev-${VER}-${REV}_${ARCH}
#	__TOOLSZIP=${MOD}-${VER}-${REV}-tools_${ARCH}
}

dependencies() {
	cat <<EOS
gettext-runtime
glib
zlib
EOS
}

dependencies_opt() {
	cat <<EOS
EOS
}


run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}"
}

run_configure() {
	CC="gcc `${XMINGW}/cross --archcflags`" \
	CPPFLAGS="`${XMINGW}/cross --cflags`" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
	-Wl,--enable-auto-image-base -Wl,-s" \
	CFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math" \
	${XMINGW}/cross-configure --disable-gtk-doc --disable-static --prefix="${INSTALL_TARGET}"
}

post_configure() {
	# ./atk/atk.def の1行目が -e EXPORTS になってしまう。頭の -e を削除する。
	sed -i -e 's/^\(\s\+(echo\) -e \(EXPORTS;\)/\1 \2/' ./atk/Makefile
}

pre_make() {
	(cd atk && ${XMINGW}/cross make atkmarshal.h atkmarshal.c)
}

run_make() {
	${XMINGW}/cross make all install
}

pre_pack() {
	echo skip > /dev/null
}

run_pack() {
	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll share/locale &&
	pack_archive "${__DEVZIP}" include lib/*.{def,a} lib/pkgconfig &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}"
}


