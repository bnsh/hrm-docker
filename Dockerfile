FROM python:3.12

ENV USER=hrm \
	PATH="/home/hrm/src/alt-text-generator/.venv/bin:/home/hrm/.venv/bin:/usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
	HRM=/home/hrm \
	GECOS="Hierarchical Reasoning Model" \
	CUDA_HOME=/usr/local/cuda-12.9

RUN adduser --gecos "${GECOS}" "${USER}"
RUN apt update -y && apt upgrade -y && apt install -y git curl vim

RUN wget -O /tmp/cuda-ubuntu2204.pin https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-ubuntu2204.pin
RUN mv /tmp/cuda-ubuntu2204.pin /etc/apt/preferences.d/cuda-repository-pin-600
RUN wget -O /tmp/cuda-repo-ubuntu2204-12-9-local_12.9.1-575.57.08-1_amd64.deb https://developer.download.nvidia.com/compute/cuda/12.9.1/local_installers/cuda-repo-ubuntu2204-12-9-local_12.9.1-575.57.08-1_amd64.deb
RUN dpkg -i /tmp/cuda-repo-ubuntu2204-12-9-local_12.9.1-575.57.08-1_amd64.deb
RUN cp /var/cuda-repo-ubuntu2204-12-9-local/cuda-3C590CF5-keyring.gpg /usr/share/keyrings/
RUN apt-get update -y && apt-get -y install cuda-toolkit-12-9

USER ${USER}
RUN python3 -m venv "${HRM}/.venv"
RUN python3 -m pip install -U pip
RUN git clone https://github.com/sapientinc/HRM.git "${HRM}/src/hrm"
RUN ${HRM}/.venv/bin/python3 -m pip install -U -r "${HRM}/src/hrm/requirements.txt"
COPY extra-requirements.txt /tmp/extra-requirements.txt
RUN ${HRM}/.venv/bin/python3 -m pip install -U -r /tmp/extra-requirements.txt
RUN ${HRM}/.venv/bin/python3 -m pip install flash-attn --no-build-isolation
RUN perl -p -i -e 's/^from adam_atan2 import AdamATan2$/from adam_atan2_pytorch import AdamAtan2 as AdamATan2/g' ${HRM}/src/hrm/pretrain.py
RUN perl -p -i -e 's/lr=0/lr=1e-3/g' ${HRM}/src/hrm/pretrain.py
RUN mkdir -p ${HRM}/.config/wandb ${HRM}/.cache/wandb
WORKDIR "${HRM}"
