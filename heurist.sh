#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # 색상 초기화

# 초기 선택 메뉴
echo -e "${YELLOW}옵션을 선택하세요:${NC}"
echo -e "${GREEN}1: heurist 노드 설치${NC}"
echo -e "${GREEN}2: heurist 노드 제거${NC}"
echo -e "${RED}대시보드사이트:https://www.heurist.ai/mining${NC}"

read -p "선택 (1, 2): " option

if [ "$option" == "1" ]; then
    echo "kuzco 노드 새로 설치를 선택했습니다."
    
    echo -e "${YELLOW}NVIDIA 드라이버 설치 옵션을 선택하세요:${NC}"
    echo -e "1: 일반 그래픽카드 (RTX, GTX 시리즈) 드라이버 설치"
    echo -e "2: 서버용 GPU (T4, L4, A100 등) 드라이버 설치"
    echo -e "3: 기존 드라이버 및 CUDA 완전 제거"
    echo -e "4: 드라이버 설치 건너뛰기"
    
    while true; do
        read -p "선택 (1, 2, 3): " driver_option
        
        case $driver_option in
            1)
                sudo apt update
                sudo apt install -y nvidia-utils-550
                sudo apt install -y nvidia-driver-550
                sudo apt-get install -y cuda-drivers-550 
                sudo apt-get install -y cuda-12-3
                ;;
            2)
                distribution=$(. /etc/os-release;echo $ID$VERSION_ID | sed -e 's/\.//g')
                wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
                sudo dpkg -i cuda-keyring_1.1-1_all.deb
                sudo apt-get update
                sudo apt install -y nvidia-utils-550-server
                sudo apt install -y nvidia-driver-550-server
                sudo apt-get install -y cuda-12-3
                ;;
            3)
                echo "기존 드라이버 및 CUDA를 제거합니다..."
                sudo apt-get purge -y nvidia*
                sudo apt-get purge -y cuda*
                sudo apt-get purge -y libnvidia*
                sudo apt autoremove -y
                sudo rm -rf /usr/local/cuda*
                echo "드라이버 및 CUDA가 완전히 제거되었습니다."
                ;;
            4)
                echo "드라이버 설치를 건너뜁니다."
                break
                ;;
            *)
                echo "잘못된 선택입니다. 다시 선택해주세요."
                continue
                ;;
        esac
        
        if [ "$driver_option" != "4" ]; then
            echo -e "\n${YELLOW}NVIDIA 드라이버 설치 옵션을 선택하세요:${NC}"
            echo -e "1: 일반 그래픽카드 (RTX, GTX 시리즈) 드라이버 설치"
            echo -e "2: 서버용 GPU (T4, L4, A100 등) 드라이버 설치"
            echo -e "3: 기존 드라이버 및 CUDA 완전 제거"
            echo -e "4: 드라이버 설치 건너뛰기"
        fi
    done
    
        # CUDA 툴킷 설치 여부 확인
        if command -v nvcc &> /dev/null; then
            echo -e "${GREEN}CUDA 툴킷이 이미 설치되어 있습니다.${NC}"
            nvcc --version
            read -p "CUDA 툴킷을 다시 설치하시겠습니까? 최초설치시 업데이트를 위해 다시설치하세요. (y/n): " reinstall_cuda
            if [ "$reinstall_cuda" == "y" ]; then
                sudo apt-get -y install cuda-toolkit-12-3
                echo 'export PATH=/usr/local/cuda-12.3/bin:$PATH' >> ~/.bashrc
                echo 'export LD_LIBRARY_PATH=/usr/local/cuda-12.3/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc
                export PATH=/usr/local/cuda/bin:$PATH
                export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
                source ~/.bashrc
                sudo ln -s /usr/local/cuda-12.3 /usr/local/cuda
            fi
        else
            echo -e "${YELLOW}CUDA 툴킷을 설치합니다...${NC}"
            sudo apt-get install -y nvidia-cuda-toolkit
        fi

        export PATH=/usr/local/cuda/bin:$PATH
        export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
        source ~/.bashrc

        echo "wsl --set-default-version 2"
        echo "wsl --shutdown"
        echo "wsl --update"
        read -p "윈도우라면 파워셸을 관리자권한으로 열어서 위 명령어들을 입력하세요"
        
        # 스크립트를 파일로 저장
        git clone https://github.com/heurist-network/miner-release.git

        # 작업공간 이동
        cd "$HOME/miner-release"

        # 필수 패키지 설치
        sudo apt update
        sudo apt install -y wget curl bzip2

        # Python 설치
        sudo apt install -y python3

        # Miniconda 설치
        wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh
        bash ~/miniconda.sh -b -p $HOME/miniconda
        export PATH="$HOME/miniconda/bin:$PATH"
        source ~/.bashrc

        # conda 초기화
        conda init

        # conda 환경 생성 및 활성화
        conda create --name heurist-miner python=3.11
        conda activate heurist-miner

        # requirements.txt 파일을 통한 패키지 설치
        cd "$HOME/miner-release"
        pip install -r requirements.txt

        # 사용자에게 지갑 주소 입력 받기
        read -p "마이너로 사용할 지갑 주소를 입력하세요: " wallet_address

        # .env 파일에 저장
        echo "MINER_ID_0=$wallet_address" > .env

        # 마이너 실행
        python3 sd-miner.py
        chmod +x llm-miner-starter.sh
        ./llm-miner-starter.sh dolphin-2.9-llama3-8b --miner-id-index 0 --port 8000 --gpu-ids 0

elif [ "$option" == "2" ]; then
    echo "kuzco 노드를 제거를 선택했습니다."

    # miner-release 디렉토리 제거
    if [ -d "$HOME/miner-release" ]; then
        echo "miner-release 디렉토리를 제거합니다..."
        rm -rf "$HOME/miner-release"
        echo "miner-release 디렉토리가 제거되었습니다."
    else
        echo "miner-release 디렉토리가 존재하지 않습니다."
    fi

    # 구동 중인 노드 프로세스 종료
    echo "구동 중인 노드를 종료합니다..."
    pkill -f sd-miner.py
    pkill -f llm-miner-starter.sh
    echo "구동 중인 노드가 종료되었습니다."

    echo "노드 제거가 완료되었습니다."
fi
