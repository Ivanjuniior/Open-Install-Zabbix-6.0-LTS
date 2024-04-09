#!/bin/bash

#====================================================================>
#=====>        NAME:............:    auto_install_zabbix_6.0.sh      #
#=====>        VERSION:.........:    2.8                             #
#=====>        DESCRIPTION:.....:    Auto Instalação Zabbix 6.0-LTS  #
#=====>        CREATE DATE:.....:    06/06/2022                      #
#=====>        UPDATE DATE:.....:    5/04/2024                       #
#=====>        WRITTEN BY:......:    Ivan da Silva Bispo Junior      #
#=====>        E-MAIL:..........:    contato@ivanjr.eti.br           #
#=====>        DISTRO:..........:    Debian GNU/Linux 12 (Bookworm)  #
#====================================================================>

# Definir o caminho do arquivo de log
LOG_FILE="/var/log/auto_install_zabbix.log"

# Função para registrar mensagens no arquivo de log
log_message() {
    local timestamp
    timestamp=$(date +"%Y-%m-%d %T")
    echo "[$timestamp] $1" >> "$LOG_FILE"
}

# Registrar início da execução do script no arquivo de log
log_message "Início da execução do script auto_install_zabbix_6.0.sh"

clear
# Verifica se o sistema operacional é compatível
if [[ "$(lsb_release -is)" != "Debian" && "$(lsb_release -is)" != "Ubuntu" ]]; then
    echo "Este script é projetado para Debian ou Ubuntu. Abortando a instalação."
    exit 1
fi

# Verifica a versão do sistema operacional
if [[ "$(lsb_release -cs)" != "Bullseye" && "$(lsb_release -cs)" != "Bookworm" && "$(lsb_release -cs)" != "22.04.4" ]]; then
    echo "Este script é projetado para Debian 11 (Bullseye), Debian 12 (Bookworm) ou Ubuntu 22.04.4 LTS. Abortando a instalação."
    exit 1
fi

# Mensagem de progresso
echo "Sistema operacional compatível. Procedendo com a instalação..."

# Tratamento de erros
set -e

# Upgrade do SO
apt update && apt upgrade -y
apt install dialog -y
cd /tmp || exit
rm -f *deb*
rm -f /tmp/finish

# Função para solicitar ao usuário que escolha a combinação de servidor web e banco de dados
function escolher_combinacao() {
    dialog --stdout --menu "Escolha a combinação de servidor web e banco de dados:" 0 0 0 \
        1 "nginx + PostgreSQL" \
        2 "nginx + MariaDB" \
        3 "Apache2 + PostgreSQL" \
        4 "Apache2 + MariaDB"
}

# Função para solicitar ao usuário que insira as informações usando o dialog
function solicitar_informacoes() {
    NOME_USUARIO=$(dialog --stdout --inputbox "Digite o nome do usuário do banco de dados:" 0 0 "$1")
    SENHA_USUARIO=$(dialog --stdout --passwordbox "Digite a senha do usuário do banco de dados:" 0 0 "$2")
    NOME_BANCO=$(dialog --stdout --inputbox "Digite o nome do banco de dados:" 0 0 "$3")
    IP=$(dialog --stdout --inputbox "Digite o IP do servidor:" 0 0 "$4")
}

# Loop para solicitar informações até que o usuário confirme que estão corretas
while true; do
    # Chama a função para escolher a combinação de servidor web e banco de dados
    escolha=$(escolher_combinacao)

    # Define as variáveis de acordo com a escolha do usuário
    case $escolha in
        1) SERVIDOR="nginx"; BANCO_DADOS="PostgreSQL";;
        2) SERVIDOR="nginx"; BANCO_DADOS="MariaDB";;
        3) SERVIDOR="Apache2"; BANCO_DADOS="PostgreSQL";;
        4) SERVIDOR="Apache2"; BANCO_DADOS="MariaDB";;
        *) echo "Escolha inválida. Por favor, escolha novamente."; continue;;
    esac

    # Chama a função para solicitar informações, passando os valores padrão (se houver)
    solicitar_informacoes "$NOME_USUARIO" "$SENHA_USUARIO" "$NOME_BANCO" "$IP"

    # Exibe as informações fornecidas pelo usuário para verificação
    dialog --stdout --msgbox "Por favor, verifique se as informações estão corretas:
Nome do usuário do banco de dados: $NOME_USUARIO
Nome do banco de dados: $NOME_BANCO
IP do servidor: $IP
Combinação selecionada: $SERVIDOR + $BANCO_DADOS" 0 0

    # Pergunta ao usuário se as informações estão corretas
    dialog --stdout --yesno "As informações estão corretas?" 0 0
    response=$?

    # Verifica a resposta do usuário
    if [ $response -eq 0 ]; then
        break  # Sai do loop se as informações estiverem corretas
    fi
done

# Mensagem de progresso
echo "Instalando dependências e bibliotecas essenciais..."

# Instalação de dependências e bibliotecas essenciais
# Lista das bibliotecas essenciais
bibliotecas=("wget" "build-essential" "snmpd" "snmp" "snmptrapd" "libsnmp-base" "libsnmp-dev" "screen" "figlet" "toilet" "cowsay")

# Verifica e instala cada biblioteca se não estiver instalada
for lib in "${bibliotecas[@]}"; do
    if ! dpkg -l | grep -q "$lib"; then
        apt-get install -y "$lib"
    fi
done

# Criação do usuário Zabbix
# Verifica se o usuário zabbix já está presente
if ! id -u zabbix >/dev/null 2>&1; then
    # Cria o usuário zabbix apenas se não estiver presente
    useradd -r -s /usr/sbin/nologin zabbix
fi

# Instalação do servidor web
if [ "$SERVIDOR" == "nginx" ]; then
    # Verifica se o Nginx não está instalado
    if ! dpkg -l | grep -q nginx; then
        apt install -y nginx
        sed -i 's/#server_tokens/server_tokens/' /etc/nginx/nginx.conf
        systemctl restart nginx
    else
        echo "O Nginx já está instalado. Pulando a instalação."
    fi
    # Desinstala o Apache2, se estiver instalado
    if dpkg -l | grep -q apache2; then
        apt remove --purge -y apache2 apache2-utils
    fi
elif [ "$SERVIDOR" == "Apache2" ]; then
    # Verifica se o Apache2 não está instalado
    if ! dpkg -l | grep -q apache2; then
        apt install -y apache2 apache2-utils
    else
        echo "O Apache2 já está instalado. Pulando a instalação."
    fi
    # Desinstala o Nginx, se estiver instalado
    if dpkg -l | grep -q nginx; then
        apt remove --purge -y nginx
    fi
fi

# Instalação do SGBD
if [ "$BANCO_DADOS" == "MariaDB" ]; then
    # Verifica se o MariaDB não está instalado
    if ! dpkg -l | grep -q mariadb-server; then
        apt install -y mariadb-server mariadb-client
    else
        echo "O MariaDB já está instalado. Pulando a instalação."
    fi
elif [ "$BANCO_DADOS" == "PostgreSQL" ]; then
    # Verifica se o PostgreSQL não está instalado
    if ! dpkg -l | grep -q postgresql; then
        apt install -y postgresql
    else
        echo "O PostgreSQL já está instalado. Pulando a instalação."
    fi
fi

# Verifica se o PHP não está instalado
if ! dpkg -l | grep -q php; then
    # Instalação do PHP comum
    apt install -y php

    # Verifica se cada biblioteca PHP está instalada individualmente e a instala, se necessário
    PHP_LIBS=("php-cli" "php-pear" "php-gmp" "php-gd" "php-bcmath" "php-curl" "php-xml" "php-zip")
    for lib in "${PHP_LIBS[@]}"; do
        if ! dpkg -l | grep -q "$lib"; then
            apt install -y "$lib"
        fi
    done

    # Verifica qual servidor web está instalado e instala os pacotes adicionais do PHP conforme necessário
    if [ "$SERVIDOR" == "nginx" ]; then
        apt install -y php-fpm php-mysql php-json php-pgsql
    elif [ "$SERVIDOR" == "Apache2" ]; then
        # Remove o pacote PHP que foi instalado anteriormente
        apt remove --purge -y php
        # Instala o pacote correto para o Apache2
        apt install -y libapache2-mod-php php-mysql php-json
    fi
fi

# Verifica se o Zabbix não está instalado
if ! dpkg -l | grep -q zabbix; then
    # Download e instalação do pacote de repositório do Zabbix
    wget https://repo.zabbix.com/zabbix/6.0/debian/pool/main/z/zabbix-release/zabbix-release_6.0-5+debian12_all.deb -P /tmp
    dpkg -i /tmp/zabbix-release_6.0-5+debian12_all.deb
    apt update && apt upgrade -y

    # Instalação do Zabbix Server e Frontend de acordo com a combinação selecionada de servidor web e banco de dados
    case "$SERVIDOR-$BANCO_DADOS" in
        nginx-PostgreSQL)
            apt install -y zabbix-server-pgsql zabbix-frontend-php php-pgsql zabbix-nginx-conf zabbix-sql-scripts zabbix-agent
            ;;
        nginx-MariaDB)
            apt install -y zabbix-server-mysql zabbix-frontend-php zabbix-nginx-conf zabbix-sql-scripts zabbix-agent
            ;;
        Apache2-PostgreSQL)
            apt install -y zabbix-server-pgsql zabbix-frontend-php php-pgsql zabbix-apache-conf zabbix-sql-scripts zabbix-agent
            ;;
        Apache2-MariaDB)
            apt install -y zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent
            ;;
        *)
            echo "Combinação inválida de servidor web e banco de dados selecionada."
            exit 1
            ;;
    esac
else
    echo "O Zabbix já está instalado. Pulando a instalação."
fi

# Configuração do banco de dados Zabbix
# Ação apropriada para o banco de dados escolhido
if [ "$BANCO_DADOS" == "MariaDB" ]; then
    # Configuração para MariaDB
    export DEBIAN_FRONTEND=noninteractive
    mariadb -uroot -e "create database $NOME_BANCO character set utf8mb4 collate utf8mb4_bin;"
    mariadb -uroot -e "create user '$NOME_USUARIO'@'localhost' identified by '$SENHA_USUARIO';"
    mariadb -uroot -e "grant all privileges on $NOME_BANCO.* to '$NOME_USUARIO'@'localhost';"
    mariadb -uroot -e "set global log_bin_trust_function_creators = 1;"
    zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql --default-character-set=utf8mb4 -u$NOME_USUARIO -p$SENHA_USUARIO $NOME_BANCO
    mariadb -uroot -e "set global log_bin_trust_function_creators = 0;"
    echo 'Populando base de dados zabbix, pode demorar um pouco dependendo do hardware'
    sleep 3
    sed -i "s/# DBPassword=/DBPassword=$SENHA_USUARIO/" /etc/zabbix/zabbix_server.conf
elif [ "$BANCO_DADOS" == "PostgreSQL" ]; then
    # Configuração para PostgreSQL
    export DEBIAN_FRONTEND=noninteractive
    sudo sed -i "s/ident/md5/g" /etc/postgresql/15/main/pg_hba.conf
    su postgres -c "psql -c \"CREATE USER $NOME_USUARIO WITH PASSWORD '$SENHA_USUARIO';\""
    su postgres -c "psql -c \"CREATE DATABASE $NOME_BANCO WITH OWNER $NOME_USUARIO;\""
    su postgres -c "psql -c \"GRANT ALL PRIVILEGES ON DATABASE $NOME_BANCO TO $NOME_USUARIO;\""
    zcat /usr/share/doc/zabbix-sql-scripts/postgresql/schema.sql.gz | sudo -u $NOME_USUARIO psql $NOME_BANCO
    zcat /usr/share/zabbix-sql-scripts/postgresql/server.sql.gz | sudo -u $NOME_USUARIO psql $NOME_BANCO
    echo 'Populando base de dados zabbix, pode demorar um pouco dependendo do hardware'
    sleep 3
    sed -i "s/# DBPassword=/DBPassword=$SENHA_USUARIO/" /etc/zabbix/zabbix_server.conf
    sudo rm /etc/nginx/sites-available/default
    sudo rm /etc/nginx/sites-enabled/default
    sudo rm /etc/nginx/conf.d/zabbix.conf
    sudo ln -s /etc/zabbix/nginx.conf /etc/nginx/sites-available/default
    sudo ln -s /etc/zabbix/nginx.conf /etc/nginx/sites-enabled/default
fi

# Função para solicitar o fuso horário ao usuário
function solicitar_fuso_horario() {
    FUSO_HORARIO=$(dialog --stdout --inputbox "Digite o fuso horário (exemplo: America/Sao_Paulo):" 0 0)
}

# Solicita o fuso horário ao usuário
solicitar_fuso_horario

# Define o fuso horário configurado pelo usuário
timedatectl set-timezone "$FUSO_HORARIO"

# Configuração do timezone para PHP
if [ "$SERVIDOR" == "Apache2" ]; then
    # Configuração para Apache2
    sed -i "s/# php_value date.timezone Europe\/Riga/php_value date.timezone $FUSO_HORARIO/g" /etc/apache2/conf-enabled/zabbix.conf
elif [ "$SERVIDOR" == "nginx" ]; then
    # Configuração para nginx
    echo "php_value[date.timezone] = $FUSO_HORARIO" | tee -a /etc/zabbix/php-fpm.conf >/dev/null
fi

# Habilita e reinicia serviços de acordo com o servidor escolhido
if [ "$SERVIDOR" == "Apache2" ]; then
    systemctl enable zabbix-server zabbix-agent apache2
    systemctl restart zabbix-server zabbix-agent apache2
elif [ "$SERVIDOR" == "nginx" ]; then
    systemctl enable zabbix-server zabbix-agent nginx
    systemctl restart zabbix-server zabbix-agent nginx
fi

# Mensagem de conclusão
log_message "Instalação concluída com sucesso. Acesse o frontend do Zabbix em http://$IP/zabbix/"

# Exibe a mensagem de conclusão para o usuário
dialog --msgbox "Instalação concluída com sucesso. Acesse o frontend do Zabbix em http://$IP/zabbix/" 0 0

# Diálogo para confirmar a instalação do Grafana
dialog --stdout --yesno "Deseja instalar o Grafana?" 0 0
response=$?

# Verifica a resposta do usuário
if [ $response -eq 0 ]; then
    # Instalação do Grafana
    apt-get install -y apt-transport-https software-properties-common
    wget -q -O - https://packages.grafana.com/gpg.key | apt-key add -
    echo "deb https://packages.grafana.com/oss/deb stable main" | tee -a /etc/apt/sources.list.d/grafana.list
    apt-get update && apt-get install -y grafana

    # Instalação do plugin do Zabbix para Grafana
    grafana-cli plugins install alexanderzobnin-zabbix-app
    systemctl daemon-reload
    systemctl start grafana-server
    systemctl enable grafana-server
    # Exibe a mensagem de conclusão para o usuário
    dialog --msgbox "Instalação concluída com sucesso. Acesse o frontend do Zabbix em http://$IP:3000" 0 0
else
    echo "Instalação do Grafana cancelada."
fi


# Ajustes SNMP
#O pulo do gato para o perfeito monitoramento, ajustes SNMP
wget http://ftp.de.debian.org/debian/pool/non-free/s/snmp-mibs-downloader/snmp-mibs-downloader_1.5_all.deb
Sleep 20
dpkg -i snmp-mibs-downloader_1.5_all.deb
sleep 20
apt-get -y install smistrip
#ajuste mib quebrada
wget -O /usr/share/snmp/mibs/ietf/SNMPv2-PDU http://pastebin.com/raw.php?i=p3QyuXzZ
clear
# Mensagem de conclusão
echo "Instalação concluída."
echo ""
echo "Deixe uma estrela no repositório do github:Ivanjuniior"
echo "Desenvolvido por: Ivan Junior"
echo "Doaçoes via pix: contato@ivanjr.eti.br"
# Registrar fim da execução do script no arquivo de log
log_message "Fim da execução do script auto_install_zabbix_6.0.sh"