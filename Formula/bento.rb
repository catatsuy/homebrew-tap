class Bento < Formula
  desc "AI-assisted CLI for git workflows, translation, and repository dumps"
  homepage "https://github.com/catatsuy/bento"
  license "MIT"

  on_macos do
    on_arm do
      # renovate: datasource=custom.bento-darwin-arm64 depName=catatsuy/bento asset=bento-darwin-arm64.tar.gz
      url "https://github.com/catatsuy/bento/releases/download/v0.3.4/bento-darwin-arm64.tar.gz"
      sha256 "7a920dda9e6c0e6e86ec6e4e27f17f0aa72fae0af008dc502f4c333844fff2ab"
    end

    on_intel do
      # renovate: datasource=custom.bento-darwin-amd64 depName=catatsuy/bento asset=bento-darwin-amd64.tar.gz
      url "https://github.com/catatsuy/bento/releases/download/v0.3.4/bento-darwin-amd64.tar.gz"
      sha256 "d3fed5d46d4a4a652b9b602d8b6e9e8426f8ddffb7d83e0b89ce4bec3a9238d4"
    end
  end

  def install
    bin.install "bento"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/bento -version 2>&1")
  end
end
