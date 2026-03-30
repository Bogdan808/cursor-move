PREFIX    ?= /usr/local
LIBEXEC    = $(PREFIX)/libexec/cursor-move
BINDIR     = $(PREFIX)/bin
CURSOR_CLI = /Applications/Cursor.app/Contents/Resources/app/bin/cursor

.PHONY: build install uninstall install-ext setup clean

build:
	cd vscode-extension && npx @vscode/vsce@latest package \
		--allow-missing-repository --out ../dist/cursor-move-file.vsix

install: dist/cursor-move-file.vsix
	@mkdir -p $(LIBEXEC) $(BINDIR)
	cp lib/move-file.js  $(LIBEXEC)/
	cp lib/setup.js      $(LIBEXEC)/
	cp dist/cursor-move-file.vsix $(LIBEXEC)/
	sed 's|%%LIBEXEC%%|$(LIBEXEC)|g' bin/cursor-move > $(BINDIR)/cursor-move
	chmod +x $(BINDIR)/cursor-move
	@echo ""
	@echo "Installed cursor-move to $(BINDIR)/cursor-move"
	@echo ""
	@echo "Next steps:"
	@echo "  make install-ext   # install VS Code extension into Cursor"
	@echo "  cursor-move --setup  # configure your workspace"

install-ext: dist/cursor-move-file.vsix
	@if [ -f "$(CURSOR_CLI)" ]; then \
		$(CURSOR_CLI) --install-extension dist/cursor-move-file.vsix; \
		echo "Extension installed. Reload Cursor to activate."; \
	else \
		echo "Error: Cursor CLI not found at $(CURSOR_CLI)" >&2; \
		exit 1; \
	fi

uninstall:
	rm -f  $(BINDIR)/cursor-move
	rm -rf $(LIBEXEC)
	@echo "Uninstalled cursor-move"

setup:
	@node lib/setup.js

clean:
	rm -f dist/cursor-move-file.vsix

dist/cursor-move-file.vsix:
	$(MAKE) build
