class Bento < Formula
  desc "AI-assisted CLI for git workflows, translation, and repository dumps"
  homepage "https://github.com/catatsuy/bento"
  version "0.3.4"
  license "MIT"
  depends_on :macos

  if Hardware::CPU.arm?
    # renovate: datasource=custom.bento-darwin-arm64 depName=catatsuy/bento asset=bento-darwin-arm64.tar.gz
    url "https://github.com/catatsuy/bento/archive/refs/tags/v0.3.5.tar.gz"
    sha256 "3c73a6f1f52e0a54137fa6671d0d1e2cb294e88468c77e095ebc4f4ac16fb94a"
  else
    # renovate: datasource=custom.bento-darwin-amd64 depName=catatsuy/bento asset=bento-darwin-amd64.tar.gz
    url "https://github.com/catatsuy/bento/releases/download/v0.3.4/bento-darwin-amd64.tar.gz"
    sha256 "d3fed5d46d4a4a652b9b602d8b6e9e8426f8ddffb7d83e0b89ce4bec3a9238d4"
  end

  def install
    bin.install "bento"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/bento -version 2>&1")
  end
end
