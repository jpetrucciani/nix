{ pkgs, ... }:
let
  python = (pkgs.python314.withPackages (p: with p;[
    aiocron
    delegator-py
    discordpy
    feedparser
    gamble
    geoip2
    gitpython
    httpx
    paramiko
    pygithub
    python-dotenv
    python-multipart

    # text
    anybadge
    beautifulsoup4
    qrcode
    lxml
    icon-image
    tabulate

    # automation
    playwright

    # ai
    openai
    pdf2image
    qdrant-client
    sentence-transformers
    tokenizers
    transformers

    # data
    numpy
    pandas

    # db
    gspread
    oauth2client
    peewee
    psycopg2
    # pydrive2

    # server
    fastapi
    uvicorn

    # testing
    ptpython
    black
    freezegun
    pytest
    pytest-cov

    # types
    types-freezegun
    types-tabulate
  ])).override { ignoreCollisions = true; };
  environment = pkgs.buildEnv {
    name = "api";
    paths = [ python ];
  };
in
{
  systemd.services.api = {
    wantedBy = [ "multi-user.target" ];
    script = ''
      cd /home/jacobi/dev/api
      ${environment}/bin/uvicorn api.api:API \
        --host 0.0.0.0 \
        --port 10000
    '';
    environment = {
      PLAYWRIGHT_BROWSERS_PATH = pkgs.playwright-driver.browsers.outPath;
      PYTHONUNBUFFERED = "1";
    };
  };
}
