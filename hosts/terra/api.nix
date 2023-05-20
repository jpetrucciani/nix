{ pkgs, ... }:
let
  environment = pkgs.buildEnv {
    name = "api";
    paths = [
      (pkgs.python311.withPackages (p: with p;[
        aiocron
        delegator-py
        discordpy
        feedparser
        geoip2
        gamble
        httpx
        paramiko
        requests
        GitPython
        praw
        tweepy
        python-dotenv
        python-multipart

        # text
        anybadge
        beautifulsoup4
        qrcode
        tabulate
        # stylecloud
        icon-image

        # automation
        playwright

        # ai
        llama-cpp-python
        whisper-cpp-py

        # data
        numpy
        pandas

        # db
        gspread
        oauth2client
        peewee
        psycopg2
        pydrive2

        # server
        fastapi
        uvicorn

        # testing
        black
        freezegun
        pytest
        pytest-cov
        mypy

        # types
        types-freezegun
        types-requests
        types-tabulate
      ]))
    ];
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
    };
  };
}
