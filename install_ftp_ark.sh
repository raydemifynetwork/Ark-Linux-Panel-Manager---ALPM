#!/bin/bash

# Script de instalação automática do servidor FTP para ARK Server
# Salve como: install_ftp_ark.sh
# Execute com: chmod +x install_ftp_ark.sh && ./install_ftp_ark.sh

echo "=== Instalando e configurando servidor FTP para ARK Server ==="

# Verificar se usuário arkserver existe
if ! id "arkserver" &>/dev/null; then
    echo "❌ Usuário arkserver não encontrado!"
    echo "Por favor, crie o usuário arkserver primeiro:"
    echo "sudo adduser arkserver"
    exit 1
fi

# 1. Instalar vsftpd
echo "📥 Instalando vsftpd..."
sudo apt update
sudo apt install -y vsftpd

# 2. Backup da configuração original
echo "💾 Fazendo backup da configuração original..."
sudo cp /etc/vsftpd.conf /etc/vsftpd.conf.bak

# 3. Criar configuração personalizada
echo "⚙️ Configurando vsftpd..."
sudo cat > /etc/vsftpd.conf << 'EOF'
# Configurações básicas do vsftpd
listen=NO
listen_ipv6=YES
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
use_localtime=YES
xferlog_enable=YES
connect_from_port_20=YES
secure_chroot_dir=/var/run/vsftpd/empty
pam_service_name=vsftpd
rsa_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem
rsa_private_key_file=/etc/ssl/private/ssl-cert-snakeoil.key
ssl_enable=NO

# Configurações de segurança
chroot_local_user=YES
allow_writeable_chroot=YES

# Diretório raiz do FTP
local_root=/home/arkserver/ftp

# Configurações de porta passiva
pasv_enable=YES
pasv_min_port=40000
pasv_max_port=40100

# Timeout
idle_session_timeout=300
data_connection_timeout=120

# Lista de usuários permitidos
userlist_enable=YES
userlist_file=/etc/vsftpd.userlist
userlist_deny=NO

# Mensagens de log
xferlog_std_format=NO
log_ftp_protocol=YES
EOF

# 4. Criar diretório FTP para o usuário arkserver
echo "📂 Criando estrutura de diretórios..."
sudo mkdir -p /home/arkserver/ftp
sudo mkdir -p /home/arkserver/ftp/ark-saves
sudo mkdir -p /home/arkserver/ftp/ark-configs
sudo mkdir -p /home/arkserver/ftp/ark-mods

# 5. Definir permissões corretas
echo "🔐 Configurando permissões..."
sudo chown -R arkserver:arkserver /home/arkserver/ftp
sudo chmod -R 755 /home/arkserver/ftp

# 6. Criar links simbólicos para os diretórios importantes do ARK
echo "🔗 Criando links para diretórios do ARK Server..."
if [ -d "/home/arkserver/arkserver/ShooterGame/Saved" ]; then
    sudo ln -s /home/arkserver/arkserver/ShooterGame/Saved /home/arkserver/ftp/ark-saves/saved-files 2>/dev/null || true
fi

if [ -d "/home/arkserver/arkserver/ShooterGame/Content/Mods" ]; then
    sudo ln -s /home/arkserver/arkserver/ShooterGame/Content/Mods /home/arkserver/ftp/ark-mods/game-mods 2>/dev/null || true
fi

# 7. Criar lista de usuários permitidos
echo "👥 Configurando lista de usuários..."
echo "arkserver" | sudo tee /etc/vsftpd.userlist > /dev/null

# 8. Configurar firewall
echo "🔥 Configurando firewall..."
sudo ufw allow 20/tcp
sudo ufw allow 21/tcp
sudo ufw allow 40000:40100/tcp
sudo ufw --force enable

# 9. Reiniciar serviço
echo "🔄 Reiniciando serviço vsftpd..."
sudo systemctl restart vsftpd
sudo systemctl enable vsftpd

# 10. Verificar status
echo "✅ Verificando status do serviço..."
if sudo systemctl is-active --quiet vsftpd; then
    echo "🎉 Serviço FTP está rodando!"
else
    echo "❌ Erro ao iniciar serviço FTP!"
    sudo systemctl status vsftpd
    exit 1
fi

# 11. Mostrar informações de conexão
echo ""
echo "=== CONFIGURAÇÃO CONCLUÍDA! ==="
echo ""
echo "📁 Diretórios disponíveis via FTP:"
echo "   /ark-saves     - Saves do servidor ARK"
echo "   /ark-configs   - Arquivos de configuração"
echo "   /ark-mods      - Mods do servidor"
echo ""
echo "👤 Credenciais FTP:"
echo "   Usuário: arkserver"
echo "   Senha: (a mesma do usuário do sistema)"
echo ""
echo "🌐 Portas abertas:"
echo "   21/tcp    - Controle FTP"
echo "   20/tcp    - Dados FTP"
echo "   40000-40100/tcp - Portas passivas"
echo ""
echo "🔌 Como conectar:"
echo "   1. Use um cliente FTP (FileZilla, WinSCP, etc.)"
echo "   2. Conecte-se usando o IP do seu servidor"
echo "   3. Use as credenciais acima"
echo ""
echo "🔧 Comandos úteis:"
echo "   sudo systemctl status vsftpd     # Ver status"
echo "   sudo systemctl restart vsftpd    # Reiniciar FTP"
echo "   sudo passwd arkserver           # Alterar senha"
echo ""
echo "💡 Dica: Para alterar a senha do usuário arkserver:"
echo "   sudo passwd arkserver"
echo ""
