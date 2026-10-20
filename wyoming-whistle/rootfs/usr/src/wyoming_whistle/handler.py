"""Wyoming event handler for Whistle."""

import array
import asyncio
import logging
from typing import Optional

from wyoming.asr import Transcribe, Transcript
from wyoming.audio import AudioChunk, AudioChunkConverter, AudioStart, AudioStop
from wyoming.event import Event
from wyoming.info import AsrModel, AsrProgram, Attribution, Describe, Info
from wyoming.ping import Ping, Pong
from wyoming.server import AsyncEventHandler

_LOGGER = logging.getLogger(__name__)

LANGUAGES = ["en", "de", "fr", "es", "it", "nl", "pl"]


class WhistleEventHandler(AsyncEventHandler):
    """Event handler for Wyoming clients."""

    def __init__(
        self,
        whistle,
        lock: asyncio.Lock,
        default_language: Optional[str],
        version: str,
        *args,
        **kwargs,
    ) -> None:
        super().__init__(*args, **kwargs)
        self.whistle = whistle
        self.lock = lock
        self.default_language = default_language
        self.version = version
        self.converter: Optional[AudioChunkConverter] = None
        self.audio_bytes = bytearray()
        self.language: Optional[str] = (
            default_language if default_language and default_language != "auto" else None
        )

    async def handle_event(self, event: Event) -> bool:
        if Describe.is_type(event.type):
            info = Info(
                asr=[
                    AsrProgram(
                        name="whistle",
                        description="Cactus Whistle speech-to-text",
                        attribution=Attribution(
                            name="Cactus Compute",
                            url="https://cactuscompute.com",
                        ),
                        installed=True,
                        version=self.version,
                        models=[
                            AsrModel(
                                name="whistle",
                                description="Whistle 16.9MB offline STT model",
                                attribution=Attribution(
                                    name="Cactus Compute",
                                    url="https://cactuscompute.com",
                                ),
                                installed=True,
                                version=self.version,
                                languages=LANGUAGES,
                            )
                        ],
                        supports_transcript_streaming=False,
                    )
                ]
            )
            await self.write_event(info.event())
            _LOGGER.debug("Sent info to client")
            return True

        if Transcribe.is_type(event.type):
            transcribe = Transcribe.from_event(event)
            if transcribe.language:
                self.language = transcribe.language
            elif self.default_language and self.default_language != "auto":
                self.language = self.default_language
            else:
                self.language = None
            _LOGGER.debug("Transcribe request received, language: %s", self.language)
            return True

        if AudioStart.is_type(event.type):
            self.converter = AudioChunkConverter(rate=16000, width=2, channels=1)
            self.audio_bytes.clear()
            _LOGGER.debug("Audio stream started")
            return True

        if AudioChunk.is_type(event.type):
            chunk = AudioChunk.from_event(event)
            if self.converter is not None:
                chunk = self.converter.convert(chunk)
            self.audio_bytes.extend(chunk.audio)
            return True

        if AudioStop.is_type(event.type):
            raw_bytes = bytes(self.audio_bytes)
            self.audio_bytes.clear()
            _LOGGER.debug("Audio stream stopped, received %d bytes", len(raw_bytes))

            if not raw_bytes:
                await self.write_event(
                    Transcript(text="", language=self.language).event()
                )
                return True

            int16_samples = array.array("h")
            int16_samples.frombytes(raw_bytes)
            float_samples = array.array("f", (s / 32768.0 for s in int16_samples))

            async with self.lock:
                result = await asyncio.to_thread(
                    self.whistle.transcribe,
                    float_samples,
                    language=self.language,
                    word_timestamps=False,
                )

            text = (result.get("text") or "").strip()
            detected_lang = result.get("language") or self.language
            _LOGGER.info("Transcription result (%s): '%s'", detected_lang, text)
            await self.write_event(
                Transcript(text=text, language=detected_lang).event()
            )
            return True

        if Ping.is_type(event.type):
            ping = Ping.from_event(event)
            await self.write_event(Pong(text=ping.text).event())
            return True

        return True
