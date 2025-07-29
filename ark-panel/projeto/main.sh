#!/bin/bash

# Menu Principal - ALPM
# main.sh

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Diretórios
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Função para verificar status da instalação
verificar_status_geral() {
    STATUS_FILE="$SCRIPT_DIR/../status/install_status.txt"
    if [ -f "$STATUS_FILE" ]; then
        STATUS=$(cat "$STATUS_FILE")
        echo -e "${YELLOW}[INSTALANDO] $STATUS${NC}"
    elif [ -d "$SCRIPT_DIR/../ark-server/ShooterGame/Binaries/Linux" ]; then
        echo -e "${GREEN}[INSTALADO] Servidor pronto${NC}"
    else
        echo -e "${RED}[NÃO INSTALADO] Servidor não encontrado${NC}"
    fi
}

# Menu principal
while true; do
    clear
    echo -e "${BLUE}=== ARK LINUX PANEL MANAGER (ALPM) ===${NC}"
    echo ""
    echo -e "${YELLOW}Status do Sistema:${NC}"
    verificar_status_geral
    echo ""
    echo "1) 💾 Instalação/Configuração do Servidor"
    echo "2) ▶️  Gerenciar Servidor"
    echo "3) 💾 Backup & Restauração"
    echo "4) 🔄 Atualizações"
    echo "5) 📊 Monitoramento"
    echo "6) ⚙️  Configurações Avançadas"
    echo "7) ❌ Sair"
    echo ""
    read -p "Escolha uma opção: " opcao_principal
    
    case $opcao_principal in
        1)
            if [ -f "$SCRIPT_DIR/install.sh" ]; then
                bash "$SCRIPT_DIR/install.sh"
            else
                echo -e "${RED}Script de instalação não encontrado!${NC}"
                sleep 2
            fi
            ;;
        2)
            if [ -f "$SCRIPT_DIR/server.sh" ]; then
                bash "$SCRIPT_DIR/server.sh"
            else
                echo -e "${RED}Script de servidor não encontrado!${NC}"
                sleep 2
            fi
            ;;
        3)
            if [ -f "$SCRIPT_DIR/backup.sh" ]; then
                bash "$SCRIPT_DIR/backup.sh"
            else
                echo -e "${RED}Script de backup não encontrado!${NC}"
                sleep 2
            fi
            ;;
        4)
            if [ -f "$SCRIPT_DIR/update.sh" ]; then
                bash "$SCRIPT_DIR/update.sh"
            else
                echo -e "${RED}Script de atualização não encontrado!${NC}"
                sleep 2
            fi
            ;;
        5)
            if [ -f "$SCRIPT_DIR/monitor.sh" ]; then
                bash "$SCRIPT_DIR/monitor.sh"
            else
                echo -e "${RED}Script de monitoramento não encontrado!${NC}"
                sleep 2
            fi
            ;;
        6)
            echo -e "${YELLOW}Configurações Avançadas - Em desenvolvimento${NC}"
            sleep 2
            ;;
        7)
            echo -e "${GREEN}Saindo do ALPM...${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Opção inválida!${NC}"
            sleep 2
            ;;
    esac
done
