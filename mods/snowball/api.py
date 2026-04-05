#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.13,<3.14"
# dependencies = [
#   "fastapi",
#   "uvicorn",
# ]
# ///

from __future__ import annotations

import os

from fastapi import FastAPI

app = FastAPI()


@app.get("/")
def read_root() -> dict[str, str]:
    return {"message": "Hello World"}


@app.get("/items/{item_id}")
def read_item(item_id: int, q: str | None = None) -> dict[str, int | str | None]:
    return {"item_id": item_id, "q": q}


def main() -> None:
    import uvicorn

    uvicorn.run(
        app,
        host=os.environ.get("SNOWBALL_API_HOST", "0.0.0.0"),
        port=int(os.environ.get("SNOWBALL_API_PORT", "8000")),
    )


if __name__ == "__main__":
    main()
