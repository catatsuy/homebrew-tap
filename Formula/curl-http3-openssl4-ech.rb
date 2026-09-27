# curl-http3-openssl4-ech.rb
class CurlHttp3Openssl4Ech < Formula
  desc "Get a file from an HTTP, HTTPS or FTP server with HTTP/3 and ECH support"
  homepage "https://curl.se"
  url "https://curl.se/download/curl-8.22.0.tar.bz2"
  sha256 "5d956a6a22b3c279f50c421ee5d3c9e9d660cb6f115dcf881b579e952130549c" # curl sha256
  license "curl"

  depends_on "pkg-config" => :build
  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "perl" => :build

  resource "openssl" do
    url "https://github.com/openssl/openssl/releases/download/openssl-4.0.2/openssl-4.0.2.tar.gz"
    sha256 "736b467530f916737b7031310ccb21d8218c6229e61e8e160cd1d3458cd543a8" # openssl sha256
  end

  resource "nghttp3" do
    url "https://github.com/ngtcp2/nghttp3.git",
        using: :git,
        tag: "v1.18.0",
        revision: "dbfc24286138cb0b6490160e7ca87fe1ce6722a0" # nghttp3 revision
  end

  resource "ngtcp2" do
    url "https://github.com/ngtcp2/ngtcp2/archive/refs/tags/v1.25.0.tar.gz"
    sha256 "fff5d584940be77005d0135045ebe4760851f818c4349c6516a49b8d8dfa1e55" # ngtcp2 sha256
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
