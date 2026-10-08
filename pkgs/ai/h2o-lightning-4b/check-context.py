"""Exercise a patched shim against real vLLM, using an ephemeral loopback HTTP server."""

from __future__ import annotations

import argparse
import importlib.util
import json
import threading
from pathlib import Path
from urllib.error import HTTPError
from urllib.request import Request, urlopen


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--shim", type=Path, required=True)
    parser.add_argument("--config", type=Path, required=True)
    parser.add_argument("--vllm", default="http://127.0.0.1:8000")
    args = parser.parse_args()
    spec = importlib.util.spec_from_file_location("context_check_shim", args.shim)
    if spec is None or spec.loader is None:
        raise ValueError("Cannot load shim")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    contract = module.Contract(json.loads(args.config.read_text()))
    assert contract.max_state_tokens == 0, (
        "Packaged config must not impose a state-only cap"
    )
    shim = module.Shim(contract, module.VLLM(args.vllm, contract.model))
    server = module.Server(("127.0.0.1", 0), module.make_handler(shim))
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    question = {"type": "noul", "instructions": "Is checkout currently unavailable?"}
    checks: list[dict[str, object]] = []

    def request(
        name: str, state: str, questions: dict[str, object], expected: int
    ) -> dict[str, object]:
        body = {"model": contract.model, "state": state, "questions": questions}
        try:
            with urlopen(
                Request(
                    f"http://127.0.0.1:{server.server_address[1]}/v1/systemone",
                    data=json.dumps(body).encode(),
                    headers={"Content-Type": "application/json"},
                ),
                timeout=40,
            ) as response:
                status = response.status
                result = json.load(response)
        except HTTPError as error:
            status = error.code
            result = json.loads(error.read())
        checks.append({"name": name, "status": status, "response": result})
        assert status == expected, checks[-1]
        return result

    try:
        shim.check_backend()
        maximum = shim.max_model_len
        assert isinstance(maximum, int) and maximum > 32001
        request("short", "Checkout is down.", {"outage": question}, 200)
        state = "A routine status check completed successfully. " * 5600
        state += "\nCheckout is now down. Customers cannot place orders."
        count = len(
            shim.v.tokenize(contract.question_prompt(state, question, "outage")[0])
        )
        assert 32000 < count < maximum
        result = request("above-32k", state, {"outage": question}, 200)
        assert result["usage"]["input_tokens"] == count, (
            "State was changed before inference"
        )
        words = maximum - 100
        for _ in range(4):
            state = " ok" * words
            count = len(
                shim.v.tokenize(contract.question_prompt(state, question, "outage")[0])
            )
            if count == maximum - 1:
                break
            words += maximum - 1 - count
        assert count == maximum - 1, "Could not construct an exact boundary request"
        result = request(
            "exact-context-including-answer", state, {"outage": question}, 200
        )
        assert result["usage"]["input_tokens"] == maximum - 1
        overflow = state + " ok"
        count = len(
            shim.v.tokenize(contract.question_prompt(overflow, question, "outage")[0])
        )
        assert count == maximum
        result = request("one-token-over-context", overflow, {"outage": question}, 422)
        assert f"{maximum} input tokens plus 1 answer token" in result["detail"]
        oversized = {"type": "noul", "instructions": " ok" * maximum}
        result = request(
            "oversized-question-before-inference",
            "Short state",
            {"fits": question, "too_long": oversized},
            422,
        )
        assert "too_long" in result["detail"]
        request(
            "multi-question",
            "Checkout is down.",
            {"first": question, "second": question},
            200,
        )
        contract.max_state_tokens = 100
        result = request("explicit-state-cap", " ok" * 101, {"outage": question}, 422)
        assert "maximum is 100" in result["detail"]
        print(
            json.dumps(
                {"max_model_len": maximum, "checks": checks, "passed": True}, indent=2
            )
        )
    finally:
        server.shutdown()
        server.server_close()
        shim.pool.shutdown()


if __name__ == "__main__":
    main()
