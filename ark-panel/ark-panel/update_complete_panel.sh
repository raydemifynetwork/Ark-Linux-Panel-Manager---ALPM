#!/bin/bash

# Script para atualizar painel com consulta real de jogadores + configurações completas
# Execute: nano update_complete_panel.sh

echo "=== 🔧 Atualizando Painel com Funcionalidades Completas ==="

# 1. Atualizar app.py com consulta real de jogadores
cat > ~/ark-panel/app.py << 'EOT'
#!/usr/bin/env python3
"""
ARK Server Panel - Painel Web COMPLETO com Consulta Real de Jogadores
"""
import os
import json
import subprocess
import time
import psutil
import a2s
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

# Servidores pré-configurados (TODOS os mapas)
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

def get_real_player_count(server):
    """Consultar número real de jogadores"""
    try:
        address = (server['ip'], server['query_port'])
        info = a2s.info(address)
        players = a2s.players(address)
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

@app.route('/api/server/<int:server_id>/start', methods=['POST'])
def start_server(server_id):
    servers_data = load_servers()
    server = next((s for s in servers_data['servers'] if s['id'] == server_id), None)
    
    if not server:
        return jsonify({'error': 'Servidor não encontrado'}), 404
    
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

# 2. Criar template de configuração
cat > ~/ark-panel/templates/server_config.html << 'EOT'
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ server.name }} - Configurações - ARK Server Panel</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <style>
        body { background-color: #1a1a1a; color: #fff; }
        .navbar { background: linear-gradient(90deg, #8B0000, #B22222); }
        .card { background-color: #2d2d2d; border: 1px solid #444; }
        .card-header { background-color: #3a3a3a; border-bottom: 1px solid #444; }
        .form-control, .form-select { background-color: #333; border: 1px solid #555; color: #fff; }
        .form-control:focus, .form-select:focus { background-color: #333; border-color: #B22222; color: #fff; }
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
                <a class="nav-link" href="/server/{{ server.id }}">← Servidor</a>
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
                                <i class="fas fa-cog"></i> Configurações - {{ server.name }}
                            </h3>
                        </div>
                    </div>
                    <div class="card-body">
                        <form id="configForm">
                            <div class="row">
                                <div class="col-md-6">
                                    <h5><i class="fas fa-server"></i> Configurações Básicas</h5>
                                    <div class="mb-3">
                                        <label class="form-label">Nome do Servidor</label>
                                        <input type="text" class="form-control" name="SessionName" value="{{ config.SessionName }}">
                                    </div>
                                    <div class="mb-3">
                                        <label class="form-label">Senha do Servidor (opcional)</label>
                                        <input type="password" class="form-control" name="ServerPassword" value="{{ config.ServerPassword }}">
                                    </div>
                                    <div class="mb-3">
                                        <label class="form-label">Senha de Administrador</label>
                                        <input type="password" class="form-control" name="ServerAdminPassword" value="{{ config.ServerAdminPassword }}">
                                    </div>
                                    <div class="mb-3">
                                        <label class="form-label">Máximo de Jogadores</label>
                                        <input type="number" class="form-control" name="MaxPlayers" value="{{ config.MaxPlayers }}" min="1" max="200">
                                    </div>
                                </div>
                                
                                <div class="col-md-6">
                                    <h5><i class="fas fa-sliders-h"></i> Configurações Avançadas</h5>
                                    <div class="mb-3">
                                        <label class="form-label">Dificuldade (0-5)</label>
                                        <input type="number" class="form-control" name="DifficultyOffset" value="{{ config.DifficultyOffset }}" step="0.1" min="0" max="5">
                                    </div>
                                    <div class="mb-3">
                                        <label class="form-label">Velocidade do Ciclo Diurno</label>
                                        <input type="number" class="form-control" name="DayCycleSpeedScale" value="{{ config.DayCycleSpeedScale }}" step="0.1" min="0.1" max="10">
                                    </div>
                                    <div class="mb-3">
                                        <label class="form-label">Velocidade da Noite</label>
                                        <input type="number" class="form-control" name="NightTimeSpeedScale" value="{{ config.NightTimeSpeedScale }}" step="0.1" min="0.1" max="10">
                                    </div>
                                    <div class="mb-3">
                                        <label class="form-label">Multiplicador de Dano (Dinos)</label>
                                        <input type="number" class="form-control" name="DinoDamageMultiplier" value="{{ config.DinoDamageMultiplier }}" step="0.1" min="0.1" max="10">
                                    </div>
                                </div>
                            </div>
                            
                            <div class="row">
                                <div class="col-md-6">
                                    <div class="mb-3">
                                        <label class="form-label">Multiplicador de Dano (Jogadores)</label>
                                        <input type="number" class="form-control" name="PlayerDamageMultiplier" value="{{ config.PlayerDamageMultiplier }}" step="0.1" min="0.1" max="10">
                                    </div>
                                </div>
                                <div class="col-md-6">
                                    <div class="mb-3">
                                        <label class="form-label">Multiplicador de Dano (Estruturas)</label>
                                        <input type="number" class="form-control" name="StructureDamageMultiplier" value="{{ config.StructureDamageMultiplier }}" step="0.1" min="0.1" max="10">
                                    </div>
                                </div>
                            </div>
                            
                            <div class="d-grid gap-2">
                                <button type="submit" class="btn btn-success btn-lg">
                                    <i class="fas fa-save"></i> Salvar Configurações
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        document.getElementById('configForm').addEventListener('submit', function(e) {
            e.preventDefault();
            
            const formData = new FormData(this);
            const configData = {};
            
            for (let [key, value] of formData.entries()) {
                configData[key] = value;
            }
            
            fetch(`/api/server/{{ server.id }}/config`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(configData)
            })
            .then(response => response.json())
            .then(data => {
                if (data.status === 'success') {
                    alert('Configurações salvas com sucesso!');
                } else {
                    alert('Erro ao salvar configurações: ' + data.message);
                }
            })
            .catch(error => {
                alert('Erro: ' + error);
            });
        });
    </script>
</body>
</html>
EOT

# 3. Atualizar template principal com link para configurações
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
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        function startServer(serverId) {
            fetch(`/api/server/${serverId}/start`, {
                method: 'POST'
            })
            .then(response => response.json())
            .then(data => {
                alert(data.message);
                location.reload();
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

echo "✅ Painel atualizado com funcionalidades completas!"
echo "Acesse: http://$(hostname -I | awk '{print $1}'):5000"
