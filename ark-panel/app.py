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
