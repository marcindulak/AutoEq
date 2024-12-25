# WebApp
WebApp for AutoEq

## Development
Install dependencies
```shell
cd webapp
python -m pip install -U -r requirements.txt
```

Run backend
```shell
uvicorn main:app --reload
```

Run frontend dev server
```shell
cd ui
npm i
npm start
```

Go to `http://localhost:3000`

## Development with docker compose
Needs to be done from root directory, not from webapp
```shell
export BUILDKIT_PROGRESS=plain
docker compose build --build-arg UID=$(id -u) --build-arg GID=$(id -g)
docker compose up --detach --wait
```

Go to `http://localhost:3000`

Stop and remove volumes that store e.g. npm modules and build
```shell
docker compose down --volumes
```

## Build Docker File
Needs to be done from root directory, not from webapp
```shell
docker build -t yourusername/autoeq:latest .
docker push yourusername/autoeq:latest
```

## Run Docker
Data directory needs to be created and mounted. `webapp/create_data.py` creates the directory and necessary files by
packaging target curves and measurements. You need all measurement data available in the `measurements` directory
to do this.

The `data/audio` directory also needs to have all the songs for the player. It's recommended to normalize the volumes across all
your tracks. https://www.loudnesspenalty.com/ helps calculating the required amplification. Use Spotify levels.

Privacy policy (`privacy-policy.html`) and Terms of Service (`terms-of-service.html`) should be placed in `data/legal`.

```
data/
  audio/
    Jennifer Warnes - Bird On a Wire.ogg
  legal/
    privacy-policy.html
    terms-of-service.html
  targets.json
  entries.json
  measurements.json
```

```shell
docker run -d -p 8000:8000 -v /path/to/AutoEq/webapp/data:/app/webapp/data yourusername/autoeq:latest
```
