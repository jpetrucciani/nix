from typing import Annotated, Literal

from pydantic import BaseModel, ConfigDict, Field, StringConstraints, model_validator

ModelName = Literal["small-sfx", "small-music", "medium"]
AudioFormat = Literal["wav", "flac", "ogg"]
ArtifactId = Annotated[str, StringConstraints(pattern=r"^[0-9a-f]{32}\.[0-9]{1,2}$")]
MEDIA_TYPES: dict[AudioFormat, str] = {
    "wav": "audio/wav",
    "flac": "audio/flac",
    "ogg": "audio/ogg",
}


class Processing(BaseModel):
    model_config = ConfigDict(extra="forbid", allow_inf_nan=False)

    format: AudioFormat = "wav"
    sample_rate: int | None = Field(default=None, ge=8000, le=192000)
    channels: Literal[1, 2] | None = None
    trim_silence: bool = False
    peak_normalize: bool = False
    remove_dc: bool = False
    fade_in: float = Field(default=0, ge=0, le=10)
    fade_out: float = Field(default=0, ge=0, le=10)


class Generation(BaseModel):
    model_config = ConfigDict(
        extra="forbid", allow_inf_nan=False, str_strip_whitespace=True
    )

    model: ModelName = "small-sfx"
    prompt: str = Field(min_length=1, max_length=4096)
    duration: float = Field(default=2, ge=0.1, le=120)
    steps: int = Field(default=8, ge=1, le=100)
    seed: int | None = Field(default=None, ge=0, lt=2**63)
    variations: int = Field(default=1, ge=1, le=16)
    processing: Processing = Field(default_factory=Processing)
    response: Literal["manifest", "audio"] = "manifest"

    @model_validator(mode="after")
    def validate_response(self) -> "Generation":
        if self.response == "audio" and self.variations != 1:
            raise ValueError("audio response requires exactly one variation")
        return self


class Edit(Generation):
    init_noise_level: float = Field(default=0.7, gt=0, le=1)


class Inpaint(Generation):
    start: float = Field(ge=0)
    end: float = Field(gt=0)

    @model_validator(mode="after")
    def validate_region(self) -> "Inpaint":
        if not self.start < self.end <= self.duration:
            raise ValueError("inpaint region must satisfy start < end <= duration")
        return self


class Artifact(BaseModel):
    id: ArtifactId
    download_url: str
    original_url: str
    format: AudioFormat
    frames: int
    sample_rate: int
    channels: int
    original_frames: int
    original_sample_rate: int
    seed: int
    batch_index: int
    checkpoint_revision: str
    request: Edit | Inpaint | Generation
    reference_sha256: str | None
    load_seconds: float
    inference_seconds: float
    peak_vram_bytes: int
    resident_vram_bytes: int


class Manifest(BaseModel):
    artifacts: list[Artifact]
