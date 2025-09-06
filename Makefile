HRM_SUDOKU_DATA := /tmp/hrm-volumes/data/sudoku
HRM_WANDB_DATA := /tmp/hrm-volumes/data/wandb
HRM_WANDB_CONFIG := /tmp/hrm-volumes/wandb-config
HRM_WANDB_CACHE := /tmp/hrm-volumes/wandb-cache

all:

build:
	docker build -t hrm/docker -f ./Dockerfile .

run: build download-sudoku-data
	mkdir -p ${HRM_SUDOKU_DATA}
	mkdir -p ${HRM_WANDB_DATA}
	mkdir -p ${HRM_WANDB_CONFIG}
	mkdir -p ${HRM_WANDB_CACHE}
	docker \
		container run \
			-it --rm \
			--gpus all \
			-v ${HRM_SUDOKU_DATA}:/home/hrm/src/hrm/data \
			-v ${HRM_WANDB_DATA}:/home/hrm/src/hrm/wandb \
			-v ${HRM_WANDB_CONFIG}:/home/hrm/.config/wandb \
			-v ${HRM_WANDB_CACHE}:/home/hrm/.cache/wandb \
			-w /home/hrm/src/hrm \
			hrm/docker \
			/bin/bash

download-sudoku-data: build ${HRM_SUDOKU_DATA}/sudoku-extreme-full/identifiers.json ${HRM_SUDOKU_DATA}/sudoku-extreme-1k-aug-1000/identifiers.json

${HRM_SUDOKU_DATA}/sudoku-extreme-full/identifiers.json:
	mkdir -p ${HRM_SUDOKU_DATA}
	docker container run -it --rm -v ${HRM_SUDOKU_DATA}:/home/hrm/src/hrm/data -w /home/hrm/src/hrm hrm/docker python3 ./dataset/build_sudoku_dataset.py

${HRM_SUDOKU_DATA}/sudoku-extreme-1k-aug-1000/identifiers.json:
	mkdir -p ${HRM_SUDOKU_DATA}
	docker container run -it --rm -v ${HRM_SUDOKU_DATA}:/home/hrm/src/hrm/data -w /home/hrm/src/hrm hrm/docker python3 ./dataset/build_sudoku_dataset.py --output-dir data/sudoku-extreme-1k-aug-1000 --subsample-size 1000 --num-aug 1000
