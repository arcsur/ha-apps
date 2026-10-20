"""Main entry point for Wyoming Whistle server."""

import argparse
import asyncio
import logging
import os
from functools import partial

from needle.agent.whistle import Whistle
from wyoming.server import AsyncServer, AsyncTcpServer

from . import __version__
from .handler import WhistleEventHandler

_LOGGER = logging.getLogger(__name__)


async def main() -> None:
    """Run Wyoming Whistle server."""
    parser = argparse.ArgumentParser(description="Wyoming Whistle Server")
    parser.add_argument(
        "--uri",
        default="tcp://0.0.0.0:10300",
        help="Server URI (default: tcp://0.0.0.0:10300)",
    )
    parser.add_argument(
        "--language",
        default=None,
        help="Default language (default: auto)",
    )
    parser.add_argument(
        "--weights",
        default=os.environ.get(
            "NEEDLE_WHISTLE_WEIGHTS", "/usr/share/whistle/whistle.cact"
        ),
        help="Path to whistle.cact weights file",
    )
    parser.add_argument(
        "--zeroconf",
        action="store_true",
        help="Enable Zeroconf mDNS advertisement",
    )
    parser.add_argument(
        "--zeroconf-name",
        default="Wyoming Whistle",
        help="Zeroconf service name (default: Wyoming Whistle)",
    )
    parser.add_argument(
        "--debug",
        action="store_true",
        help="Enable debug logging",
    )
    args = parser.parse_args()

    logging.basicConfig(
        level=logging.DEBUG if args.debug else logging.INFO,
        format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    )

    _LOGGER.info("Starting Wyoming Whistle v%s", __version__)

    if os.path.exists(args.weights):
        os.environ["NEEDLE_WHISTLE_WEIGHTS"] = args.weights
        _LOGGER.info("Using weights: %s", args.weights)

    lib_path = os.environ.get("NEEDLE3_LIB_PATH", "/usr/share/whistle/libneedle.so")
    if os.path.exists(lib_path):
        os.environ["NEEDLE3_LIB_PATH"] = lib_path
        _LOGGER.info("Using engine library: %s", lib_path)

    _LOGGER.info("Loading Whistle model...")
    whistle = Whistle(weights=args.weights if os.path.exists(args.weights) else None)
    lock = asyncio.Lock()
    _LOGGER.info("Whistle model loaded successfully")

    server = AsyncServer.from_uri(args.uri)
    handler_factory = partial(
        WhistleEventHandler,
        whistle,
        lock,
        args.language,
        __version__,
    )

    if args.zeroconf and isinstance(server, AsyncTcpServer):
        try:
            from wyoming.zeroconf import HomeAssistantZeroconf

            zeroconf = HomeAssistantZeroconf(
                name=args.zeroconf_name,
                port=server.port,
            )
            await zeroconf.register_server()
            _LOGGER.info(
                "Zeroconf service '%s' registered on port %d",
                args.zeroconf_name,
                server.port,
            )
        except Exception as err:
            _LOGGER.warning("Could not register Zeroconf service: %s", err)

    _LOGGER.info("Server listening on %s", args.uri)
    await server.run(handler_factory)


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        pass
