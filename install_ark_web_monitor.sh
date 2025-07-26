#!/bin/bash

# Script de instalação automática do ARK Web Monitor
# Execute com: chmod +x install_ark_web_monitor.sh && ./install_ark_web_monitor.sh

echo "=== Instalando ARK Web Monitor ==="

# 1. Instalar dependências
echo "📥 Instalando dependências..."
sudo apt update
sudo apt install -y python3 python3-pip python3-venv

# 2. Criar ambiente virtual
echo "🐍 Configurando ambiente Python..."
cd ~
mkdir -p ark-web-monitor
cd ark-web-monitor

python3 -m venv venv
source venv/bin/activate

# 3. Instalar pacotes Python
echo "📦 Instalando pacotes Python..."
pip install flask requests psutil

# 4. Criar estrutura de diretórios
echo "📁 Criando estrutura de diretórios..."
mkdir -p {static,templates,servers,logs,static/css,static/js}

# 5. Baixar arquivos (você pode copiar os arquivos manualmente)
echo "📄 Criando arquivos do aplicativo..."

# Aqui você colocaria o conteúdo dos arquivos criados acima
# Para simplificar, vamos criar um app.py básico

cat > app.py << 'EOT'
#!/usr/bin/env python3
import os
import json
import subprocess
from datetime import datetime
from flask import Flask, render_template, request, jsonify, redirect, url_for

app = Flask(__name__)

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
SERVERS_FILE = os.path.join(BASE_DIR, 'servers', 'servers.json')
LOGS_DIR = os.path.join(BASE_DIR, 'logs')

os.makedirs(LOGS_DIR, exist_ok=True)
os.makedirs(os.path.join(BASE_DIR, 'servers'), exist_ok=True)

DEFAULT_SERVERS = {"servers": []}

def load_servers():
    if os.path.exists(SERVERS_FILE):
        with open(SERVERS_FILE, 'r') as f:
            return json.load(f)
    else:
        with open(SERVERS_FILE, 'w') as f:
            json.dump(DEFAULT_SERVERS, f)
        return DEFAULT_SERVERS

def save_servers(servers_data):
    with open(SERVERS_FILE, 'w') as f:
        json.dump(servers_data, f, indent=2)

def check_server_status(server_config):
    try:
        result = subprocess.run([
            'pgrep', '-f', f'ShooterGameServer'
        ], capture_output=True, text=True)
        
        if result.stdout.strip():
            return {
                'status': 'online',
                'players': 0,
                'last_check': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            }
        else:
            return {
                'status': 'offline',
                'players': 0,
                'last_check': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            }
    except Exception as e:
        return {
            'status': 'error',
            'error': str(e),
            'players': 0,
            'last_check': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        }

@app.route('/')
def index():
    servers_data = load_servers()
    server_status = []
    
    for server in servers_data['servers']:
        status = check_server_status(server)
        server_info = {**server, **status}
        server_status.append(server_info)
    
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <title>ARK Server Monitor</title>
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    </head>
    <body>
        <div class="container mt-4">
            <h1><i class="fas fa-dragon"></i> ARK Server Monitor</h1>
            
            <div class="card mb-4">
                <div class="card-header">
                    <h5>Adicionar Novo Servidor</h5>
                </div>
                <div class="card-body">
                    <form method="POST" action="/add_server">
                        <div class="row">
                            <div class="col-md-3">
                                <input type="text" class="form-control" name="name" placeholder="Nome do Servidor" required>
                            </div>
                            <div class="col-md-2">
                                <select class="form-control" name="map" required>
                                    <option value="">Mapa</option>
                                    <option value="TheIsland">The Island</option>
                                    <option value="TheCenter">The Center</option>
                                    <option value="Ragnarok">Ragnarok</option>
                                    <option value="Aberration">Aberration</option>
                                    <option value="Extinction">Extinction</option>
                                    <option value="Genesis">Genesis</option>
                                    <option value="Genesis2">Genesis 2</option>
                                    <option value="LostIsland">Lost Island</option>
                                    <option value="Fjordur">Fjordur</option>
                                </select>
                            </div>
                            <div class="col-md-2">
                                <input type="text" class="form-control" name="ip" placeholder="IP" value="127.0.0.1" required>
                            </div>
                            <div class="col-md-1">
                                <input type="number" class="form-control" name="port" placeholder="Porta" value="7777" required>
                            </div>
                            <div class="col-md-2">
                                <input type="text" class="form-control" name="path" placeholder="Caminho" required>
                            </div>
                            <div class="col-md-2">
                                <button type="submit" class="btn btn-primary">Adicionar</button>
                            </div>
                        </div>
                    </form>
                </div>
            </div>

            <div class="row">
                {% for server in servers %}
                <div class="col-md-6 col-lg-4 mb-3">
                    <div class="card">
                        <div class="card-header">
                            <div class="d-flex justify-content-between align-items-center">
                                <h6>{{ server.name }}</h6>
                                <span class="badge bg-{% if server.status == 'online' %}success{% else %}danger{% endif %}">
                                    {{ server.status }}
                                </span>
                            </div>
                        </div>
                        <div class="card-body">
                            <p>
                                <strong>Mapa:</strong> {{ server.map }}<br>
                                <strong>IP:</strong> {{ server.ip }}:{{ server.port }}<br>
                                <strong>Jogadores:</strong> {{ server.players }}
                            </p>
                            <div class="btn-group w-100">
                                <a href="/remove_server/{{ server.id }}" class="btn btn-sm btn-danger">Remover</a>
                            </div>
                        </div>
                    </div>
                </div>
                {% endfor %}
            </div>
        </div>
        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
    </body>
    </html>
    '''

@app.route('/add_server', methods=['POST'])
def add_server():
    servers_data = load_servers()
    
    new_server = {
        'id': len(servers_data['servers']) + 1,
        'name': request.form['name'],
        'map': request.form['map'],
        'ip': request.form['ip'],
        'port': request.form['port'],
        'path': request.form['path'],
        'enabled': True
    }
    
    servers_data['servers'].append(new_server)
    save_servers(servers_data)
    
    return redirect(url_for('index'))

@app.route('/remove_server/<int:server_id>')
def remove_server(server_id):
    servers_data = load_servers()
    servers_data['servers'] = [s for s in servers_data['servers'] if s['id'] != server_id]
    save_servers(servers_data)
    return redirect(url_for('index'))

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
EOT

# 6. Criar serviço systemd
echo "🔧 Configurando serviço systemd..."
sudo cat > /etc/systemd/system/ark-web-monitor.service << 'EOT'
[Unit]
Description=ARK Web Monitor
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/ark-web-monitor
ExecStart=/root/ark-web-monitor/venv/bin/python /root/ark-web-monitor/app.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOT

# 7. Configurar firewall
echo "🔥 Configurando firewall..."
sudo ufw allow 5000

# 8. Iniciar serviço
echo "🚀 Iniciando serviço..."
sudo systemctl daemon-reload
sudo systemctl enable ark-web-monitor
sudo systemctl start ark-web-monitor

echo "✅ Instalação concluída!"
echo ""
echo "🌐 Acesse o painel web em:"
echo "   http://$(hostname -I | awk '{print $1}'):5000"
echo ""
echo "🔧 Comandos úteis:"
echo "   sudo systemctl status ark-web-monitor    # Ver status"
echo "   sudo systemctl stop ark-web-monitor      # Parar serviço"
echo "   sudo systemctl start ark-web-monitor     # Iniciar serviço"
echo "   sudo systemctl restart ark-web-monitor   # Reiniciar serviço"
echo ""
echo "📂 Diretório de instalação: /root/ark-web-monitor"
