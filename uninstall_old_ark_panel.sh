#!/bin/bash

# Script para desinstalar completamente o painel ARK anterior
# Salve como: uninstall_old_ark_panel.sh

echo "=== 🗑️ Desinstalando Painel ARK Anterior ==="

# 1. Parar serviços antigos
echo "🛑 Parando serviços antigos..."
sudo systemctl stop ark-web-monitor 2>/dev/null || echo "Serviço ark-web-monitor não encontrado"
sudo systemctl disable ark-web-monitor 2>/dev/null || echo "Serviço ark-web-monitor não encontrado"

sudo systemctl stop ark-panel 2>/dev/null || echo "Serviço ark-panel não encontrado"
sudo systemctl disable ark-panel 2>/dev/null || echo "Serviço ark-panel não encontrado"

# 2. Remover arquivos e diretórios antigos
echo "🗂️ Removendo arquivos antigos..."
sudo rm -rf ~/ark-web-monitor 2>/dev/null
sudo rm -rf ~/ark-panel 2>/dev/null
sudo rm -rf ~/ARK-Server-Manager-Web 2>/dev/null

# 3. Remover serviços systemd antigos
echo "⚙️ Removendo serviços antigos..."
sudo rm -f /etc/systemd/system/ark-web-monitor.service
sudo rm -f /etc/systemd/system/ark-panel.service

# 4. Remover portas específicas do firewall (mantendo as essenciais)
echo "🔥 Limpando regras de firewall específicas..."
# Listar regras atuais
sudo ufw status numbered

# 5. Recarregar systemd
echo "🔄 Recarregando systemd..."
sudo systemctl daemon-reload

echo ""
echo "✅ Desinstalação concluída!"
echo "Agora você pode instalar o novo painel executando:"
echo "./install_complete_ark_panel.sh"
