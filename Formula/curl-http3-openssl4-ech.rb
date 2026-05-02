# curl-http3-openssl4-ech.rb
class CurlHttp3Openssl4Ech < Formula
  desc "Get a file from an HTTP, HTTPS or FTP server with HTTP/3 and ECH support"
  homepage "https://curl.se"
  url "https://curl.se/download/curl-8.20.0.tar.bz2"
  sha256 "4be48e69cf467246cb97d369b85d78a08528f2b37cffef2418ee16e6a4eb596e" # curl sha256
  license "curl"

  depends_on "pkg-config" => :build
  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "perl" => :build

  resource "openssl" do
    url "https://github.com/openssl/openssl/releases/download/openssl-4.0.0/openssl-4.0.0.tar.gz"
    sha256 "c32cf49a959c4f345f9606982dd36e7d28f7c58b19c2e25d75624d2b3d2f79ac" # openssl sha256
  end

  resource "nghttp3" do
    url "https://github.com/ngtcp2/nghttp3.git",
        using: :git,
        tag: "v1.15.0",
        revision: "d326f4c1eb3f6a780d77793b30e16756c498f913" # nghttp3 revision
  end

  resource "ngtcp2" do
    url "https://github.com/ngtcp2/ngtcp2/archive/refs/tags/v1.22.1.tar.gz"
    sha256 "a83f46b17e07ad91ff1c8b843adcba99578d1e62007ededa7d52cd097ef64a52" # ngtcp2 sha256
  end

  def install
    # Keep all private dependencies isolated from Homebrew's shared curl/OpenSSL.
    deps_prefix = prefix/"curl-http3-openssl4-ech"
    openssl_prefix = deps_prefix/"openssl"
    nghttp3_prefix = deps_prefix/"nghttp3"
    ngtcp2_prefix = deps_prefix/"ngtcp2"

    resource("openssl").stage do
      system "./config", "--prefix=#{openssl_prefix}",
                         "--openssldir=#{openssl_prefix}/ssl",
                         "--libdir=lib",
                         "no-shared"
      system "make"
      system "make", "install_sw"
    end

    resource("nghttp3").stage do
      system "git", "submodule", "update", "--init"
      system "autoreconf", "-fi"
      system "./configure", "--prefix=#{nghttp3_prefix}",
                            "--enable-lib-only",
                            "--disable-shared"
      system "make"
      system "make", "install"
    end

    resource("ngtcp2").stage do
      ENV["PKG_CONFIG_PATH"] = "#{openssl_prefix}/lib/pkgconfig:#{nghttp3_prefix}/lib/pkgconfig"
      ENV["LDFLAGS"] = "-Wl,-rpath,#{openssl_prefix}/lib"

      system "autoreconf", "-fi"
      system "./configure", "--prefix=#{ngtcp2_prefix}",
                            "--enable-lib-only",
                            "--disable-shared",
                            "--with-openssl"
      system "make"
      system "make", "install"
    end

    ENV["PKG_CONFIG_PATH"] = [
      openssl_prefix/"lib/pkgconfig",
      nghttp3_prefix/"lib/pkgconfig",
      ngtcp2_prefix/"lib/pkgconfig",
    ].join(":")
    ENV["LDFLAGS"] = [
      "-Wl,-rpath,#{openssl_prefix}/lib",
      "-Wl,-rpath,#{nghttp3_prefix}/lib",
      "-Wl,-rpath,#{ngtcp2_prefix}/lib",
    ].join(" ")

    system "autoreconf", "-fi"
    system "./configure", "--prefix=#{prefix}",
                          "--with-openssl=#{openssl_prefix}",
                          "--with-nghttp3=#{nghttp3_prefix}",
                          "--with-ngtcp2=#{ngtcp2_prefix}",
                          "--enable-alt-svc",
                          "--enable-ech",
                          "--enable-http3",
                          # "--enable-httpsrr",
                          # "--enable-ares",
                          # "--enable-threaded-resolver",
                          "--disable-shared",
                          "--without-libpsl"
    system "make"
    system "make", "install"
  end

  test do
    version_output = shell_output("#{bin}/curl -V")
    assert_match "OpenSSL/4.0.0", version_output
    assert_match "nghttp3", version_output
    assert_match "HTTP3", version_output
    assert_match "ECH", version_output
    # assert_match "HTTPSRR", version_output
    # assert_match "ARES", version_output
    # assert_match "Threaded Resolver", version_output
  end
end
