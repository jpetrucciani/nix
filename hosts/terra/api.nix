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
        gamble
        geoip2
        GitPython
        httpx
        paramiko
        praw
        pygithub
        python-dotenv
        python-multipart
        requests
        transformers
        tweepy

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
        whisper-cpp-python

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
