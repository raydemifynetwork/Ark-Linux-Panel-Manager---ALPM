#!/bin/bash

# Sistema de Instalação Completo - ALPM
# install.sh

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Diretórios
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PANEL_ROOT="$(dirname "$SCRIPT_DIR")"
ARK_DIR="$PANEL_ROOT/ark-server"
LOGS_DIR="$PANEL_ROOT/logs"
INSTALL_LOG="$LOGS_DIR/install.log"
STATUS_FILE="$PANEL_ROOT/status/install_status.txt"

# Criar diretórios necessários
mkdir -p "$ARK_DIR" "$LOGS_DIR" "$PANEL_ROOT/status"

# Função para log
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$INSTALL_LOG"
}

# Função para verificar se servidor está instalado
verificar_instalacao() {
    if [ -d "$ARK_DIR/ShooterGame/Binaries/Linux" ] && [ -f "$ARK_DIR/ShooterGame/Binaries/Linux/ShooterGameServer" ]; then
        return 0
    else
        return 1
    fi
}

# Função para verificar se instalação está em andamento
verificar_instalacao_andamento() {
    if [ -f "$STATUS_FILE" ]; then
        STATUS=$(cat "$STATUS_FILE" 2>/dev/null)
        if [[ "$STATUS" == "INSTALANDO"* ]] || [[ "$STATUS" == "ATUALIZANDO"* ]]; then
            return 0
        fi
    fi
    return 1
}

# Função para mostrar status da instalação
mostrar_status_instalacao() {
    echo -e "${BLUE}=== STATUS DA INSTALAÇÃO ===${NC}"
    
    if verificar_instalacao_andamento; then
        if [ -f "$STATUS_FILE" ]; then
            STATUS=$(cat "$STATUS_FILE")
            echo -e "${YELLOW}Status: $STATUS${NC}"
            echo -e "${BLUE}Logs disponíveis em: $INSTALL_LOG${NC}"
        fi
    elif verificar_instalacao; then
        echo -e "${GREEN}✅ Servidor Ark já está instalado${NC}"
        echo -e "${BLUE}Diretório: $ARK_DIR${NC}"
    else
        echo -e "${RED}❌ Servidor Ark não está instalado${NC}"
    fi
}

# Função para ver logs da instalação
ver_logs_instalacao() {
    if [ -f "$INSTALL_LOG" ]; then
        echo -e "${BLUE}=== LOGS DA INSTALAÇÃO ===${NC}"
        echo "1) Ver últimas 50 linhas"
        echo "2) Ver log completo"
        echo "3) Seguir em tempo real (Ctrl+C para sair)"
        echo "4) Voltar"
        read -p "Escolha uma opção: " opcao_log
        
        case $opcao_log in
            1)
                echo -e "${YELLOW}=== Últimas 50 linhas ===${NC}"
                tail -50 "$INSTALL_LOG"
                ;;
            2)
                less "$INSTALL_LOG"
                ;;
            3)
                echo -e "${YELLOW}Seguindo logs em tempo real... (Ctrl+C para sair)${NC}"
                tail -f "$INSTALL_LOG"
                ;;
            4)
                return
                ;;
            *)
                echo -e "${RED}Opção inválida!${NC}"
                ;;
        esac
    else
        echo -e "${YELLOW}Nenhum log encontrado${NC}"
    fi
}

# Função para instalar dependências
instalar_dependencias() {
    log_message "Verificando e instalando dependências..."
    echo -e "${BLUE}Verificando dependências do sistema...${NC}"
    
    # Detectar distribuição Linux
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$NAME
    else
        DISTRO="Desconhecida"
    fi
    
    echo -e "${BLUE}Distribuição detectada: $DISTRO${NC}"
    
    # Instalar dependências baseado na distribuição
    if command -v apt &> /dev/null; then
        sudo apt update >> "$INSTALL_LOG" 2>&1
        sudo apt install -y curl wget tar bzip2 lib32gcc1 >> "$INSTALL_LOG" 2>&1
    elif command -v yum &> /dev/null; then
        sudo yum install -y curl wget tar bzip2 glibc.i686 >> "$INSTALL_LOG" 2>&1
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y curl wget tar bzip2 glibc.i686 >> "$INSTALL_LOG" 2>&1
    elif command -v pacman &> /dev/null; then
        sudo pacman -Syu --noconfirm curl wget tar bzip2 gcc-libs >> "$INSTALL_LOG" 2>&1
    else
        echo -e "${YELLOW}Gerenciador de pacotes não reconhecido. Instale manualmente: curl, wget, tar, bzip2${NC}"
        read -p "Pressione ENTER para continuar (ou Ctrl+C para cancelar)..."
    fi
    
    log_message "Dependências instaladas com sucesso"
    echo -e "${GREEN}✅ Dependências instaladas${NC}"
}

# Função para instalar SteamCMD
instalar_steamcmd() {
    log_message "Iniciando instalação do SteamCMD..."
    echo -e "${BLUE}Instalando SteamCMD...${NC}"
    
    mkdir -p "$ARK_DIR/steamcmd"
    cd "$ARK_DIR/steamcmd"
    
    # Baixar SteamCMD
    if wget -q https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz -O steamcmd.tar.gz; then
        tar -xzf steamcmd.tar.gz >> "$INSTALL_LOG" 2>&1
        rm -f steamcmd.tar.gz
        log_message "SteamCMD instalado com sucesso"
        echo -e "${GREEN}✅ SteamCMD instalado${NC}"
        return 0
    else
        log_message "ERRO: Falha ao baixar SteamCMD"
        echo -e "${RED}Erro ao baixar SteamCMD${NC}"
        return 1
    fi
}

# Função para instalar servidor Ark
instalar_servidor_ark() {
    log_message "Iniciando instalação do servidor Ark..."
    echo -e "${BLUE}Instalando servidor Ark Survival Evolved...${NC}"
    echo -e "${YELLOW}Este processo pode levar 10-30 minutos...${NC}"
    
    cd "$ARK_DIR/steamcmd"
    
    # Criar script de instalação
    cat > ark_install.txt << 'EOI'
login anonymous
force_install_dir ../
app_update 376030 validate
quit
EOI
    
    # Executar instalação
    echo -e "${BLUE}Baixando e instalando servidor Ark...${NC}"
    if ./steamcmd.sh +runscript ark_install.txt >> "$INSTALL_LOG" 2>&1; then
        rm -f ark_install.txt
        log_message "Servidor Ark instalado com sucesso"
        echo -e "${GREEN}✅ Servidor Ark instalado com sucesso!${NC}"
        return 0
    else
        rm -f ark_install.txt
        log_message "ERRO: Falha na instalação do servidor Ark"
        echo -e "${RED}Erro na instalação do servidor Ark${NC}"
        return 1
    fi
}

# Função para criar scripts de gerenciamento
criar_scripts_gerenciamento() {
    log_message "Criando scripts de gerenciamento..."
    echo -e "${BLUE}Criando scripts de gerenciamento...${NC}"
    
    # Script de inicialização básico
    cat > "$ARK_DIR/start_server.sh" << 'EOI'
#!/bin/bash
cd "$(dirname "$0")"

# Configurações básicas
MAP_NAME="TheIsland"
SESSION_NAME="MyArkServer"

# Executar servidor
./ShooterGame/Binaries/Linux/ShooterGameServer "$MAP_NAME?listen?SessionName=$SESSION_NAME?Port=7777?QueryPort=27015" -server -log
EOI

    # Script de parada
    cat > "$ARK_DIR/stop_server.sh" << 'EOI'
#!/bin/bash
pkill -f ShooterGameServer
echo "Servidor Ark parado"
EOI

    # Dar permissões de execução
    chmod +x "$ARK_DIR/start_server.sh" "$ARK_DIR/stop_server.sh"
    
    log_message "Scripts de gerenciamento criados com sucesso"
    echo -e "${GREEN}✅ Scripts de gerenciamento criados${NC}"
}

# Função principal de instalação
instalar_servidor() {
    # Verificar se já está instalando
    if verificar_instalacao_andamento; then
        echo -e "${YELLOW}Instalação já está em andamento!${NC}"
        mostrar_status_instalacao
        return
    fi
    
    # Verificar se já está instalado
    if verificar_instalacao; then
        echo -e "${YELLOW}Servidor já está instalado!${NC}"
        echo "Deseja reinstalar? (isso pode sobrescrever arquivos existentes)"
        read -p "Continuar? (s/N): " confirmar
        if [[ ! "$confirmar" =~ ^[Ss]$ ]]; then
            return
        fi
    fi
    
    # Iniciar processo de instalação
    echo "INSTALANDO - Iniciando processo" > "$STATUS_FILE"
    
    log_message "=== INICIANDO INSTALAÇÃO DO SERVIDOR ARK ==="
    echo -e "${GREEN}=== INICIANDO INSTALAÇÃO DO SERVIDOR ARK ===${NC}"
    
    # Etapa 1: Dependências
    echo "INSTALANDO - Instalando dependências" > "$STATUS_FILE"
    if ! instalar_dependencias; then
        echo "ERRO - Falha nas dependências" > "$STATUS_FILE"
        return 1
    fi
    
    # Etapa 2: SteamCMD
    echo "INSTALANDO - Instalando SteamCMD" > "$STATUS_FILE"
    if ! instalar_steamcmd; then
        echo "ERRO - Falha na instalação do SteamCMD" > "$STATUS_FILE"
        return 1
    fi
    
    # Etapa 3: Servidor Ark
    echo "INSTALANDO - Instalando servidor Ark (pode levar 10-30 minutos)" > "$STATUS_FILE"
    if ! instalar_servidor_ark; then
        echo "ERRO - Falha na instalação do servidor Ark" > "$STATUS_FILE"
        return 1
    fi
    
    # Etapa 4: Scripts de gerenciamento
    echo "INSTALANDO - Criando scripts de gerenciamento" > "$STATUS_FILE"
    criar_scripts_gerenciamento
    
    # Finalizar instalação
    echo "CONCLUIDO - Instalação finalizada com sucesso" > "$STATUS_FILE"
    log_message "=== INSTALAÇÃO CONCLUÍDA COM SUCESSO ==="
    echo -e "${GREEN}=== INSTALAÇÃO CONCLUÍDA COM SUCESSO ===${NC}"
    
    # Aguardar 5 segundos e limpar status
    sleep 5
    rm -f "$STATUS_FILE"
}

# Menu de instalação
menu_instalacao() {
    while true; do
        clear
        echo -e "${BLUE}=== SISTEMA DE INSTALAÇÃO - ALPM ===${NC}"
        echo ""
        mostrar_status_instalacao
        echo ""
        echo "1) Instalar/Reinstalar Servidor Ark"
        echo "2) Ver Status Detalhado"
        echo "3) Ver Logs da Instalação"
        echo "4) Verificar Instalação"
        echo "5) Voltar ao Menu Principal"
        echo ""
        read -p "Escolha uma opção: " opcao
        
        case $opcao in
            1)
                instalar_servidor
                echo ""
                read -p "Pressione ENTER para continuar..."
                ;;
            2)
                mostrar_status_instalacao
                echo ""
                read -p "Pressione ENTER para continuar..."
                ;;
            3)
                ver_logs_instalacao
                echo ""
                read -p "Pressione ENTER para continuar..."
                ;;
            4)
                if verificar_instalacao; then
                    echo -e "${GREEN}✅ Servidor Ark está instalado${NC}"
                else
                    echo -e "${RED}❌ Servidor Ark não está instalado${NC}"
                fi
                echo ""
                read -p "Pressione ENTER para continuar..."
                ;;
            5)
                echo "Voltando ao menu principal..."
                break
                ;;
            *)
                echo -e "${RED}Opção inválida!${NC}"
                sleep 2
                ;;
        esac
    done
}

# Executar menu se script for chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    menu_instalacao
fi
