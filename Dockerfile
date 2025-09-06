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

# The commit hash 05dd4ef795a98c20110e380a330d0b3ec159a46b is just the one I happened to use, and I'm adding it here, for the sake of replicability.
# In principle, you shouldn't have to slavishly follow this commit hash.
RUN git clone https://github.com/sapientinc/HRM.git "${HRM}/src/hrm" && ( cd "${HRM}/src/hrm" && git checkout 05dd4ef795a98c20110e380a330d0b3ec159a46b )
RUN ${HRM}/.venv/bin/python3 -m pip install -U -r "${HRM}/src/hrm/requirements.txt"
COPY extra-requirements.txt /tmp/extra-requirements.txt
RUN ${HRM}/.venv/bin/python3 -m pip install -U -r /tmp/extra-requirements.txt
RUN ${HRM}/.venv/bin/python3 -m pip install flash-attn --no-build-isolation

# This replacement (from adam_atan2...), is because if we don't do this, the `from adam_atan2 import AdamATan2` fails.
#     Traceback (most recent call last):
#      File "/home/hrm/src/hrm/pretrain.py", line 19, in <module>
#        from adam_atan2 import AdamATan2
#      File "/home/hrm/.venv/lib/python3.12/site-packages/adam_atan2/__init__.py", line 1, in <module>
#        from .adam_atan2 import AdamATan2
#      File "/home/hrm/.venv/lib/python3.12/site-packages/adam_atan2/adam_atan2.py", line 4, in <module>
#        import adam_atan2_backend
#    ModuleNotFoundError: No module named 'adam_atan2_backend'
RUN perl -p -i -e 's/^from adam_atan2 import AdamATan2$/from adam_atan2_pytorch import AdamAtan2 as AdamATan2/g' ${HRM}/src/hrm/pretrain.py

# This replacement (lr=...) is because if we don't do this, AdamAtan2 complains about lr being 0. (lr=0 is of course, ridiculous)
#     Error executing job with overrides: ['data_path=data/sudoku-extreme-1k-aug-1000', 'epochs=20000', 'eval_interval=2000', 'global_batch_size=384', 'lr=7e-5', 'puzzle_emb_lr=7e-5', 'weight_decay=1.0', 'puzzle_emb_weight_decay=1.0']
#     Traceback (most recent call last):
#       File "/home/hrm/src/hrm/pretrain.py", line 411, in launch
#         train_state = init_train_state(config, train_metadata, world_size=WORLD_SIZE)
#                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
#       File "/home/hrm/src/hrm/pretrain.py", line 177, in init_train_state
#         model, optimizers, optimizer_lrs = create_model(config, train_metadata, world_size=world_size)
#                                            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
#       File "/home/hrm/src/hrm/pretrain.py", line 146, in create_model
#         AdamATan2(
#       File "/home/hrm/.venv/lib/python3.12/site-packages/adam_atan2_pytorch/adam_atan2.py", line 28, in __init__
#         assert lr > 0.
#                ^^^^^^^
#     AssertionError
RUN perl -p -i -e 's/lr=0/lr=1e-3/g' ${HRM}/src/hrm/pretrain.py

RUN mkdir -p ${HRM}/.config/wandb ${HRM}/.cache/wandb
RUN echo 'source ${HRM}/.venv/bin/activate' >> ${HRM}/.bashrc
WORKDIR "${HRM}"
