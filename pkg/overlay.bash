
# The rest is the same for both packages: the patch goes on after Arch's own
# prepare(), and nothing else of Arch's recipe changes.
#
# The release number is Arch's plus .$_xscale_release, so pacman prefers this
# build to Arch's of the same version and gives it back at Arch's next release.
pkgrel+=".$_xscale_release"
source+=("$_xscale_patch")
# one more checksum in each list the recipe keeps: the patch lies beside it
for _xscale_sums in md5sums sha1sums sha224sums sha256sums sha384sums sha512sums b2sums cksums; do
  if declare -p "$_xscale_sums" >/dev/null 2>&1; then
    eval "$_xscale_sums+=(SKIP)"
  fi
done
unset _xscale_sums

if declare -F prepare >/dev/null; then
  eval "_xscale_arch_prepare() $(declare -f prepare | tail -n +2)"
else
  _xscale_arch_prepare() { :; }
fi
prepare() {
  _xscale_arch_prepare
  cd "$srcdir/$_xscale_dir"
  patch -Np1 -i "$srcdir/$_xscale_patch"
}
# <<< xscale
