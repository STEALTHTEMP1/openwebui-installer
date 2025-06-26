class OpenwebuiInstaller < Formula
  include Language::Python::Virtualenv

  version "0.1.0"

  desc "A macOS installer for Open WebUI with native Ollama integration"
  homepage "https://github.com/open-webui/openwebui-installer"
  url "https://github.com/open-webui/openwebui-installer/archive/refs/tags/v#{version}.tar.gz"
  sha256 "REPLACE_WITH_ACTUAL_SHA256_HASH" # Updated by CI during release
  license "MIT"

  livecheck do
    url :stable
    strategy :github_latest
  end

  depends_on "python@3.9"

  resource "click" do
    url "https://files.pythonhosted.org/packages/96/d3/f04c7bfcf5c1862a2a5b845c6b2b360488cf47af55dfa79c98f6a6bf98b5/click-8.2.1.tar.gz"
    sha256 "ca9853ad459e787e2192211578cc907e7594e294c7ccc834310722b41b9ca6de"
  end

  resource "docker" do
    url "https://files.pythonhosted.org/packages/25/14/7d40f8f64ceca63c741ee5b5611ead4fb8d3bcaf3e6ab57d2ab0f01712bc/docker-7.1.0.tar.gz"
    sha256 "323736fb92cd9418fc5e7133bc953e11a9da04f4483f828b527db553f1e7e5a3"
  end

  resource "PyQt6" do
    url "https://files.pythonhosted.org/packages/05/62/13e0c9a470e2216d35b3ada0a8ebf2a6a7f5b03c4e4d321c1c07af9e3c16/PyQt6-6.9.1.tar.gz"
    sha256 "9f158aa29d205142c56f0f35d07784b8df0be28378d20a97bcda8bd64ffd0379"
  end

  resource "PyQt6-Qt6" do
    url "https://files.pythonhosted.org/packages/ee/7d/6f4c220e3e47dd3288e5076c560c5d224d65d95c54e0679fdee3c4f7d78d/PyQt6_Qt6-6.9.1-py3-none-macosx_11_0_arm64.whl"
    sha256 "1880a138c83dc3dd3a8f2c7e6d0e0c4f5f5dbff97f1b6f3e97b4e2e95947e7f5"
  end

  resource "PyQt6-sip" do
    url "https://files.pythonhosted.org/packages/ee/81/8e5dfb6a14a0fbf9e9df2e892724934badf288771c04cc9aa288e0c5ea16/PyQt6_sip-13.10.2.tar.gz"
    sha256 "2486e1588071943d4f6657ba09096dc9fffd2322ad2c30041e78ea3f037b5778"
  end

  resource "requests" do
    url "https://files.pythonhosted.org/packages/9d/be/10918a2eac4ae9f02f6cfe6414b7a155ccd8f7f9d4380d62fd5b955065c3/requests-2.32.4.tar.gz"
    sha256 "942c5a758f98d790eaed1a29cb6eefc7ffb0d1cf7af05c3d2791656dbd6ad1e1"
  end

  resource "rich" do
    url "https://files.pythonhosted.org/packages/rich/rich-14.0.0.tar.gz"
    sha256 "922b9cd261d7c2f8e8b435e8309d6e8f1fbb487e091f3a9e2aa9ed2e8e7b6b8c"
  end

  def install
    virtualenv_install_with_resources
  end

  test do
    system bin/"openwebui-installer", "--version"
    system bin/"openwebui-installer-gui", "--help"
  end
end
