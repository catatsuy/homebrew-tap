class Purl < Formula
  desc "Modern Perl-like text processing for files and standard input"
  homepage "https://github.com/catatsuy/purl"
  version "0.2.7"
  license "MIT"
  depends_on :macos

  if Hardware::CPU.arm?
    # renovate: datasource=custom.purl-darwin-arm64 depName=catatsuy/purl asset=purl-darwin-arm64.tar.gz
    url "https://github.com/catatsuy/purl/releases/download/v0.2.7/purl-darwin-arm64.tar.gz"
    sha256 "3ba3fbcaee965701fcd49867feac0b943a16deeb6bfca06ef453267a1401e051"
  else
    # renovate: datasource=custom.purl-darwin-amd64 depName=catatsuy/purl asset=purl-darwin-amd64.tar.gz
    url "https://github.com/catatsuy/purl/releases/download/v0.2.7/purl-darwin-amd64.tar.gz"
    sha256 "7b93a49c49a727c3e70e51a0a8818b476bfe09a2bfd17b8f02e5b906f359e3b2"
  end

  def install
    bin.install "purl"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/purl -version 2>&1")
  end
end
