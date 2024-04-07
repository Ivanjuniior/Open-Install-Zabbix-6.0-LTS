# Auto Instalação Zabbix 6.0-LTS

Este script automatiza o processo de instalação do Zabbix 6.0-LTS em um sistema Debian GNU/Linux 12 (Bookworm), permitindo que os usuários escolham entre diferentes combinações de servidor web (nginx ou Apache2) e banco de dados (PostgreSQL ou MariaDB). Além disso, o script instala dependências, configurações necessárias e oferece a opção de instalar o Grafana para visualizações avançadas.

## Pré-requisitos

Certifique-se de que o sistema operacional seja Debian GNU/Linux 12 (Bookworm). Você pode verificar isso usando o seguinte comando:

```bash
lsb_release -a
```
## Uso

Clone este repositório em seu sistema Debian 12 (Bookworm).
Execute o script usando o seguinte comando:

```
./auto_install_zabbix_6.0.sh
```

Siga as instruções do script para escolher as combinações de servidor web e banco de dados desejadas, inserir informações necessárias e confirmar as configurações.
Aguarde até que o script conclua a instalação e configuração do Zabbix.
Se desejar, você pode optar por instalar o Grafana quando solicitado pelo script.

## Teste do script

1 - nginx + PostgreSQL |
2 - nginx + MariaDB |
3 - Apache2 + PostgreSQL |
4 - Apache2 + MariaDB | *OK*

## Contribuição
As contribuições são bem-vindas! Sinta-se à vontade para abrir problemas (issues) para relatar bugs, solicitar recursos ou enviar solicitações de pull (pull requests) para correções ou melhorias.

## Autor
Ivan da Silva Bispo Junior
E-mail: contato@ivanjr.eti.br

#Licença
Este projeto está licenciado sob a Licença MIT. Consulte o arquivo LICENSE para obter detalhes.