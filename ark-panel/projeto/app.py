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
import shutil
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
    """Verificar se o servidor está instalado (versão Linux)"""
    # Verificar arquivo de marcação primeiro
    marker_file = os.path.join(server['path'], '.ark_installed')
    if os.path.exists(marker_file):
        return True
    
    # Verificação secundária: executável Linux existe
    executable_path = os.path.join(server['path'], 'ShooterGameServer')
    if os.path.exists(executable_path):
        # Criar arquivo de marcação se executável existe
        try:
            with open(marker_file, 'w') as f:
                f.write(f"Installed at: {datetime.now()}\n")
            return True
        except:
            pass
    
    return False
def get_server_version(server):
    """Obter versão do servidor instalado"""
    version_file = os.path.join(server['path'], '.ark_version')
    if os.path.exists(version_file):
        try:
            with open(version_file, 'r') as f:
                return f.read().strip()
        except:
            return "Desconhecida"
    return "Desconhecida"
def get_installation_date(server):
    """Obter data de instalação"""
    marker_file = os.path.join(server['path'], '.ark_installed')
    if os.path.exists(marker_file):
        try:
            return time.ctime(os.path.getctime(marker_file))
        except:
            return "Desconhecida"
    return "Desconhecida"
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
                'last_check': datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
                'version': 'N/A',
                'install_date': 'N/A'
            }
        
        # Se instalado, obter informações adicionais
        version = get_server_version(server)
        install_date = get_installation_date(server)
        
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
                'last_check': datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
                'version': version,
                'install_date': install_date
            }
        else:
            return {
                'status': 'offline',
                'players': 0,
                'max_players': 0,
                'cpu_percent': 0,
                'memory_mb': 0,
                'last_check': datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
                'version': version,
                'install_date': install_date
            }
    except Exception as e:
        return {
            'status': 'error',
            'error': str(e),
            'players': 0,
            'max_players': 0,
            'cpu_percent': 0,
            'memory_mb': 0,
            'last_check': datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
            'version': 'N/A',
            'install_date': 'N/A'
        }
def create_start_script(server, config_settings=None):
    """Criar script de inicialização para o servidor com caminhos corretos"""
    script_path = os.path.join(server['path'], 'start_server.sh')
    # Configurações padrão
    session_name = config_settings.get('SessionName', server['name']) if config_settings else server['name']
    server_password = config_settings.get('ServerPassword', '') if config_settings else ''
    admin_password = config_settings.get('ServerAdminPassword', 'admin123') if config_settings else 'admin123'
    max_players = config_settings.get('MaxPlayers', 70) if config_settings else 70
    
    # Caminho absoluto para o executável
    executable_path = os.path.join(server['path'], 'ShooterGameServer')
    
    start_script = f'''#!/bin/bash
# Script de inicialização do servidor ARK
# Gerado automaticamente pelo ARK Server Panel

# Garantir que estamos no diretório correto
cd "{server['path']}" || {{
    echo "ERRO: Não foi possível acessar o diretório {server['path']}"
    exit 1
}}

# Verificar se o executável existe
if [ ! -f "{executable_path}" ]; then
    echo "ERRO: Executável não encontrado em {executable_path}"
    echo "Verifique se o servidor foi instalado corretamente para Linux."
    exit 1
fi

# Tornar o executável executável (por garantia)
chmod +x "{executable_path}"

# Iniciar o servidor
echo "Iniciando servidor ARK: {server['name']}"
echo "Mapa: {server['map']}"
echo "Porta do jogo: {server['game_port']}"
echo "Porta de consulta: {server['query_port']}"
echo "Porta RCON: {server['rcon_port']}"

"{executable_path}" "{server['map']}?listen?SessionName={session_name}?ServerPassword={server_password}?ServerAdminPassword={admin_password}?MaxPlayers={max_players}" \\
  -server \\
  -log \\
  -Port={server['game_port']} \\
  -QueryPort={server['query_port']} \\
  -RCONPort={server['rcon_port']}
'''
    with open(script_path, 'w') as f:
        f.write(start_script)
    # Usar caminho absoluto para chmod
    subprocess.run(['/bin/chmod', '+x', script_path])
def log_installation(message, server_id=None):
    """Log de instalação geral ou específica de servidor"""
    if server_id:
        log_file = os.path.join(LOGS_DIR, f'install_server_{server_id}.log')
    else:
        log_file = os.path.join(LOGS_DIR, 'installation.log')
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    with open(log_file, 'a') as f:
        f.write(f"[{timestamp}] {message}\n")
    print(f"[{timestamp}] {message}")
def install_server_steamcmd(server_path, server_id, app_id=376030, force_update=False, branch="preaquatica"):
    """Instalar servidor usando SteamCMD com plataforma correta e seleção de branch"""
    try:
        log_installation(f"Iniciando instalação para: {server_path} (branch: {branch})", server_id)
        
        # Se for force update, remover diretório existente
        if force_update and os.path.exists(server_path):
            log_installation(f"Removendo diretório existente para force update...", server_id)
            shutil.rmtree(server_path)
            time.sleep(2)  # Pequena pausa para garantir remoção
        
        # Criar diretórios
        os.makedirs(server_path, exist_ok=True)
        log_installation(f"Diretórios criados: {server_path}", server_id)
        
        # Verificar se SteamCMD existe
        steamcmd_path = '/home/arkserver/steamcmd/steamcmd.sh'
        if not os.path.exists(steamcmd_path):
            log_installation("SteamCMD não encontrado, instalando...", server_id)
            # Instalar SteamCMD - Usando caminho absoluto para sudo e bash
            cmd = [
                '/usr/bin/sudo', '-u', 'arkserver', '/bin/bash', '-c',
                f'mkdir -p /home/arkserver/steamcmd && cd /home/arkserver/steamcmd && /usr/bin/wget http://media.steampowered.com/installer/steamcmd_linux.tar.gz && /bin/tar -xvzf steamcmd_linux.tar.gz'
            ]
            log_installation(f"Executando comando de instalação do SteamCMD: {' '.join(cmd)}", server_id)
            result = subprocess.run(cmd, capture_output=True, text=True, cwd='/tmp')
            if result.returncode != 0:
                log_installation(f"ERRO na instalação do SteamCMD: {result.stderr}", server_id)
                return False
            log_installation("SteamCMD instalado com sucesso", server_id)
        
        # Instalar servidor ARK - FORÇANDO PLATAFORMA LINUX E USANDO BRANCH
        log_installation(f"Instalando servidor ARK (app_id: {app_id}) para Linux (branch: {branch})...", server_id)
        
        # Construir comando com branch
        if branch and branch != "public":
            install_cmd = f'/usr/bin/sudo -u arkserver {steamcmd_path} +@sSteamCmdForcePlatformType linux +force_install_dir {server_path} +login anonymous +app_update {app_id} -beta {branch} validate +quit'
        else:
            # Branch public (padrão)
            install_cmd = f'/usr/bin/sudo -u arkserver {steamcmd_path} +@sSteamCmdForcePlatformType linux +force_install_dir {server_path} +login anonymous +app_update {app_id} validate +quit'
        
        log_installation(f"Comando: {install_cmd}", server_id)
        
        # Criar arquivo de log específico para esta instalação
        install_log_file = os.path.join(LOGS_DIR, f'install_server_{server_id}.log')
        
        # Executar o comando e capturar output em tempo real
        with open(install_log_file, 'a') as log_f:
            process = subprocess.Popen(
                install_cmd,
                shell=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                cwd='/tmp',
                bufsize=1,
                universal_newlines=True
            )
            
            # Ler a saída em tempo real e escrever no log
            for line in process.stdout:
                log_f.write(line)
                log_f.flush() # Garantir que seja escrito imediatamente
                # Também escrever no log geral para rastreamento
                with open(os.path.join(LOGS_DIR, 'installation.log'), 'a') as general_log:
                    general_log.write(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] [SERVER_{server_id}] {line}")
            
            # Esperar o processo terminar
            process.wait()
            
            if process.returncode == 0:
                # Verificar se a instalação foi bem sucedida (pasta Linux existe)
                linux_bin_path = os.path.join(server_path, 'ShooterGame', 'Binaries', 'Linux')
                if os.path.exists(linux_bin_path):
                    executable_path = os.path.join(linux_bin_path, 'ShooterGameServer')
                    if os.path.exists(executable_path):
                        # Mover executável para o diretório principal para compatibilidade
                        destination_path = os.path.join(server_path, 'ShooterGameServer')
                        shutil.move(executable_path, destination_path)
                        log_installation("Executável movido para diretório principal", server_id)
                    
                    # Criar arquivo de marcação de instalação bem sucedida
                    marker_file = os.path.join(server_path, '.ark_installed')
                    version_file = os.path.join(server_path, '.ark_version')
                    try:
                        with open(marker_file, 'w') as f:
                            f.write(f"Installed successfully at: {datetime.now()}\nLinux version (branch: {branch})\n")
                        with open(version_file, 'w') as f:
                            f.write(f"Linux version installed at: {datetime.now()}\nBranch: {branch}\n")
                        log_installation("Arquivos de marcação criados com sucesso!", server_id)
                    except Exception as e:
                        log_installation(f"ERRO ao criar arquivos de marcação: {e}", server_id)
                    
                    log_installation("Servidor instalado com sucesso para Linux!", server_id)
                    return True
                else:
                    log_installation("ERRO: Pasta Linux não encontrada após instalação", server_id)
                    log_installation("Provavelmente o SteamCMD baixou a versão Windows ou houve erro no download", server_id)
                    return False
            else:
                log_installation(f"ERRO na instalação do servidor (código {process.returncode})", server_id)
                return False
            
    except Exception as e:
        log_installation(f"EXCEÇÃO na instalação: {str(e)}", server_id)
        import traceback
        log_installation(f"Traceback: {traceback.format_exc()}", server_id)
        return False
def update_server_steamcmd(server_path, server_id, app_id=376030, branch="preaquatica"):
    """Atualizar servidor usando SteamCMD"""
    try:
        log_installation(f"Iniciando atualização para: {server_path} (branch: {branch})", server_id)
        
        # Verificar se SteamCMD existe
        steamcmd_path = '/home/arkserver/steamcmd/steamcmd.sh'
        if not os.path.exists(steamcmd_path):
            log_installation("SteamCMD não encontrado!", server_id)
            return False
        
        # Atualizar servidor ARK - FORÇANDO PLATAFORMA LINUX E USANDO BRANCH
        log_installation(f"Atualizando servidor ARK (app_id: {app_id}) para Linux (branch: {branch})...", server_id)
        
        # Construir comando com branch
        if branch and branch != "public":
            update_cmd = f'/usr/bin/sudo -u arkserver {steamcmd_path} +@sSteamCmdForcePlatformType linux +force_install_dir {server_path} +login anonymous +app_update {app_id} -beta {branch} validate +quit'
        else:
            # Branch public (padrão)
            update_cmd = f'/usr/bin/sudo -u arkserver {steamcmd_path} +@sSteamCmdForcePlatformType linux +force_install_dir {server_path} +login anonymous +app_update {app_id} validate +quit'
        
        log_installation(f"Comando: {update_cmd}", server_id)
        
        # Criar arquivo de log específico para esta atualização
        update_log_file = os.path.join(LOGS_DIR, f'update_server_{server_id}.log')
        
        # Executar o comando e capturar output em tempo real
        with open(update_log_file, 'a') as log_f:
            process = subprocess.Popen(
                update_cmd,
                shell=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                cwd='/tmp',
                bufsize=1,
                universal_newlines=True
            )
            
            # Ler a saída em tempo real e escrever no log
            for line in process.stdout:
                log_f.write(line)
                log_f.flush()
                # Também escrever no log geral
                with open(os.path.join(LOGS_DIR, 'installation.log'), 'a') as general_log:
                    general_log.write(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] [UPDATE_SERVER_{server_id}] {line}")
            
            # Esperar o processo terminar
            process.wait()
            
            if process.returncode == 0:
                log_installation("Servidor atualizado com sucesso!", server_id)
                return True
            else:
                log_installation(f"ERRO na atualização do servidor (código {process.returncode})", server_id)
                return False
                
    except Exception as e:
        log_installation(f"EXCEÇÃO na atualização: {str(e)}", server_id)
        import traceback
        log_installation(f"Traceback: {traceback.format_exc()}", server_id)
        return False
def uninstall_server(server_path, server_id):
    """Desinstalar servidor removendo diretório"""
    try:
        log_installation(f"Iniciando desinstalação do servidor em: {server_path}", server_id)
        
        # Parar processo se estiver rodando
        try:
            subprocess.run(['/usr/bin/pkill', '-f', f"ShooterGameServer.*{server_path}"], capture_output=True)
            time.sleep(2)  # Esperar processo terminar
        except:
            pass
        
        # Remover arquivos de marcação
        marker_files = [
            os.path.join(server_path, '.ark_installed'),
            os.path.join(server_path, '.ark_version')
        ]
        for marker_file in marker_files:
            if os.path.exists(marker_file):
                os.remove(marker_file)
        
        # Remover diretório do servidor
        if os.path.exists(server_path):
            shutil.rmtree(server_path)
            log_installation(f"Diretório do servidor removido: {server_path}", server_id)
        else:
            log_installation(f"Diretório do servidor não encontrado: {server_path}", server_id)
        
        # Remover logs específicos do servidor
        server_logs = [
            os.path.join(LOGS_DIR, f'server_{server_id}.log'),
            os.path.join(LOGS_DIR, f'install_server_{server_id}.log'),
            os.path.join(LOGS_DIR, f'update_server_{server_id}.log')
        ]
        for log_file in server_logs:
            if os.path.exists(log_file):
                os.remove(log_file)
        
        log_installation("Servidor desinstalado com sucesso!", server_id)
        return True
    except Exception as e:
        log_installation(f"ERRO na desinstalação: {str(e)}", server_id)
        return False
def filter_log_lines(lines, search_term=None, start_date=None, end_date=None):
    """Filtrar linhas de log por termo de busca e/ou data"""
    filtered_lines = []
    
    for line in lines:
        # Filtrar por termo de busca
        if search_term and search_term.lower() not in line.lower():
            continue
            
        # Filtrar por data (se houver timestamp no formato [YYYY-MM-DD HH:MM:SS])
        if start_date or end_date:
            try:
                # Extrair timestamp da linha de log
                if line.startswith('[') and ']' in line:
                    timestamp_str = line[1:line.find(']')]
                    log_timestamp = datetime.strptime(timestamp_str, '%Y-%m-%d %H:%M:%S')
                    
                    if start_date and log_timestamp < start_date:
                        continue
                    if end_date and log_timestamp > end_date:
                        continue
            except ValueError:
                # Se não conseguir parsear a data, incluir a linha
                pass
        
        filtered_lines.append(line)
    
    return filtered_lines
def get_available_log_files(server_id):
    """Obter lista de arquivos de log disponíveis para um servidor"""
    log_files = []
    
    # Log principal do servidor
    main_log = os.path.join(LOGS_DIR, f'server_{server_id}.log')
    if os.path.exists(main_log):
        log_files.append({
            'name': 'Execução Principal',
            'file': f'server_{server_id}.log',
            'type': 'main'
        })
    
    # Logs de instalação
    install_log = os.path.join(LOGS_DIR, f'install_server_{server_id}.log')
    if os.path.exists(install_log):
        log_files.append({
            'name': 'Instalação',
            'file': f'install_server_{server_id}.log',
            'type': 'install'
        })
    
    # Logs de atualização
    update_log = os.path.join(LOGS_DIR, f'update_server_{server_id}.log')
    if os.path.exists(update_log):
        log_files.append({
            'name': 'Atualização',
            'file': f'update_server_{server_id}.log',
            'type': 'update'
        })
    
    return log_files
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
    
    # Obter lista de arquivos de log disponíveis
    log_files = get_available_log_files(server_id)
    
    return render_template('server_detail.html', server=server_info, log_files=log_files)
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
@app.route('/api/server/<int:server_id>/logs')
def get_server_logs(server_id):
    """Endpoint para obter logs do servidor com filtros"""
    log_file = os.path.join(LOGS_DIR, f'server_{server_id}.log')
    
    # Parâmetros de filtro
    search_term = request.args.get('search')
    start_date_str = request.args.get('start_date')
    end_date_str = request.args.get('end_date')
    lines_limit = request.args.get('lines', 500)  # Padrão: 500 linhas
    
    try:
        lines_limit = int(lines_limit)
    except ValueError:
        lines_limit = 500
    
    if os.path.exists(log_file):
        try:
            with open(log_file, 'r') as f:
                lines = f.readlines()
                
            # Aplicar filtros
            start_date = None
            end_date = None
            if start_date_str:
                try:
                    start_date = datetime.strptime(start_date_str, '%Y-%m-%d')
                except ValueError:
                    pass
            if end_date_str:
                try:
                    end_date = datetime.strptime(end_date_str, '%Y-%m-%d')
                    # Definir hora final do dia
                    end_date = end_date.replace(hour=23, minute=59, second=59)
                except ValueError:
                    pass
            
            filtered_lines = filter_log_lines(lines, search_term, start_date, end_date)
            
            # Limitar número de linhas
            if len(filtered_lines) > lines_limit:
                filtered_lines = filtered_lines[-lines_limit:]
            
            log_content = ''.join(filtered_lines)
            return jsonify({'status': 'success', 'logs': log_content})
        except Exception as e:
            return jsonify({'status': 'error', 'message': f'Erro ao ler logs: {str(e)}'})
    else:
        return jsonify({'status': 'error', 'message': 'Arquivo de log não encontrado'})
@app.route('/api/server/<int:server_id>/install_logs')
def get_server_install_logs(server_id):
    """Endpoint para obter logs específicos de instalação de um servidor"""
    log_file = os.path.join(LOGS_DIR, f'install_server_{server_id}.log')
    if os.path.exists(log_file):
        try:
            with open(log_file, 'r') as f:
                # Lê as últimas 500 linhas para mais contexto
                lines = f.readlines()
                last_lines = lines[-500:] if len(lines) > 500 else lines
                log_content = ''.join(last_lines)
            return jsonify({'status': 'success', 'logs': log_content})
        except Exception as e:
            return jsonify({'status': 'error', 'message': f'Erro ao ler logs de instalação: {str(e)}'})
    else:
        return jsonify({'status': 'error', 'message': 'Arquivo de log de instalação não encontrado'})
@app.route('/api/server/<int:server_id>/update_logs')
def get_server_update_logs(server_id):
    """Endpoint para obter logs específicos de atualização de um servidor"""
    log_file = os.path.join(LOGS_DIR, f'update_server_{server_id}.log')
    if os.path.exists(log_file):
        try:
            with open(log_file, 'r') as f:
                # Lê as últimas 500 linhas para mais contexto
                lines = f.readlines()
                last_lines = lines[-500:] if len(lines) > 500 else lines
                log_content = ''.join(last_lines)
            return jsonify({'status': 'success', 'logs': log_content})
        except Exception as e:
            return jsonify({'status': 'error', 'message': f'Erro ao ler logs de atualização: {str(e)}'})
    else:
        return jsonify({'status': 'error', 'message': 'Arquivo de log de atualização não encontrado'})
@app.route('/api/server/<int:server_id>/specific_log')
def get_specific_log(server_id):
    """Endpoint para obter conteúdo de um arquivo de log específico"""
    filename = request.args.get('file')
    if not filename:
        return jsonify({'status': 'error', 'message': 'Nome do arquivo não especificado'})
    
    # Validar nome do arquivo para segurança
    allowed_files = [f'server_{server_id}.log', f'install_server_{server_id}.log', f'update_server_{server_id}.log']
    
    if filename not in allowed_files:
        return jsonify({'status': 'error', 'message': 'Arquivo não permitido'})
    
    log_file = os.path.join(LOGS_DIR, filename)
    if os.path.exists(log_file):
        try:
            with open(log_file, 'r') as f:
                lines = f.readlines()
                # Limitar a 1000 linhas para performance
                if len(lines) > 1000:
                    lines = lines[-1000:]
                log_content = ''.join(lines)
            return jsonify({'status': 'success', 'logs': log_content, 'filename': filename})
        except Exception as e:
            return jsonify({'status': 'error', 'message': f'Erro ao ler log: {str(e)}'})
    else:
        return jsonify({'status': 'error', 'message': 'Arquivo de log não encontrado'})
@app.route('/api/installation/logs')
def get_installation_logs():
    log_file = os.path.join(LOGS_DIR, 'installation.log')
    if os.path.exists(log_file):
        try:
            with open(log_file, 'r') as f:
                # Lê as últimas 500 linhas para mais contexto
                lines = f.readlines()
                last_lines = lines[-500:] if len(lines) > 500 else lines
                log_content = ''.join(last_lines)
            return jsonify({'status': 'success', 'logs': log_content})
        except Exception as e:
            return jsonify({'status': 'error', 'message': f'Erro ao ler logs: {str(e)}'})
    else:
        return jsonify({'status': 'error', 'message': 'Arquivo de log não encontrado'})
@app.route('/api/server/<int:server_id>/install', methods=['POST'])
def install_server(server_id):
    servers_data = load_servers()
    server = next((s for s in servers_data['servers'] if s['id'] == server_id), None)
    if not server:
        log_installation(f"Servidor ID {server_id} não encontrado!")
        return jsonify({'error': 'Servidor não encontrado'}), 404
    
    # Verificar se já está instalado
    if check_server_installed(server):
        return jsonify({'status': 'error', 'message': 'Servidor já está instalado! Use "Forçar Atualização" para reinstalar.'}), 400
    
    # Obter parâmetros da requisição
    data = request.get_json()
    branch = data.get('branch', 'preaquatica')  # Padrão é preaquatica para contornar bug
    
    log_installation(f"Recebida solicitação de instalação para servidor ID: {server_id} (branch: {branch})")
    
    try:
        # Criar diretórios
        os.makedirs(server['path'], exist_ok=True)
        log_installation(f"Diretórios criados: {server['path']}")
        
        # Instalar servidor
        success = install_server_steamcmd(server['path'], server_id, branch=branch)
        if success:
            log_installation(f"Servidor {server_id} instalado com sucesso!")
            return jsonify({'status': 'success', 'message': 'Servidor instalado com sucesso!'})
        else:
            log_installation(f"Erro na instalação do servidor {server_id}")
            return jsonify({'status': 'error', 'message': 'Erro na instalação do servidor. Verifique os logs de instalação específicos do servidor.'}), 500
    except Exception as e:
        log_installation(f"EXCEÇÃO na instalação do servidor {server_id}: {str(e)}")
        import traceback
        log_installation(f"Traceback: {traceback.format_exc()}")
        return jsonify({'status': 'error', 'message': f'Exceção: {str(e)}'}), 500
@app.route('/api/server/<int:server_id>/force_install', methods=['POST'])
def force_install_server(server_id):
    """Forçar reinstalação do servidor"""
    servers_data = load_servers()
    server = next((s for s in servers_data['servers'] if s['id'] == server_id), None)
    if not server:
        log_installation(f"Servidor ID {server_id} não encontrado!")
        return jsonify({'error': 'Servidor não encontrado'}), 404
    
    # Obter parâmetros da requisição
    data = request.get_json()
    branch = data.get('branch', 'preaquatica')  # Padrão é preaquatica
    
    log_installation(f"Recebida solicitação de FORCE INSTALL para servidor ID: {server_id} (branch: {branch})")
    
    try:
        # Forçar reinstalação
        success = install_server_steamcmd(server['path'], server_id, force_update=True, branch=branch)
        if success:
            log_installation(f"Servidor {server_id} REINSTALADO com sucesso!")
            return jsonify({'status': 'success', 'message': 'Servidor reinstalado com sucesso!'})
        else:
            log_installation(f"Erro na REINSTALAÇÃO do servidor {server_id}")
            return jsonify({'status': 'error', 'message': 'Erro na reinstalação do servidor. Verifique os logs.'}), 500
    except Exception as e:
        log_installation(f"EXCEÇÃO na REINSTALAÇÃO do servidor {server_id}: {str(e)}")
        import traceback
        log_installation(f"Traceback: {traceback.format_exc()}")
        return jsonify({'status': 'error', 'message': f'Exceção: {str(e)}'}), 500
@app.route('/api/server/<int:server_id>/update', methods=['POST'])
def update_server(server_id):
    """Atualizar servidor existente"""
    servers_data = load_servers()
    server = next((s for s in servers_data['servers'] if s['id'] == server_id), None)
    if not server:
        return jsonify({'error': 'Servidor não encontrado'}), 404
    
    # Verificar se está instalado
    if not check_server_installed(server):
        return jsonify({'error': 'Servidor não instalado! Instale primeiro.'}), 400
    
    # Obter parâmetros da requisição
    data = request.get_json()
    branch = data.get('branch', 'preaquatica')  # Padrão é preaquatica
    
    try:
        success = update_server_steamcmd(server['path'], server_id, branch=branch)
        if success:
            return jsonify({'status': 'success', 'message': 'Servidor atualizado com sucesso!'})
        else:
            return jsonify({'status': 'error', 'message': 'Erro na atualização do servidor. Verifique os logs.'}), 500
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500
@app.route('/api/server/<int:server_id>/uninstall', methods=['POST'])
def uninstall_server_api(server_id):
    """Desinstalar servidor"""
    servers_data = load_servers()
    server = next((s for s in servers_data['servers'] if s['id'] == server_id), None)
    if not server:
        return jsonify({'error': 'Servidor não encontrado'}), 404
    
    try:
        success = uninstall_server(server['path'], server_id)
        if success:
            return jsonify({'status': 'success', 'message': 'Servidor desinstalado com sucesso!'})
        else:
            return jsonify({'status': 'error', 'message': 'Erro na desinstalação do servidor.'}), 500
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
        subprocess.Popen(['/usr/bin/nohup', '/bin/bash', script_path], 
                        stdout=open(f"{LOGS_DIR}/server_{server_id}.log", 'w'),
                        stderr=subprocess.STDOUT,
                        start_new_session=True)
        return jsonify({'status': 'success', 'message': 'Servidor iniciado'})
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500
@app.route('/api/server/<int:server_id>/stop', methods=['POST'])
def stop_server(server_id):
    try:
        subprocess.run(['/usr/bin/pkill', '-f', f"ShooterGameServer.*Port={7777 + (server_id-1)*10}"])
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
