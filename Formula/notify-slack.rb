class NotifySlack < Formula
  desc "Post messages and snippets to Slack from the command line"
  homepage "https://github.com/catatsuy/notify_slack"
  version "0.5.9"
  license "MIT"
  depends_on :macos

  if Hardware::CPU.arm?
    # renovate: datasource=custom.notify-slack-darwin-arm64 depName=catatsuy/notify_slack asset=notify_slack-darwin-arm64.tar.gz
    url "https://github.com/catatsuy/notify_slack/archive/refs/tags/v0.5.10.tar.gz"
    sha256 "bf84605eea4a3d897289158508db9a08abf9a1f7f7943e773698eec1c19b2c63"
  else
    # renovate: datasource=custom.notify-slack-darwin-amd64 depName=catatsuy/notify_slack asset=notify_slack-darwin-amd64.tar.gz
    url "https://github.com/catatsuy/notify_slack/releases/download/v0.5.9/notify_slack-darwin-amd64.tar.gz"
    sha256 "0fbbf78b6fc4e4e3665e3169f29cc0e25ad0e773df832a81fff0e847cde5e206"
  end

  def install
    bin.install "notify_slack"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/notify_slack -version 2>&1")
  end
end
