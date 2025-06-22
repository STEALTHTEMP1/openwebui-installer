class OpenwebuiInstaller < Formula
  desc "Easy installer and manager for Open WebUI - User-friendly AI Interface"
  homepage "https://github.com/STEALTHTEMP1/openwebui-installer"
  url "https://github.com/STEALTHTEMP1/openwebui-installer/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "REPLACE_WITH_ACTUAL_SHA256_HASH"
  license "MIT"
  head "https://github.com/STEALTHTEMP1/openwebui-installer.git", branch: "main"

  depends_on "python@3.11"
  depends_on "git"
  depends_on "curl"

  def install
    # Create a libexec directory for the Python environment
    libexec.install Dir["*"]

    # Create wrapper script
    (bin/"openwebui-installer").write <<~EOS
      #!/bin/bash
      cd "#{libexec}"
      exec python3 install.py "$@"
    EOS

    # Make the wrapper executable
    chmod 0755, bin/"openwebui-installer"
  end

  def post_install
    ohai "Open WebUI Installer has been installed!"
    ohai "Run 'openwebui-installer --help' to get started"
    ohai ""
    ohai "Common commands:"
    ohai "  openwebui-installer install    # Install Open WebUI"
    ohai "  openwebui-installer start      # Start Open WebUI service"
    ohai "  openwebui-installer stop       # Stop Open WebUI service"
    ohai "  openwebui-installer update     # Update Open WebUI"
    ohai "  openwebui-installer uninstall  # Remove Open WebUI"
  end

  test do
    assert_match "Open WebUI Installer", shell_output("#{bin}/openwebui-installer --version")
  end

  def caveats
    <<~EOS
      Open WebUI Installer has been installed to:
        #{bin}/openwebui-installer

      To get started:
        openwebui-installer install

      The installer will guide you through the setup process.

      For more information, visit:
        https://github.com/STEALTHTEMP1/openwebui-installer
    EOS
  end
end
