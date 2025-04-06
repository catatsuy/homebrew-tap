# curl-http3-libressl.rb
class CurlHttp3Libressl < Formula
  desc "Get a file from an HTTP, HTTPS or FTP server"
  homepage "https://curl.se"
  url "https://curl.se/download/curl-8.13.0.tar.bz2"
  sha256 "e0d20499260760f9865cb6308928223f4e5128910310c025112f592a168e1473" # curl sha256
  license "curl"

  depends_on "pkg-config" => :build
  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build

  resource "libressl" do
    url "https://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-4.0.0.tar.gz"
    sha256 "4d841955f0acc3dfc71d0e3dd35f283af461222350e26843fea9731c0246a1e4" # libressl sha256
  end

  resource "nghttp3" do
    url "https://github.com/ngtcp2/nghttp3.git",
        using: :git,
        tag: "v1.8.0",
        revision: "96ad17fd71d599b78a11e0ff635eccb7d2f6d649" # nghttp3 sha256
  end

  resource "ngtcp2" do
    url "https://github.com/ngtcp2/ngtcp2/archive/refs/tags/v1.11.0.tar.gz"
    sha256 "144b169aa98ba2ca1f74cf40ff5e93b90a7bb1292f62b7998a8dd5c2a5eb102a" # ngtcp2 sha256
  end

  def install
    # Define paths for dependencies in the curl-specific directory under prefix
    libressl_prefix = "#{prefix}/curl-http3-libressl/libressl"
    nghttp3_prefix = "#{prefix}/curl-http3-libressl/nghttp3"
    ngtcp2_prefix = "#{prefix}/curl-http3-libressl/ngtcp2"

    # Build and install LibreSSL in the curl-specific directory
    resource("libressl").stage do
      system "./configure", "--prefix=#{libressl_prefix}", "--disable-shared", "--enable-static"
      system "make"
      system "make", "install"
    end

    # Build and install nghttp3 in the curl-specific directory
    resource("nghttp3").stage do
      system "git", "submodule", "update", "--init"
      system "autoreconf -fi"
      system "./configure", "--prefix=#{nghttp3_prefix}", "--enable-lib-only", "--disable-shared"
      system "make"
      system "make", "install"
    end

    # Build and install ngtcp2 in the curl-specific directory
    resource("ngtcp2").stage do
      system "autoreconf -fi"
      system "./configure", "--prefix=#{ngtcp2_prefix}", "--enable-lib-only", "--disable-shared",
                            "PKG_CONFIG_PATH=#{libressl_prefix}/lib/pkgconfig:#{nghttp3_prefix}/lib/pkgconfig"
      system "make"
      system "make", "install"
    end

    # Set PKG_CONFIG_PATH and LDFLAGS to reference curl-specific locations
    ENV["PKG_CONFIG_PATH"] = "#{libressl_prefix}/lib/pkgconfig:#{nghttp3_prefix}/lib/pkgconfig:#{ngtcp2_prefix}/lib/pkgconfig"
    ENV["LDFLAGS"] = "-Wl,-rpath,#{libressl_prefix}/lib -Wl,-rpath,#{nghttp3_prefix}/lib -Wl,-rpath,#{ngtcp2_prefix}/lib"

    # Configure curl with static linking for dependencies
    system "autoreconf", "-fi"
    system "./configure", "--prefix=#{prefix}",
                          "--with-openssl=#{libressl_prefix}",
                          "--with-nghttp3=#{nghttp3_prefix}",
                          "--with-ngtcp2=#{ngtcp2_prefix}",
                          "--enable-alt-svc",
                          "--enable-http3",
                          "--disable-shared",
                          "--without-libpsl"
    system "make"
    system "make", "install"

    # Update the paths to libraries in the curl binary using install_name_tool
    system "install_name_tool", "-change", "#{libressl_prefix}/lib/libssl.58.dylib", "#{libressl_prefix}/lib/libssl.58.dylib", "#{bin}/curl"
    system "install_name_tool", "-change", "#{libressl_prefix}/lib/libcrypto.55.dylib", "#{libressl_prefix}/lib/libcrypto.55.dylib", "#{bin}/curl"
    system "install_name_tool", "-change", "#{nghttp3_prefix}/lib/libnghttp3.9.dylib", "#{nghttp3_prefix}/lib/libnghttp3.9.dylib", "#{bin}/curl"
    system "install_name_tool", "-change", "#{ngtcp2_prefix}/lib/libngtcp2.16.dylib", "#{ngtcp2_prefix}/lib/libngtcp2.16.dylib", "#{bin}/curl"
    system "install_name_tool", "-change", "#{ngtcp2_prefix}/lib/libngtcp2_crypto_quictls.2.dylib", "#{ngtcp2_prefix}/lib/libngtcp2_crypto_quictls.2.dylib", "#{bin}/curl"
  end

  test do
    assert_match "nghttp3", shell_output("#{bin}/curl -V")
  end
end
