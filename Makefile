# Makefile de Miniaturas 3D - Fedora (GCode, 3MF, STL, OpenSCAD)
BIN_DIR = /usr/bin
THUMB_DIR = /usr/share/thumbnailers
MIME_DIR = /usr/share/mime/packages

# Identifica o usuário real mesmo rodando com 'sudo'
REAL_USER = $(if $(SUDO_USER),$(SUDO_USER),$(USER))
USER_HOME = $(shell getent passwd $(REAL_USER) | cut -d: -f6)

.PHONY: all install uninstall

all:
	@echo "Pronto para instalar. Execute 'sudo make install'."

install:
	@echo "=========================================================="
	@echo "Instalando Geradores de Miniaturas 3D..."
	@echo "=========================================================="
	@mkdir -p $(BIN_DIR)
	@mkdir -p $(THUMB_DIR)
	@mkdir -p $(MIME_DIR)

	# 1. Registro de MimeType do GCode
	@printf '%s\n' \
		'<?xml version="1.0" encoding="utf-8"?>' \
		'<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">' \
		'  <mime-type type="text/x-gcode">' \
		'    <comment>G-Code File</comment>' \
		'    <glob pattern="*.gcode"/>' \
		'    <glob pattern="*.gco"/>' \
		'    <glob pattern="*.g"/>' \
		'  </mime-type>' \
		'</mime-info>' > $(MIME_DIR)/gcode.xml

	# 2. Extrator Python de GCode (sem arquivos temporarios)
	@printf '%s\n' \
		'#!/usr/bin/env python3' \
		'import sys, re, base64' \
		'if len(sys.argv) < 3: sys.exit(1)' \
		'try:' \
		'    with open(sys.argv[1], "r", encoding="utf-8", errors="ignore") as f:' \
		'        content = f.read(3 * 1024 * 1024)' \
		'    blocks = re.findall(r";\s*thumbnail(?:_JPG)?\s+begin.*?\n(.*?);\s*thumbnail(?:_JPG)?\s+end", content, re.DOTALL | re.IGNORECASE)' \
		'    if not blocks:' \
		'        with open(sys.argv[1], "r", encoding="utf-8", errors="ignore") as f:' \
		'            content = f.read()' \
		'        blocks = re.findall(r";\s*thumbnail(?:_JPG)?\s+begin.*?\n(.*?);\s*thumbnail(?:_JPG)?\s+end", content, re.DOTALL | re.IGNORECASE)' \
		'    if blocks:' \
		'        lines = [l.strip().lstrip(";").strip() for l in blocks[-1].splitlines()]' \
		'        b64_data = "".join(lines)' \
		'        with open(sys.argv[2], "wb") as out:' \
		'            out.write(base64.b64decode(b64_data))' \
		'        sys.exit(0)' \
		'except Exception: pass' \
		'sys.exit(1)' > $(BIN_DIR)/gcode_thumbnailer

	# 3. Registro do Thumbnailer de GCode
	@printf '%s\n' \
		'[Thumbnailer Entry]' \
		'TryExec=$(BIN_DIR)/gcode_thumbnailer' \
		'Exec=$(BIN_DIR)/gcode_thumbnailer %i %o %s' \
		'MimeType=text/x-gcode;text/x.gcode;application/x-gcode;model/gcode;' > $(THUMB_DIR)/gcode.thumbnailer

	# 4. Extrator Python de 3MF
	@printf '%s\n' \
		'#!/usr/bin/env python3' \
		'import sys, zipfile' \
		'if len(sys.argv) < 3: sys.exit(1)' \
		'try:' \
		'    with zipfile.ZipFile(sys.argv[1], "r") as z:' \
		'        paths = ["Metadata/thumbnail.png", "Metadata/plate_1.png", "thumbnail.png"]' \
		'        for p in paths:' \
		'            if p in z.namelist():' \
		'                with open(sys.argv[2], "wb") as f:' \
		'                    f.write(z.read(p))' \
		'                sys.exit(0)' \
		'except Exception: pass' \
		'sys.exit(1)' > $(BIN_DIR)/3mf_thumbnailer

	# 5. Registro do Thumbnailer de 3MF
	@printf '%s\n' \
		'[Thumbnailer Entry]' \
		'TryExec=$(BIN_DIR)/3mf_thumbnailer' \
		'Exec=$(BIN_DIR)/3mf_thumbnailer %i %o %s' \
		'MimeType=model/3mf;application/x-3mf;application/vnd.ms-3mfdocument;' > $(THUMB_DIR)/3mf.thumbnailer

	# 6. Suporte a STL e OpenSCAD
	@printf '%s\n' \
		'#!/usr/bin/env python3' \
		'import sys, subprocess' \
		'if len(sys.argv) < 3: sys.exit(1)' \
		'try:' \
		'    if sys.argv[1].lower().endswith(".stl"):' \
		'        cmd = ["openscad", "-o", sys.argv[2], "--camera=0,0,0,60,0,25,200", "--imgsize=512,512", "/dev/null", "-D", f"import(\"{sys.argv[1]}\");"]' \
		'    else:' \
		'        cmd = ["openscad", "-o", sys.argv[2], "--imgsize=512,512", sys.argv[1]]' \
		'    subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)' \
		'    sys.exit(0)' \
		'except Exception: pass' \
		'sys.exit(1)' > $(BIN_DIR)/stl_thumbnailer

	@printf '%s\n' \
		'[Thumbnailer Entry]' \
		'TryExec=openscad' \
		'Exec=$(BIN_DIR)/stl_thumbnailer %i %o %s' \
		'MimeType=model/stl;model/x.stl-ascii;model/x.stl-binary;' > $(THUMB_DIR)/stl.thumbnailer

	@printf '%s\n' \
		'[Thumbnailer Entry]' \
		'TryExec=openscad' \
		'Exec=$(BIN_DIR)/stl_thumbnailer %i %o %s' \
		'MimeType=text/x-computational-geometry;' > $(THUMB_DIR)/openscad.thumbnailer

	# 7. Permissões, base MIME, limpeza de cache e reinício do Nautilus
	@echo "Atualizando permissões e base de dados..."
	@chmod 755 $(BIN_DIR)/gcode_thumbnailer $(BIN_DIR)/3mf_thumbnailer $(BIN_DIR)/stl_thumbnailer
	@update-mime-database /usr/share/mime
	@echo "Limpando cache de miniaturas do usuário ($(REAL_USER))..."
	@rm -rf $(USER_HOME)/.cache/thumbnails/*
	@rm -rf /root/.cache/thumbnails/*
	@echo "Reiniciando o Nautilus..."
	@killall nautilus 2>/dev/null || pkill -f nautilus 2>/dev/null || true
	@echo "=========================================================="
	@echo "Instalação concluída com sucesso! Miniaturas prontas."
	@echo "=========================================================="

uninstall:
	@echo "Removendo configurações..."
	rm -f $(BIN_DIR)/gcode_thumbnailer $(BIN_DIR)/3mf_thumbnailer $(BIN_DIR)/stl_thumbnailer
	rm -f $(THUMB_DIR)/gcode.thumbnailer $(THUMB_DIR)/3mf.thumbnailer $(THUMB_DIR)/stl.thumbnailer $(THUMB_DIR)/openscad.thumbnailer
	rm -f $(MIME_DIR)/gcode.xml
	@update-mime-database /usr/share/mime
	@rm -rf $(USER_HOME)/.cache/thumbnails/*
	@killall nautilus 2>/dev/null || pkill -f nautilus 2>/dev/null || true
	@echo "Desinstalação concluída!"
