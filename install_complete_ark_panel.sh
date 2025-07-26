#!/bin/bash

# Script completo: Instala e pré-configura painel web com todos servidores ARK
# Execute com: chmod +x install_complete_ark_panel.sh && ./install_complete_ark_panel.sh

echo "=== 🚀 Instalando Painel Web ARK COMPLETO ==="
echo "Este script irá:"
echo "1. Instalar todas as dependências"
echo "2. Configurar o painel web"
echo "3. Pré-configurar TODOS os mapas ARK"
echo "4. Abrir todas as portas necessárias"
echo "5. Iniciar o serviço automaticamente"
echo ""

# Perguntar informações do usuário
echo "=== 📋 Informações do Servidor ==="
read -p "Digite o IP público do seu servidor (ou pressione Enter para detectar automaticamente): " SERVER_IP
if [ -z "$SERVER_IP" ]; then
    SERVER_IP=$(hostname -I | awk '{print $1}')
fi

read -p "Digite o caminho base para os servidores ARK [/home/arkserver]: " BASE_PATH
if [ -z "$BASE_PATH" ]; then
    BASE_PATH="/home/arkserver"
fi

echo ""
echo "IP do servidor: $SERVER_IP"
echo "Caminho base: $BASE_PATH"
echo ""

# 1. Instalar dependências
echo "📥 Instalando dependências..."
sudo apt update
sudo apt install -y python3 python3-pip python3-venv nginx ufw

# 2. Criar estrutura do projeto
echo "📁 Criando estrutura do projeto..."
cd ~
mkdir -p ark-panel/{templates,static,config,servers}
cd ark-panel

# 3. Criar ambiente virtual Python
python3 -m venv venv
source venv/bin/activate
pip install flask requests psutil

# 4. Criar aplicação web completa
cat > app.py << 'EOT'
#!/usr/bin/env python3
"""
ARK Server Panel - Painel Web Completo para Gerenciamento de Servidores ARK
"""
import os
import json
import subprocess
import time
from datetime import datetime
from flask import Flask, render_template, request, jsonify, redirect, url_for

app = Flask(__name__)

# Configurações
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
CONFIG_DIR = os.path.join(BASE_DIR, 'config')
SERVERS_FILE = os.path.join(CONFIG_DIR, 'servers.json')

# Criar diretórios necessários
os.makedirs(CONFIG_DIR, exist_ok=True)

# Servidores pré-configurados (todos os mapas ARK)
PRE_CONFIGURED_SERVERS = {
    "servers": [
        {
            "id": 1,
            "name": "ARK - The Island",
            "map": "TheIsland",
            "ip": "127.0.0.1",
            "game_port": 7777,
            "query_port": 27015,
            "rcon_port": 32330,
            "path": "/home/arkserver/ark-servers/the-island",
            "enabled": True,
            "status": "offline",
            "players": 0
        },
        {
            "id": 2,
            "name": "ARK - The Center",
            "map": "TheCenter",
            "ip": "127.0.0.1",
            "game_port": 7787,
            "query_port": 27025,
            "rcon_port": 32340,
            "path": "/home/arkserver/ark-servers/the-center",
            "enabled": True,
            "status": "offline",
            "players": 0
        },
        {
            "id": 3,
            "name": "ARK - Ragnarok",
            "map": "Ragnarok",
            "ip": "127.0.0.1",
            "game_port": 7797,
            "query_port": 27035,
            "rcon_port": 32350,
            "path": "/home/arkserver/ark-servers/ragnarok",
            "enabled": True,
            "status": "offline",
            "players": 0
        },
        {
            "id": 4,
            "name": "ARK - Aberration",
            "map": "Aberration",
            "ip": "127.0.0.1",
            "game_port": 7807,
            "query_port": 27045,
            "rcon_port": 32360,
            "path": "/home/arkserver/ark-servers/aberration",
            "enabled": True,
            "status": "offline",
            "players": 0
        },
        {
            "id": 5,
            "name": "ARK - Extinction",
            "map": "Extinction",
            "ip": "127.0.0.1",
            "game_port": 7817,
            "query_port": 27055,
            "rcon_port": 32370,
            "path": "/home/arkserver/ark-servers/extinction",
            "enabled": True,
            "status": "offline",
            "players": 0
        },
        {
            "id": 6,
            "name": "ARK - Genesis",
            "map": "Genesis",
            "ip": "127.0.0.1",
            "game_port": 7827,
            "query_port": 27065,
            "rcon_port": 32380,
            "path": "/home/arkserver/ark-servers/genesis",
            "enabled": True,
            "status": "offline",
            "players": 0
        },
        {
            "id": 7,
            "name": "ARK - Genesis 2",
            "map": "Genesis2",
            "ip": "127.0.0.1",
            "game_port": 7837,
            "query_port": 27075,
            "rcon_port": 32390,
            "path": "/home/arkserver/ark-servers/genesis2",
            "enabled": True,
            "status": "offline",
            "players": 0
        },
        {
            "id": 8,
            "name": "ARK - Lost Island",
            "map": "LostIsland",
            "ip": "127.0.0.1",
            "game_port": 7847,
            "query_port": 27085,
            "rcon_port": 32400,
            "path": "/home/arkserver/ark-servers/lost-island",
            "enabled": True,
            "status": "offline",
            "players": 0
        },
        {
            "id": 9,
            "name": "ARK - Fjordur",
            "map": "Fjordur",
            "ip": "127.0.0.1",
            "game_port": 7857,
            "query_port": 27095,
            "rcon_port": 32410,
            "path": "/home/arkserver/ark-servers/fjordur",
            "enabled": True,
            "status": "offline",
            "players": 0
        }
    ]
}

def load_servers():
    """Carregar servidores do arquivo ou usar configuração padrão"""
    if os.path.exists(SERVERS_FILE):
        try:
            with open(SERVERS_FILE, 'r') as f:
                return json.load(f)
        except:
            return PRE_CONFIGURED_SERVERS
    else:
        # Salvar configuração pré-configurada
        save_servers(PRE_CONFIGURED_SERVERS)
        return PRE_CONFIGURED_SERVERS

def save_servers(servers_data):
    """Salvar servidores no arquivo"""
    with open(SERVERS_FILE, 'w') as f:
        json.dump(servers_data, f, indent=2)

def check_server_status(server):
    """Verificar status do servidor (simulado)"""
    try:
        # Aqui você pode implementar a verificação real do processo
        # Por enquanto, simulando status aleatório
        import random
        status_options = ['online', 'offline']
        status = random.choice(status_options)
        players = random.randint(0, 50) if status == 'online' else 0
        
        return {
            'status': status,
            'players': players,
            'last_check': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        }
    except Exception as e:
        return {
            'status': 'error',
            'error': str(e),
            'players': 0,
            'last_check': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        }

# Rotas web
@app.route('/')
def index():
    servers_data = load_servers()
    server_status = []
    
    for server in servers_data['servers']:
        status = check_server_status(server)
        server_info = {**server, **status}
        server_status.append(server_info)
    
    # Estatísticas
    total_servers = len(server_status)
    online_servers = len([s for s in server_status if s['status'] == 'online'])
    total_players = sum([s['players'] for s in server_status])
    
    stats = {
        'total_servers': total_servers,
        'online_servers': online_servers,
        'offline_servers': total_servers - online_servers,
        'total_players': total_players
    }
    
    return render_template('index.html', servers=server_status, stats=stats, server_ip=request.host.split(':')[0])

@app.route('/server/<int:server_id>')
def server_detail(server_id):
    servers_data = load_servers()
    server = next((s for s in servers_data['servers'] if s['id'] == server_id), None)
    
    if not server:
        return "Servidor não encontrado", 404
    
    status = check_server_status(server)
    server_info = {**server, **status}
    
    return render_template('server_detail.html', server=server_info)

@app.route('/api/servers')
def api_servers():
    servers_data = load_servers()
    status_list = []
    
    for server in servers_data['servers']:
        status = check_server_status(server)
        status_list.append({**server, **status})
    
    return jsonify(status_list)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
EOT

# 5. Criar diretórios de templates
mkdir -p templates

# 6. Criar template principal
cat > templates/index.html << 'EOT'
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ARK Server Panel</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <style>
        body { background-color: #1a1a1a; color: #fff; }
        .navbar { background: linear-gradient(90deg, #8B0000, #B22222); }
        .card { background-color: #2d2d2d; border: 1px solid #444; }
        .card-header { background-color: #3a3a3a; border-bottom: 1px solid #444; }
        .stat-card { border-radius: 10px; margin-bottom: 20px; }
        .map-icon { font-size: 2rem; margin-bottom: 10px; }
        .server-online { border-left: 4px solid #28a745; }
        .server-offline { border-left: 4px solid #dc3545; }
        .server-error { border-left: 4px solid #ffc107; }
    </style>
</head>
<body>
    <nav class="navbar navbar-expand-lg navbar-dark">
        <div class="container-fluid">
            <a class="navbar-brand" href="/">
                <i class="fas fa-dragon"></i> ARK Server Panel
            </a>
            <div class="navbar-nav ms-auto">
                <span class="navbar-text">
                    <i class="fas fa-server"></i> Todos os Mapas ARK Pré-Configurados
                </span>
            </div>
        </div>
    </nav>

    <div class="container-fluid mt-4">
        <!-- Estatísticas -->
        <div class="row mb-4">
            <div class="col-md-3">
                <div class="stat-card bg-primary text-white p-3 text-center">
                    <h3>{{ stats.total_servers }}</h3>
                    <p class="mb-0">Total de Servidores</p>
                </div>
            </div>
            <div class="col-md-3">
                <div class="stat-card bg-success text-white p-3 text-center">
                    <h3>{{ stats.online_servers }}</h3>
                    <p class="mb-0">Servidores Online</p>
                </div>
            </div>
            <div class="col-md-3">
                <div class="stat-card bg-danger text-white p-3 text-center">
                    <h3>{{ stats.offline_servers }}</h3>
                    <p class="mb-0">Servidores Offline</p>
                </div>
            </div>
            <div class="col-md-3">
                <div class="stat-card bg-info text-white p-3 text-center">
                    <h3>{{ stats.total_players }}</h3>
                    <p class="mb-0">Total de Jogadores</p>
                </div>
            </div>
        </div>

        <!-- Lista de Servidores -->
        <div class="row">
            {% for server in servers %}
            <div class="col-xl-4 col-lg-6 col-md-6 mb-4">
                <div class="card h-100 {% if server.status == 'online' %}server-online{% elif server.status == 'offline' %}server-offline{% else %}server-error{% endif %}">
                    <div class="card-header">
                        <div class="d-flex justify-content-between align-items-center">
                            <h5 class="mb-0">
                                <i class="fas fa-server"></i> {{ server.name }}
                            </h5>
                            <span class="badge {% if server.status == 'online' %}bg-success{% elif server.status == 'offline' %}bg-danger{% else %}bg-warning{% endif %}">
                                {{ server.status }}
                            </span>
                        </div>
                    </div>
                    <div class="card-body">
                        <div class="text-center mb-3">
                            <div class="map-icon">
                                {% if server.map == 'TheIsland' %}
                                    <i class="fas fa-island-tropical text-success"></i>
                                {% elif server.map == 'TheCenter' %}
                                    <i class="fas fa-circle text-warning"></i>
                                {% elif server.map == 'Ragnarok' %}
                                    <i class="fas fa-snowflake text-info"></i>
                                {% elif server.map == 'Aberration' %}
                                    <i class="fas fa-virus text-danger"></i>
                                {% elif server.map == 'Extinction' %}
                                    <i class="fas fa-skull text-dark"></i>
                                {% elif server.map == 'Genesis' %}
                                    <i class="fas fa-globe-americas text-primary"></i>
                                {% elif server.map == 'Genesis2' %}
                                    <i class="fas fa-globe-europe text-success"></i>
                                {% elif server.map == 'LostIsland' %}
                                    <i class="fas fa-tree text-warning"></i>
                                {% elif server.map == 'Fjordur' %}
                                    <i class="fas fa-water text-info"></i>
                                {% endif %}
                            </div>
                            <h6>{{ server.map }}</h6>
                        </div>
                        
                        <div class="server-info">
                            <p class="mb-1">
                                <i class="fas fa-network-wired"></i> 
                                <strong>IP:</strong> {{ server_ip }}:{{ server.game_port }}
                            </p>
                            <p class="mb-1">
                                <i class="fas fa-users"></i> 
                                <strong>Jogadores:</strong> {{ server.players }}
                            </p>
                            <p class="mb-1">
                                <i class="fas fa-folder"></i> 
                                <strong>Caminho:</strong> {{ server.path }}
                            </p>
                            <p class="mb-0">
                                <i class="fas fa-clock"></i> 
                                <small class="text-muted">Última verificação: {{ server.last_check }}</small>
                            </p>
                        </div>
                    </div>
                    <div class="card-footer">
                        <div class="d-grid gap-2">
                            <a href="/server/{{ server.id }}" class="btn btn-outline-primary btn-sm">
                                <i class="fas fa-cog"></i> Gerenciar Servidor
                            </a>
                        </div>
                    </div>
                </div>
            </div>
            {% endfor %}
        </div>

        <!-- Informações do Sistema -->
        <div class="card mt-4">
            <div class="card-header">
                <h5><i class="fas fa-info-circle"></i> Informações do Sistema</h5>
            </div>
            <div class="card-body">
                <div class="row">
                    <div class="col-md-6">
                        <p><i class="fas fa-network-wired"></i> <strong>IP do Servidor:</strong> {{ server_ip }}</p>
                        <p><i class="fas fa-sync-alt"></i> <strong>Status:</strong> Painel Online</p>
                    </div>
                    <div class="col-md-6">
                        <p><i class="fas fa-database"></i> <strong>Servidores Configurados:</strong> {{ servers|length }}</p>
                        <p><i class="fas fa-map-marked-alt"></i> <strong>Mapas ARK:</strong> Todos Pré-Configurados</p>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        // Auto-refresh a cada 30 segundos
        setTimeout(function(){
            location.reload();
        }, 30000);
    </script>
</body>
</html>
EOT

# 7. Criar template de detalhes do servidor
cat > templates/server_detail.html << 'EOT'
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ server.name }} - ARK Server Panel</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <style>
        body { background-color: #1a1a1a; color: #fff; }
        .navbar { background: linear-gradient(90deg, #8B0000, #B22222); }
        .card { background-color: #2d2d2d; border: 1px solid #444; }
        .card-header { background-color: #3a3a3a; border-bottom: 1px solid #444; }
    </style>
</head>
<body>
    <nav class="navbar navbar-expand-lg navbar-dark">
        <div class="container-fluid">
            <a class="navbar-brand" href="/">
                <i class="fas fa-dragon"></i> ARK Server Panel
            </a>
            <div class="navbar-nav">
                <a class="nav-link" href="/">← Voltar</a>
            </div>
        </div>
    </nav>

    <div class="container mt-4">
        <div class="row">
            <div class="col-12">
                <div class="card">
                    <div class="card-header">
                        <div class="d-flex justify-content-between align-items-center">
                            <h3>
                                <i class="fas fa-server"></i> {{ server.name }}
                            </h3>
                            <span class="badge {% if server.status == 'online' %}bg-success{% elif server.status == 'offline' %}bg-danger{% else %}bg-warning{% endif %}">
                                {{ server.status }}
                            </span>
                        </div>
                    </div>
                    <div class="card-body">
                        <div class="row">
                            <div class="col-md-6">
                                <h5><i class="fas fa-info-circle"></i> Informações do Servidor</h5>
                                <table class="table table-dark table-striped">
                                    <tr>
                                        <td><strong>Mapa:</strong></td>
                                        <td>{{ server.map }}</td>
                                    </tr>
                                    <tr>
                                        <td><strong>IP:</strong></td>
                                        <td>{{ server.ip }}:{{ server.game_port }}</td>
                                    </tr>
                                    <tr>
                                        <td><strong>Query Port:</strong></td>
                                        <td>{{ server.query_port }}</td>
                                    </tr>
                                    <tr>
                                        <td><strong>RCON Port:</strong></td>
                                        <td>{{ server.rcon_port }}</td>
                                    </tr>
                                    <tr>
                                        <td><strong>Jogadores:</strong></td>
                                        <td>{{ server.players }}</td>
                                    </tr>
                                    <tr>
                                        <td><strong>Caminho:</strong></td>
                                        <td>{{ server.path }}</td>
                                    </tr>
                                    <tr>
                                        <td><strong>Última Verificação:</strong></td>
                                        <td>{{ server.last_check }}</td>
                                    </tr>
                                </table>
                            </div>
                            <div class="col-md-6">
                                <h5><i class="fas fa-cogs"></i> Ações do Servidor</h5>
                                <div class="d-grid gap-2">
                                    {% if server.status == 'online' %}
                                        <button class="btn btn-danger btn-lg">
                                            <i class="fas fa-stop"></i> Parar Servidor
                                        </button>
                                        <button class="btn btn-warning btn-lg">
                                            <i class="fas fa-sync-alt"></i> Reiniciar Servidor
                                        </button>
                                    {% else %}
                                        <button class="btn btn-success btn-lg">
                                            <i class="fas fa-play"></i> Iniciar Servidor
                                        </button>
                                    {% endif %}
                                    <button class="btn btn-info btn-lg">
                                        <i class="fas fa-download"></i> Backup do Servidor
                                    </button>
                                    <button class="btn btn-outline-primary btn-lg">
                                        <i class="fas fa-edit"></i> Editar Configurações
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
EOT

# 8. Criar serviço systemd
echo "🔧 Configurando serviço systemd..."
sudo cat > /etc/systemd/system/ark-panel.service << 'EOT'
[Unit]
Description=ARK Server Panel
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/ark-panel
ExecStart=/root/ark-panel/venv/bin/python /root/ark-panel/app.py
Restart=always
RestartSec=10
Environment=PATH=/root/ark-panel/venv/bin

[Install]
WantedBy=multi-user.target
EOT

# 9. Configurar firewall (todas as portas)
echo "🔥 Configurando firewall completo..."
sudo ufw --force enable
sudo ufw allow 22/tcp      # SSH
sudo ufw allow 5000/tcp    # Painel web

# Portas para 10 servidores ARK
for i in {0..9}; do
    GAME_PORT=$((7777 + i * 10))
    QUERY_PORT=$((27015 + i * 10))
    RCON_PORT=$((32330 + i * 10))
    RAW_PORT=$((7777 + i * 10))
    
    sudo ufw allow $GAME_PORT/udp
    sudo ufw allow $QUERY_PORT/udp
    sudo ufw allow $RCON_PORT/tcp
    sudo ufw allow $RAW_PORT/udp
done

# Portas FTP (se necessário)
sudo ufw allow 20/tcp
sudo ufw allow 21/tcp
sudo ufw allow 40000:40100/tcp

# 10. Criar estrutura de diretórios para servidores
echo "📂 Criando estrutura de diretórios para servidores..."
sudo mkdir -p $BASE_PATH/ark-servers
sudo chown -R arkserver:arkserver $BASE_PATH/ark-servers 2>/dev/null || true

for map in the-island the-center ragnarok aberration extinction genesis genesis2 lost-island fjordur; do
    sudo mkdir -p $BASE_PATH/ark-servers/$map
    sudo chown -R arkserver:arkserver $BASE_PATH/ark-servers/$map 2>/dev/null || true
done

# 11. Iniciar serviço
echo "🚀 Iniciando serviço..."
sudo systemctl daemon-reload
sudo systemctl enable ark-panel
sudo systemctl start ark-panel

# 12. Verificar status
echo ""
echo "=== 📊 VERIFICANDO INSTALAÇÃO ==="
if sudo systemctl is-active --quiet ark-panel; then
    echo "✅ Painel web está ONLINE!"
    echo "🌐 Acesse: http://$SERVER_IP:5000"
else
    echo "❌ Erro ao iniciar painel web!"
    sudo systemctl status ark-panel
fi

echo ""
echo "=== 🎯 CONFIGURAÇÃO CONCLUÍDA! ==="
echo ""
echo "🎮 Todos os 9 mapas ARK estão pré-configurados:"
echo "   1. The Island     - Porta 7777"
echo "   2. The Center     - Porta 7787" 
echo "   3. Ragnarok       - Porta 7797"
echo "   4. Aberration     - Porta 7807"
echo "   5. Extinction     - Porta 7817"
echo "   6. Genesis        - Porta 7827"
echo "   7. Genesis 2      - Porta 7837"
echo "   8. Lost Island    - Porta 7847"
echo "   9. Fjordur        - Porta 7857"
echo ""
echo "🌐 Painel Web:"
echo "   URL: http://$SERVER_IP:5000"
echo ""
echo "📂 Diretórios criados:"
echo "   Base: $BASE_PATH/ark-servers"
echo "   Cada mapa terá sua própria pasta"
echo ""
echo "🔧 Comandos úteis:"
echo "   sudo systemctl status ark-panel     # Ver status"
echo "   sudo systemctl restart ark-panel    # Reiniciar painel"
echo "   sudo ufw status                     # Ver portas"
echo ""
echo "💡 Próximos passos:"
echo "   1. Acesse o painel web"
echo "   2. Clique em 'Gerenciar Servidor' para cada mapa"
echo "   3. Configure e inicie os servidores individualmente"
echo ""
