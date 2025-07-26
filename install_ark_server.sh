#!/bin/bash

# Script de instalação automática do servidor ARK: Survival Evolved
# Salve como: install_ark_server.sh
# Execute com: chmod +x install_ark_server.sh && ./install_ark_server.sh

echo "=== Instalando Servidor ARK: Survival Evolved ==="

# 1. Atualizar sistema
echo "Atualizando sistema..."
sudo apt update && sudo apt upgrade -y

# 2. Instalar dependências
echo "Instalando dependências..."
sudo apt install -y wget curl lib32gcc-s1 gdb

# 3. Criar usuário arkserver
echo "Criando usuário arkserver..."
sudo useradd -m -s /bin/bash arkserver
echo "arkserver:arkserver123" | sudo chpasswd
sudo usermod -aG sudo arkserver

# 4. Instalar SteamCMD e servidor ARK como arkserver
echo "Instalando SteamCMD e servidor ARK..."
sudo -u arkserver bash << 'EOF'
cd ~
mkdir -p ~/steamcmd
cd ~/steamcmd
wget http://media.steampowered.com/installer/steamcmd_linux.tar.gz
tar -xvzf steamcmd_linux.tar.gz

# Instalar servidor ARK
./steamcmd.sh +login anonymous +force_install_dir ~/arkserver +app_update 376030 validate +quit

# Criar script de inicialização
cat > ~/arkserver/start.sh << 'EOT'
#!/bin/bash
cd ~/arkserver/ShooterGame/Binaries/Linux
./ShooterGameServer "TheIsland?listen?SessionName=ServidorARK?ServerPassword=?ServerAdminPassword=admin123" -server -log
EOT

chmod +x ~/arkserver/start.sh
EOF

# 5. Criar serviço systemd
echo "Criando serviço systemd..."
cat > /etc/systemd/system/arkserver.service << 'EOF'
[Unit]
Description=ARK Survival Evolved Server
After=network.target

[Service]
Type=simple
User=arkserver
WorkingDirectory=/home/arkserver/arkserver
ExecStart=/home/arkserver/arkserver/start.sh
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# 6. Configurar permissões e serviços
echo "Configurando permissões e serviços..."
sudo systemctl daemon-reload
sudo systemctl enable arkserver

# 7. Abrir portas no firewall
echo "Abrindo portas no firewall..."
sudo ufw allow 7777/udp
sudo ufw allow 7778/udp
sudo ufw allow 27015/udp

# 8. Iniciar servidor
echo "Iniciando servidor ARK..."
sudo systemctl start arkserver

echo "=== Instalação concluída! ==="
echo ""
echo "Usuário criado: arkserver"
echo "Senha do usuário: arkserver123"
echo "Diretório do servidor: /home/arkserver/arkserver"
echo ""
echo "Comandos úteis:"
echo "  sudo systemctl status arkserver    # Ver status"
echo "  sudo systemctl stop arkserver      # Parar servidor"
echo "  sudo systemctl start arkserver     # Iniciar servidor"
echo "  sudo systemctl restart arkserver   # Reiniciar servidor"
echo ""
echo "Para personalizar as configurações do servidor:"
echo "  sudo nano /home/arkserver/arkserver/start.sh"
echo ""
echo "Para acessar os arquivos do servidor:"
echo "  su - arkserver"
