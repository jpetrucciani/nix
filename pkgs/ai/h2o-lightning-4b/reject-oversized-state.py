"""Patch the pinned shim to preserve state and preflight full text context."""

import sys
from pathlib import Path


def main() -> None:
    source = Path(sys.argv[1]).read_text()
    start = source.index("    def truncate_state(self, text):\n")
    end = source.index("    def one(self, prompt, labels):\n", start)
    expected = 'return self.v.detokenize(ids[:half]) + "\\n...\\n" + self.v.detokenize(ids[-half:])'
    if expected not in source[start:end] or source.count("self.truncate_state(") != 2:
        raise SystemExit("Upstream state handling changed; review the rejection patch")
    replacement = '''    def validate_state(self, text):
        """Reject oversized state instead of silently classifying a partial record."""
        maximum = self.c.max_state_tokens
        if maximum and len(text.encode("utf-8", "ignore")) > maximum:
            count = len(self.v.tokenize(text))
            if count > maximum:
                raise Unprocessable(f"state requires {count} tokens; maximum is {maximum}; split or shorten the input")
        return text

    def validate_context(self, work, tokens):
        """Reserve one answer token and check every field before submitting inference."""
        maximum = self.max_model_len
        if not isinstance(maximum, int) or isinstance(maximum, bool) or maximum < 2:
            raise UpstreamError("vLLM did not report a usable max_model_len", 503)
        for field, ids in zip(work, tokens):
            count = len(ids)
            if count + 1 > maximum:
                raise Unprocessable(f"question {field[0]!r} requires {count} input tokens plus 1 answer token; maximum context is {maximum}; split or shorten the input")

'''
    source = (source[:start] + replacement + source[end:]).replace(
        "self.truncate_state(", "self.validate_state("
    )
    text_start = source.index("    def decide(self, body):\n")
    text_end = source.index("    def check_chat(self):\n", text_start)
    text_path = source[text_start:text_end]
    preflight = """        tokens = [self.v.tokenize(w[4]) for w in work]
        self.validate_context(work, tokens)
        shared = 0
"""
    if text_path.count("        shared = 0\n") != 1:
        raise SystemExit(
            "Upstream text request planning changed; review context preflight"
        )
    text_path = text_path.replace("        shared = 0\n", preflight, 1)
    old = "            toks = [self.pool.submit(self.v.tokenize, w[4]) for w in work]\n"
    if text_path.count(old) != 1:
        raise SystemExit("Upstream token accounting changed; review context preflight")
    text_path = text_path.replace(old, "")
    old = "shared = common_prefix_len([f.result() for f in toks])"
    if text_path.count(old) != 1:
        raise SystemExit("Upstream prefix accounting changed; review context preflight")
    text_path = text_path.replace(old, "shared = common_prefix_len(tokens)")
    source = source[:text_start] + text_path + source[text_end:]
    compile(source, "h2o_lightning_shim.py", "exec")
    Path(sys.argv[2]).write_text(source)


if __name__ == "__main__":
    main()
