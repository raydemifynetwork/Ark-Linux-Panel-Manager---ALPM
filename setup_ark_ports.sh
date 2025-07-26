#!/bin/bash

# Script para configurar todas as portas necessárias para múltiplos servidores ARK + painel web
# Salve como: setup_ark_ports.sh

echo "=== Configurando portas para múltiplos servidores ARK ==="

# 1. Portas para o Painel Web
echo "🌐 Configurando portas do painel web..."
sudo ufw allow 5000/tcp    # Painel web principal
sudo ufw allow 80/tcp      # HTTP (opcional)
sudo ufw allow 443/tcp     # HTTPS (opcional)

# 2. Portas para múltiplos servidores ARK (para 10 servidores)
echo "🎮 Configurando portas para servidores ARK..."

# Para 10 servidores ARK
for i in {0..9}; do
    GAME_PORT=$((7777 + i * 10))
    QUERY_PORT=$((27015 + i * 10))
    RCON_PORT=$((32330 + i * 10))
    RAW_PORT=$((7777 + i * 10))  # Porta raw socket
    
    echo "Configurando servidor $((i+1)): Game=$GAME_PORT, Query=$QUERY_PORT, RCON=$RCON_PORT"
    
    # Portas UDP
    sudo ufw allow $GAME_PORT/udp
    sudo ufw allow $QUERY_PORT/udp
    sudo ufw allow $RAW_PORT/udp
    
    # Porta TCP RCON
    sudo ufw allow $RCON_PORT/tcp
done

# 3. Portas para FTP (se instalado)
echo "📁 Configurando portas FTP..."
sudo ufw allow 20/tcp
sudo ufw allow 21/tcp
sudo ufw allow 40000:40100/tcp

# 4. Portas adicionais que podem ser úteis
echo "🔧 Configurando portas adicionais..."
sudo ufw allow 22/tcp      # SSH (já deve estar aberto)
sudo ufw allow 8080/tcp    # Porta alternativa para web

# 5. Mostrar todas as portas configuradas
echo ""
echo "=== PORTAS CONFIGURADAS ==="
echo "🌐 Painel Web:"
echo "   5000/tcp     - Painel de controle ARK"
echo "   80/tcp       - HTTP (opcional)"
echo "   443/tcp      - HTTPS (opcional)"
echo ""
echo "🎮 Servidores ARK (10 servidores):"
for i in {0..9}; do
    GAME_PORT=$((7777 + i * 10))
    QUERY_PORT=$((27015 + i * 10))
    RCON_PORT=$((32330 + i * 10))
    echo "   Servidor $((i+1)): $GAME_PORT/udp, $QUERY_PORT/udp, $RCON_PORT/tcp"
done
echo ""
echo "📁 FTP:"
echo "   20/tcp       - FTP Data"
echo "   21/tcp       - FTP Control"
echo "   40000:40100/tcp - FTP Passive Ports"
echo ""

# 6. Verificar status do firewall
echo "🛡️ Status do firewall:"
sudo ufw status

echo ""
echo "✅ Configuração de portas concluída!"
echo "💡 Para reiniciar o firewall: sudo ufw reload"
