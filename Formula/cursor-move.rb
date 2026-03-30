# Copy to homebrew-cursor-move tap: Formula/cursor-move.rb
# After tagging v0.1.0 on GitHub, set sha256 from:
#   curl -fsSL "https://github.com/Bogdan808/cursor-move/archive/refs/tags/v0.1.0.tar.gz" | shasum -a 256
class CursorMove < Formula
  desc "Move files in Cursor IDE with automatic import updates — built for AI agents"
  homepage "https://github.com/Bogdan808/cursor-move"
  url "https://github.com/Bogdan808/cursor-move/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "dc62880916052cce0ac0575e33cc202e3081d930f00e3f9fe9867d627390a662"
  license "MIT"

  depends_on "node"

  def install
    mkdir_p "dist"
    cd "vscode-extension" do
      system "npx", "--yes", "@vscode/vsce@latest", "package",
        "--allow-missing-repository",
        "--out", "../dist/cursor-move-file.vsix"
    end

    libexec.install "lib/move-file.js"
    libexec.install "lib/setup.js"
    libexec.install "dist/cursor-move-file.vsix"

    inreplace "bin/cursor-move", "%%LIBEXEC%%", libexec.to_s
    bin.install "bin/cursor-move"
  end

  def post_install
    cursor_cli = "/Applications/Cursor.app/Contents/Resources/app/bin/cursor"
    vsix = "#{libexec}/cursor-move-file.vsix"
    if File.exist?(cursor_cli)
      system cursor_cli, "--install-extension", vsix
      ohai "VS Code extension installed into Cursor"
    else
      opoo "Cursor not found at #{cursor_cli}."
      opoo "Install manually: cursor-move --install-ext"
    end
  end

  def caveats
    <<~EOS
      cursor-move has been installed!

      Quick start (run inside your project directory):

        cursor-move --setup          # add required VS Code setting
        cursor-move src dst          # move a file

      If the extension was not auto-installed:

        cursor-move --install-ext    # install the VS Code extension
        Then reload Cursor (Cmd+Shift+P -> "Reload Window")
    EOS
  end

  test do
    assert_match "cursor-move", shell_output("#{bin}/cursor-move --help")
  end
end
