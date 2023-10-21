#!/bin/bash
if [ $# -eq 0 ]; then
    echo "Ошибка: необходимо передать название проекта."
    exit 1
fi
RUN_APP=false
PROJECT_NAME="${!#}"
while getopts "r" opt; do
  case $opt in
    r) RUN_APP=true ;;
    *) echo "Ошибка: Неизвестный ключ." >&2; exit 1 ;;
  esac
done
OS=$(uname | tr '[:upper:]' '[:lower:]' || echo "win")

INSTALL_CMD=""
UPDATE_CMD=""

case $OS in
    "linux")
        DISTRO=$(grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
        case $DISTRO in
            "debian"|"ubuntu")
                INSTALL_CMD="apt-get install -y"
                UPDATE_CMD="apt-get update"
                ;;
            "fedora")
                INSTALL_CMD="dnf install -y"
                UPDATE_CMD="dnf update"
                ;;
            *)
                echo "Этот дистрибутив Linux не поддерживается."
                exit 1
                ;;
        esac
        ;;
    "darwin")  # MacOS
        if ! which brew > /dev/null; then
            echo "Homebrew не найден. Устанавливаю..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        INSTALL_CMD="brew install"
        UPDATE_CMD="brew update"
        ;;
    "win")    # Windows
        if ! which choco > /dev/null; then
            echo "Chocolatey не найден. Устанавливаю..."
            powershell -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))"
        fi
        INSTALL_CMD="choco install -y"
        UPDATE_CMD="choco upgrade"
        ;;
    *)
        echo "Эта операционная система не поддерживается."
        exit 1
        ;;
esac
echo "Проверяю наличие Python 3.11..."
if ! which python3.11 > /dev/null; then
    echo "Python3 не найден. Устанавливаю..."
    echo "Обновляю список пакетов..."
    $UPDATE_CMD
    echo "Устанавливаю Python 3.11..."
    $INSTALL_CMD python3.11
    echo "Python 3.11 установлен."
else
    echo "Python3 уже установлен."
fi

echo "Проверяю наличие pip3..."
if ! which pip3 > /dev/null; then
    echo "pip3 не найден. Устанавливаю..."
    echo "Обновляю список пакетов..."
    $UPDATE_CMD
    echo "Устанавливаю pip3..."
    $INSTALL_CMD python3-pip
    echo "pip3 установлен."
else
    echo "pip3 уже установлен."
fi

echo "Обновляю pip3..."
pip3 install --upgrade pip
echo "pip3 обновлен."


echo "Создаю структуру директорий..."
mkdir $PROJECT_NAME
cd $PROJECT_NAME
echo "Создаю виртуальное окружение..."
python3.11 -m venv .venv
echo "Виртуальное окружение создано."

echo "Активирую виртуальное окружение..."
source .venv/bin/activate
echo "Виртуальное окружение активировано."

echo "Устанавливаю необходимые пакеты..."
pip install 'fastapi[all]' uvicorn
echo "Необходимые пакеты установлены."

mkdir api
cd api
mkdir dependencies
mkdir endpoints
mkdir models
cd ..
mkdir core
cd core
touch config.py
cd ..
mkdir db
cd db
mkdir models
touch base.py
touch session.py
cd ..
mkdir schemas
mkdir services
mkdir tests
echo "Структура директорий создана."

echo "Создаю стандартные файлы для FastAPI..."
echo -e "from fastapi import FastAPI\n"\
"app = FastAPI()\n\n"\
"@app.get(\"/\")\n"\
"async def root():\n"\
"\treturn {\"message\": \"Hello World\"}\n\n"\
"@app.get(\"/hello/{name}\")\n"\
"async def say_hello(name: str):\n"\
"\treturn {\"message\": f\"Hello {name}\"}" > main.py
cd tests
echo -e "# Test your FastAPI endpoints\n\n"\
"GET http://127.0.0.1:8000/\n"\
"Accept: application/json\n\n"\
"###\n\n"\
"GET http://127.0.0.1:8000/hello/User\n"\
"Accept: application/json\n\n"\
"###" > test_main.http
echo "Стандартные файлы для FastAPI созданы."
cd ..
echo "Скрипт завершил выполнение!"

pwd
if $RUN_APP; then
    echo "Запускаю приложение..."
    uvicorn main:app --reload
fi
