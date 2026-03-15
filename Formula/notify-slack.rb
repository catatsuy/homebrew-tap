class NotifySlack < Formula
  desc "Post messages and snippets to Slack from the command line"
  homepage "https://github.com/catatsuy/notify_slack"
  license "MIT"

  on_macos do
    on_arm do
      # renovate: datasource=custom.notify-slack-darwin-arm64 depName=catatsuy/notify_slack asset=notify_slack-darwin-arm64.tar.gz
      url "https://github.com/catatsuy/notify_slack/releases/download/v0.5.9/notify_slack-darwin-arm64.tar.gz"
      sha256 "c74b286474231e0b5cc66aa612d5e981f88c7e768e9a8cc7063270e0556ad144"
    end

    on_intel do
      # renovate: datasource=custom.notify-slack-darwin-amd64 depName=catatsuy/notify_slack asset=notify_slack-darwin-amd64.tar.gz
      url "https://github.com/catatsuy/notify_slack/releases/download/v0.5.9/notify_slack-darwin-amd64.tar.gz"
      sha256 "0fbbf78b6fc4e4e3665e3169f29cc0e25ad0e773df832a81fff0e847cde5e206"
    end
  end

  def install
    bin.install "notify_slack"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/notify_slack -version 2>&1")
  end
end
