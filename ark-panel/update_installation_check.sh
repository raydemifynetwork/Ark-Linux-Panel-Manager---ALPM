#!/bin/bash

# Script para atualizar painel com verificação e instalação de servidores
# Execute: nano update_installation_check.sh

echo "=== 🔧 Atualizando Painel com Verificação de Instalação ==="

# 1. Atualizar app.py com verificação de instalação
cat > ~/ark-panel/app.py << 'EOT'
#!/usr/bin/env python3
"""
ARK Server Panel - Com verificação e instalação de servidores
"""
import os
import json
import subprocess
import time
import psutil
import a2s
import threading
from datetime import datetime
from flask import Flask, render_template, request, jsonify, redirect, url_for

app = Flask(__name__)

# Configurações
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
CONFIG_DIR = os.path.join(BASE_DIR, 'config')
SERVERS_FILE = os.path.join(CONFIG_DIR, 'servers.json')
LOGS_DIR = os.path.join(BASE_DIR, 'logs')

# Criar diretórios necessários
os.makedirs(CONFIG_DIR, exist_ok=True)
os.makedirs(LOGS_DIR, exist_ok=True)

# Servidores pré-configurados
ALL_ARK_MAPS = {
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
    """Carregar servidores do arquivo"""
    if os.path.exists(SERVERS_FILE):
        try:
            with open(SERVERS_FILE, 'r') as f:
                return json.load(f)
        except:
            return ALL_ARK_MAPS
    else:
        save_servers(ALL_ARK_MAPS)
        return ALL_ARK_MAPS

def save_servers(servers_data):
    """Salvar servidores no arquivo"""
    with open(SERVERS_FILE, 'w') as f:
        json.dump(servers_data, f, indent=2)

def check_server_installed(server):
    """Verificar se o servidor está instalado"""
    executable_path = os.path.join(server['path'], 'ShooterGameServer')
    return os.path.exists(executable_path)

def get_real_player_count(server):
    """Consultar número real de jogadores"""
    try:
        address = (server['ip'], server['query_port'])
        info = a2s.info(address)
        return {
            'player_count': info.player_count,
            'max_players': info.max_players,
            'map_name': info.map_name,
            'server_name': info.server_name
        }
    except Exception as e:
        return {
            'player_count': 0,
            'max_players': 0,
            'map_name': server['map'],
            'server_name': server['name'],
            'error': str(e)
        }

def check_server_process(server):
    """Verificar se o processo do servidor está rodando"""
    try:
        for proc in psutil.process_iter(['pid', 'name', 'cmdline']):
            try:
                if proc.info['cmdline']:
                    cmdline = ' '.join(proc.info['cmdline'])
                    if f"ShooterGameServer {server['map']}" in cmdline and str(server['game_port']) in cmdline:
                        return True
            except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
                pass
        return False
    except Exception as e:
        return False

def get_server_metrics(server):
    """Obter métricas reais do servidor"""
    try:
        is_installed = check_server_installed(server)
        
        if not is_installed:
            return {
                'status': 'not_installed',
                'players': 0,
                'max_players': 0,
                'cpu_percent': 0,
                'memory_mb': 0,
                'last_check': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            }
        
        is_running = check_server_process(server)
        
        if is_running:
            # Obter métricas do processo
            cpu_percent = 0
            memory_mb = 0
            
            for proc in psutil.process_iter(['pid', 'name', 'cmdline', 'cpu_percent', 'memory_info']):
                try:
                    if proc.info['cmdline']:
                        cmdline = ' '.join(proc.info['cmdline'])
                        if f"ShooterGameServer {server['map']}" in cmdline:
                            cpu_percent = proc.cpu_percent()
                            memory_mb = proc.memory_info().rss / 1024 / 1024
                            break
                except:
                    pass
            
            # Obter jogadores reais
            player_info = get_real_player_count(server)
            
            return {
                'status': 'online',
                'players': player_info['player_count'],
                'max_players': player_info['max_players'],
                'cpu_percent': round(cpu_percent, 2),
                'memory_mb': round(memory_mb, 2),
                'last_check': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            }
        else:
            return {
                'status': 'offline',
                'players': 0,
                'max_players': 0,
                'cpu_percent': 0,
                'memory_mb': 0,
                'last_check': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            }
    except Exception as e:
        return {
            'status': 'error',
            'error': str(e),
            'players': 0,
            'max_players': 0,
            'cpu_percent': 0,
            'memory_mb': 0,
            'last_check': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        }

def create_start_script(server, config_settings=None):
    """Criar script de inicialização para o servidor"""
    script_path = os.path.join(server['path'], 'start_server.sh')
    
    # Configurações padrão
    session_name = config_settings.get('SessionName', server['name']) if config_settings else server['name']
    server_password = config_settings.get('ServerPassword', '') if config_settings else ''
    admin_password = config_settings.get('ServerAdminPassword', 'admin123') if config_settings else 'admin123'
    max_players = config_settings.get('MaxPlayers', 70) if config_settings else 70
    
    start_script = f'''#!/bin/bash
cd {server['path']}
./ShooterGameServer "{server['map']}?listen?SessionName={session_name}?ServerPassword={server_password}?ServerAdminPassword={admin_password}?MaxPlayers={max_players}" \\
  -server \\
  -log \\
  -Port={server['game_port']} \\
  -QueryPort={server['query_port']} \\
  -RCONPort={server['rcon_port']}
'''
    
    with open(script_path, 'w') as f:
        f.write(start_script)
    
    subprocess.run(['chmod', '+x', script_path])

def install_server_steamcmd(server_path, app_id=376030):
    """Instalar servidor usando SteamCMD"""
    try:
        # Criar diretórios
        os.makedirs(server_path, exist_ok=True)
        
        # Verificar se SteamCMD existe
        steamcmd_path = '/home/arkserver/steamcmd/steamcmd.sh'
        if not os.path.exists(steamcmd_path):
            # Instalar SteamCMD
            subprocess.run([
                'sudo', '-u', 'arkserver', 'bash', '-c',
                f'mkdir -p /home/arkserver/steamcmd && cd /home/arkserver/steamcmd && wget http://media.steampowered.com/installer/steamcmd_linux.tar.gz && tar -xvzf steamcmd_linux.tar.gz'
            ], check=True)
        
        # Instalar servidor ARK
        install_cmd = f'sudo -u arkserver {steamcmd_path} +login anonymous +force_install_dir {server_path} +app_update {app_id} validate +quit'
        result = subprocess.run(install_cmd.split(), capture_output=True, text=True)
        
        return result.returncode == 0
    except Exception as e:
        print(f"Erro na instalação: {e}")
        return False

# Rotas web
@app.route('/')
def index():
    servers_data = load_servers()
    server_status = []
    
    for server in servers_data['servers']:
        metrics = get_server_metrics(server)
        server_info = {**server, **metrics}
        server_status.append(server_info)
    
    total_servers = len(server_status)
    installed_servers = len([s for s in server_status if s['status'] != 'not_installed'])
    online_servers = len([s for s in server_status if s['status'] == 'online'])
    total_players = sum([s['players'] for s in server_status if s['status'] == 'online'])
    
    stats = {
        'total_servers': total_servers,
        'installed_servers': installed_servers,
        'online_servers': online_servers,
        'offline_servers': installed_servers - online_servers,
        'total_players': total_players
    }
    
    return render_template('index.html', servers=server_status, stats=stats, server_ip=request.host.split(':')[0])

@app.route('/server/<int:server_id>')
def server_detail(server_id):
    servers_data = load_servers()
    server = next((s for s in servers_data['servers'] if s['id'] == server_id), None)
    
    if not server:
        return "Servidor não encontrado", 404
    
    metrics = get_server_metrics(server)
    server_info = {**server, **metrics}
    
    return render_template('server_detail.html', server=server_info)

@app.route('/server/<int:server_id>/config')
def server_config(server_id):
    servers_data = load_servers()
    server = next((s for s in servers_data['servers'] if s['id'] == server_id), None)
    
    if not server:
        return "Servidor não encontrado", 404
    
    # Carregar configurações existentes ou usar padrão
    config_file = os.path.join(server['path'], 'ShooterGame/Saved/Config/LinuxServer/GameUserSettings.ini')
    config_settings = {}
    
    if os.path.exists(config_file):
        # Aqui você pode implementar leitura real do arquivo INI
        config_settings = {
            'SessionName': server['name'],
            'ServerPassword': '',
            'ServerAdminPassword': 'admin123',
            'MaxPlayers': 70,
            'DifficultyOffset': 1.0,
            'DayCycleSpeedScale': 1.0,
            'NightTimeSpeedScale': 1.0,
            'DinoDamageMultiplier': 1.0,
            'PlayerDamageMultiplier': 1.0,
            'StructureDamageMultiplier': 1.0,
            'PlayerResistanceMultiplier': 1.0,
            'DinoResistanceMultiplier': 1.0
        }
    
    return render_template('server_config.html', server=server, config=config_settings)

@app.route('/api/servers')
def api_servers():
    servers_data = load_servers()
    status_list = []
    
    for server in servers_data['servers']:
        metrics = get_server_metrics(server)
        status_list.append({**server, **metrics})
    
    return jsonify(status_list)

@app.route('/api/server/<int:server_id>/install', methods=['POST'])
def install_server(server_id):
    servers_data = load_servers()
    server = next((s for s in servers_data['servers'] if s['id'] == server_id), None)
    
    if not server:
        return jsonify({'error': 'Servidor não encontrado'}), 404
    
    try:
        # Criar diretórios
        os.makedirs(server['path'], exist_ok=True)
        
        # Instalar servidor
        success = install_server_steamcmd(server['path'])
        
        if success:
            return jsonify({'status': 'success', 'message': 'Servidor instalado com sucesso!'})
        else:
            return jsonify({'status': 'error', 'message': 'Erro na instalação do servidor'}), 500
            
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/api/server/<int:server_id>/start', methods=['POST'])
def start_server(server_id):
    servers_data = load_servers()
    server = next((s for s in servers_data['servers'] if s['id'] == server_id), None)
    
    if not server:
        return jsonify({'error': 'Servidor não encontrado'}), 404
    
    # Verificar se está instalado
    if not check_server_installed(server):
        return jsonify({'error': 'Servidor não instalado! Instale primeiro.'}), 400
    
    try:
        # Criar diretórios necessários
        os.makedirs(server['path'], exist_ok=True)
        os.makedirs(os.path.join(server['path'], 'ShooterGame/Saved/Config/LinuxServer'), exist_ok=True)
        
        # Criar script de inicialização
        create_start_script(server)
        
        # Iniciar servidor
        script_path = os.path.join(server['path'], 'start_server.sh')
        subprocess.Popen(['nohup', 'bash', script_path], 
                        stdout=open(f"{LOGS_DIR}/server_{server_id}.log", 'w'),
                        stderr=subprocess.STDOUT,
                        start_new_session=True)
        
        return jsonify({'status': 'success', 'message': 'Servidor iniciado'})
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/api/server/<int:server_id>/stop', methods=['POST'])
def stop_server(server_id):
    try:
        subprocess.run(['pkill', '-f', f"ShooterGameServer.*Port={7777 + (server_id-1)*10}"])
        return jsonify({'status': 'success', 'message': 'Servidor parado'})
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/api/server/<int:server_id>/config', methods=['POST'])
def update_server_config(server_id):
    servers_data = load_servers()
    server = next((s for s in servers_data['servers'] if s['id'] == server_id), None)
    
    if not server:
        return jsonify({'error': 'Servidor não encontrado'}), 404
    
    try:
        # Obter dados do formulário
        config_data = request.get_json()
        
        # Salvar configurações em arquivo
        config_dir = os.path.join(server['path'], 'ShooterGame/Saved/Config/LinuxServer')
        os.makedirs(config_dir, exist_ok=True)
        
        # Criar GameUserSettings.ini
        config_file = os.path.join(config_dir, 'GameUserSettings.ini')
        
        config_content = f"""[ServerSettings]
SessionName={config_data.get('SessionName', server['name'])}
ServerPassword={config_data.get('ServerPassword', '')}
ServerAdminPassword={config_data.get('ServerAdminPassword', 'admin123')}
MaxPlayers={config_data.get('MaxPlayers', 70)}
DifficultyOffset={config_data.get('DifficultyOffset', 1.0)}
DayCycleSpeedScale={config_data.get('DayCycleSpeedScale', 1.0)}
NightTimeSpeedScale={config_data.get('NightTimeSpeedScale', 1.0)}
DinoDamageMultiplier={config_data.get('DinoDamageMultiplier', 1.0)}
PlayerDamageMultiplier={config_data.get('PlayerDamageMultiplier', 1.0)}
StructureDamageMultiplier={config_data.get('StructureDamageMultiplier', 1.0)}
PlayerResistanceMultiplier={config_data.get('PlayerResistanceMultiplier', 1.0)}
DinoResistanceMultiplier={config_data.get('DinoResistanceMultiplier', 1.0)}

[/Script/ShooterGame.ShooterGameMode]
bAllowUnlimitedRespecs=true
"""
        
        with open(config_file, 'w') as f:
            f.write(config_content)
        
        return jsonify({'status': 'success', 'message': 'Configurações salvas com sucesso!'})
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
EOT

# 2. Atualizar template principal com verificação de instalação
cat > ~/ark-panel/templates/index.html << 'EOT'
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
        .server-not-installed { border-left: 4px solid #6c757d; }
        .server-error { border-left: 4px solid #ffc107; }
        .installing { opacity: 0.7; }
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
            <div class="col-md-2">
                <div class="stat-card bg-primary text-white p-3 text-center">
                    <h3>{{ stats.total_servers }}</h3>
                    <p class="mb-0">Total de Servidores</p>
                </div>
            </div>
            <div class="col-md-2">
                <div class="stat-card bg-info text-white p-3 text-center">
                    <h3>{{ stats.installed_servers }}</h3>
                    <p class="mb-0">Instalados</p>
                </div>
            </div>
            <div class="col-md-2">
                <div class="stat-card bg-success text-white p-3 text-center">
                    <h3>{{ stats.online_servers }}</h3>
                    <p class="mb-0">Online</p>
                </div>
            </div>
            <div class="col-md-2">
                <div class="stat-card bg-danger text-white p-3 text-center">
                    <h3>{{ stats.offline_servers }}</h3>
                    <p class="mb-0">Offline</p>
                </div>
            </div>
            <div class="col-md-2">
                <div class="stat-card bg-warning text-dark p-3 text-center">
                    <h3>{{ stats.total_players }}</h3>
                    <p class="mb-0">Jogadores</p>
                </div>
            </div>
            <div class="col-md-2">
                <div class="stat-card bg-secondary text-white p-3 text-center">
                    <h3>{{ stats.total_servers - stats.installed_servers }}</h3>
                    <p class="mb-0">Não Instalados</p>
                </div>
            </div>
        </div>

        <!-- Lista de Servidores -->
        <div class="row">
            {% for server in servers %}
            <div class="col-xl-4 col-lg-6 col-md-6 mb-4">
                <div class="card h-100 {% if server.status == 'online' %}server-online{% elif server.status == 'offline' %}server-offline{% elif server.status == 'not_installed' %}server-not-installed{% else %}server-error{% endif %}" id="server-card-{{ server.id }}">
                    <div class="card-header">
                        <div class="d-flex justify-content-between align-items-center">
                            <h5 class="mb-0">
                                <i class="fas fa-server"></i> {{ server.name }}
                            </h5>
                            <span class="badge {% if server.status == 'online' %}bg-success{% elif server.status == 'offline' %}bg-danger{% elif server.status == 'not_installed' %}bg-secondary{% else %}bg-warning{% endif %}">
                                {% if server.status == 'online' %}Online
                                {% elif server.status == 'offline' %}Offline
                                {% elif server.status == 'not_installed' %}Não Instalado
                                {% else %}Erro{% endif %}
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
                        
                        {% if server.status == 'not_installed' %}
                            <div class="text-center">
                                <p class="text-muted">
                                    <i class="fas fa-exclamation-circle"></i> Servidor não instalado
                                </p>
                                <button class="btn btn-primary" onclick="installServer({{ server.id }})">
                                    <i class="fas fa-download"></i> Instalar Servidor
                                </button>
                            </div>
                        {% else %}
                            <div class="server-info">
                                <p class="mb-1">
                                    <i class="fas fa-network-wired"></i> 
                                    <strong>IP:</strong> {{ request.host.split(':')[0] }}:{{ server.game_port }}
                                </p>
                                {% if server.status == 'online' %}
                                    <p class="mb-1">
                                        <i class="fas fa-users"></i> 
                                        <strong>Jogadores:</strong> {{ server.players }} / {{ server.max_players }}
                                    </p>
                                {% endif %}
                                <p class="mb-1">
                                    <i class="fas fa-folder"></i> 
                                    <strong>Caminho:</strong> {{ server.path }}
                                </p>
                                {% if server.status != 'not_installed' %}
                                    <p class="mb-1">
                                        <i class="fas fa-microchip"></i> 
                                        <strong>CPU:</strong> {{ server.cpu_percent }}%
                                    </p>
                                    <p class="mb-0">
                                        <i class="fas fa-memory"></i> 
                                        <strong>Memória:</strong> {{ server.memory_mb|round(0) }} MB
                                    </p>
                                {% endif %}
                            </div>
                        {% endif %}
                    </div>
                    <div class="card-footer">
                        {% if server.status != 'not_installed' %}
                            <div class="d-grid gap-2">
                                <a href="/server/{{ server.id }}" class="btn btn-outline-primary btn-sm">
                                    <i class="fas fa-cog"></i> Gerenciar Servidor
                                </a>
                            </div>
                        {% endif %}
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
                        <p><i class="fas fa-network-wired"></i> <strong>IP do Servidor:</strong> {{ request.host.split(':')[0] }}</p>
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
        function installServer(serverId) {
            // Desabilitar botão e mostrar loading
            const button = event.target;
            const originalText = button.innerHTML;
            button.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Instalando...';
            button.disabled = true;
            
            // Adicionar classe de instalação ao card
            document.getElementById(`server-card-${serverId}`).classList.add('installing');
            
            fetch(`/api/server/${serverId}/install`, {
                method: 'POST'
            })
            .then(response => response.json())
            .then(data => {
                if (data.status === 'success') {
                    alert('Servidor instalado com sucesso!');
                    location.reload();
                } else {
                    alert('Erro na instalação: ' + data.message);
                    button.innerHTML = originalText;
                    button.disabled = false;
                    document.getElementById(`server-card-${serverId}`).classList.remove('installing');
                }
            })
            .catch(error => {
                alert('Erro na instalação: ' + error);
                button.innerHTML = originalText;
                button.disabled = false;
                document.getElementById(`server-card-${serverId}`).classList.remove('installing');
            });
        }

        // Auto-refresh a cada 30 segundos
        setTimeout(function(){
            location.reload();
        }, 30000);
    </script>
</body>
</html>
EOT

# 3. Atualizar template de detalhes do servidor
cat > ~/ark-panel/templates/server_detail.html << 'EOT'
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
        .metric-card { background-color: #333; border-radius: 10px; padding: 15px; margin-bottom: 15px; }
    </style>
</head>
<body>
    <nav class="navbar navbar-expand-lg navbar-dark">
        <div class="container-fluid">
            <a class="navbar-brand" href="/">
                <i class="fas fa-dragon"></i> ARK Server Panel
            </a>
            <div class="navbar-nav">
                <a class="nav-link" href="/">← Dashboard</a>
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
                            <span class="badge {% if server.status == 'online' %}bg-success{% elif server.status == 'offline' %}bg-danger{% elif server.status == 'not_installed' %}bg-secondary{% else %}bg-warning{% endif %}">
                                {% if server.status == 'online' %}Online
                                {% elif server.status == 'offline' %}Offline
                                {% elif server.status == 'not_installed' %}Não Instalado
                                {% else %}Erro{% endif %}
                            </span>
                        </div>
                    </div>
                    <div class="card-body">
                        {% if server.status == 'not_installed' %}
                            <div class="text-center p-5">
                                <h3><i class="fas fa-exclamation-circle text-warning"></i> Servidor Não Instalado</h3>
                                <p class="lead">Este servidor ainda não foi instalado no sistema.</p>
                                <button class="btn btn-primary btn-lg" onclick="installServer({{ server.id }})">
                                    <i class="fas fa-download"></i> Instalar Servidor ARK - {{ server.map }}
                                </button>
                                <p class="mt-3 text-muted">
                                    <small>A instalação pode levar alguns minutos. O servidor (~15GB) será baixado.</small>
                                </p>
                            </div>
                        {% else %}
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
                                    <h5><i class="fas fa-chart-bar"></i> Métricas em Tempo Real</h5>
                                    {% if server.status == 'online' %}
                                        <div class="metric-card">
                                            <h6><i class="fas fa-users"></i> Jogadores Online</h6>
                                            <h3 class="text-center">{{ server.players }} / {{ server.max_players }}</h3>
                                        </div>
                                        <div class="metric-card">
                                            <h6><i class="fas fa-microchip"></i> Uso de CPU</h6>
                                            <h3 class="text-center">{{ server.cpu_percent }}%</h3>
                                        </div>
                                        <div class="metric-card">
                                            <h6><i class="fas fa-memory"></i> Uso de Memória</h6>
                                            <h3 class="text-center">{{ server.memory_mb|round(0) }} MB</h3>
                                        </div>
                                    {% else %}
                                        <div class="text-center p-4">
                                            <p class="text-muted">
                                                <i class="fas fa-info-circle"></i> Métricas disponíveis quando o servidor estiver online
                                            </p>
                                        </div>
                                    {% endif %}
                                </div>
                            </div>
                            
                            <div class="row mt-4">
                                <div class="col-12">
                                    <h5><i class="fas fa-cogs"></i> Ações do Servidor</h5>
                                    <div class="d-grid gap-2 d-md-flex justify-content-center">
                                        <a href="/server/{{ server.id }}/config" class="btn btn-primary btn-lg mx-2">
                                            <i class="fas fa-cog"></i> Configurações
                                        </a>
                                        {% if server.status == 'online' %}
                                            <button class="btn btn-danger btn-lg mx-2" onclick="stopServer({{ server.id }})">
                                                <i class="fas fa-stop"></i> Parar Servidor
                                            </button>
                                            <button class="btn btn-warning btn-lg mx-2" onclick="restartServer({{ server.id }})">
                                                <i class="fas fa-sync-alt"></i> Reiniciar Servidor
                                            </button>
                                        {% else %}
                                            <button class="btn btn-success btn-lg mx-2" onclick="startServer({{ server.id }})">
                                                <i class="fas fa-play"></i> Iniciar Servidor
                                            </button>
                                        {% endif %}
                                        <button class="btn btn-info btn-lg mx-2" onclick="backupServer({{ server.id }})">
                                            <i class="fas fa-download"></i> Backup
                                        </button>
                                    </div>
                                </div>
                            </div>
                        {% endif %}
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        function installServer(serverId) {
            if (confirm('Tem certeza que deseja instalar o servidor ARK - ' + serverId + '?\n\nA instalação pode levar alguns minutos e requer ~15GB de espaço em disco.')) {
                fetch(`/api/server/${serverId}/install`, {
                    method: 'POST'
                })
                .then(response => response.json())
                .then(data => {
                    if (data.status === 'success') {
                        alert('Servidor instalado com sucesso! Aguarde alguns segundos e recarregue a página.');
                        location.reload();
                    } else {
                        alert('Erro na instalação: ' + data.message);
                    }
                })
                .catch(error => {
                    alert('Erro na instalação: ' + error);
                });
            }
        }

        function startServer(serverId) {
            fetch(`/api/server/${serverId}/start`, {
                method: 'POST'
            })
            .then(response => response.json())
            .then(data => {
                if (data.status === 'success') {
                    alert(data.message);
                    location.reload();
                } else {
                    alert('Erro: ' + data.message);
                }
            })
            .catch(error => {
                alert('Erro ao iniciar servidor: ' + error);
            });
        }

        function stopServer(serverId) {
            if (confirm('Tem certeza que deseja parar este servidor?')) {
                fetch(`/api/server/${serverId}/stop`, {
                    method: 'POST'
                })
                .then(response => response.json())
                .then(data => {
                    alert(data.message);
                    location.reload();
                })
                .catch(error => {
                    alert('Erro ao parar servidor: ' + error);
                });
            }
        }

        function restartServer(serverId) {
            if (confirm('Tem certeza que deseja reiniciar este servidor?')) {
                stopServer(serverId);
                setTimeout(() => startServer(serverId), 3000);
            }
        }

        function backupServer(serverId) {
            alert('Função de backup será implementada em breve!');
        }

        // Auto-refresh a cada 15 segundos
        setTimeout(function(){
            location.reload();
        }, 15000);
    </script>
</body>
</html>
EOT

# 4. Reiniciar serviço
echo "🔄 Reiniciando serviço..."
sudo systemctl restart ark-panel

echo "✅ Painel atualizado com verificação de instalação!"
echo "Acesse: http://$(hostname -I | awk '{print $1}'):5000"
