# TODO

## PortMaster Distribution

SpruceChat could be listed on [PortMaster](https://portmaster.games/) — an app store for Linux handhelds with ~1,000 ports and 18k+ Discord members. Non-game apps are welcome (KOReader, music players, etc. are already on there).

### What needs to happen

- [x] **Adapt launch script to PortMaster conventions** — `portmaster/Spruce Chat.sh`
- [x] **Solve Python runtime** — bundled via astral-sh/python-build-standalone (aarch64, 3.11, stripped)
- [x] **Package** — `port.json`, `gameinfo.xml`, README.md, licenses/ written; CI pulls system-lib copyrights
- [x] **Refactor chat.py for PortMaster** — SDL GameController input path + font fallbacks + `$XDG_DATA_HOME` support (spruceOS behavior preserved)
- [x] **CI workflow** — `.github/workflows/build.yml` has a `portmaster` job that reuses the universal aarch64 build and produces `spruce_chat.zip`
- [ ] **Trigger CI build** — run the workflow and confirm `SpruceChat-PortMaster` artifact builds cleanly
- [ ] **Smoke-test on an actual device** — install the zip to a PortMaster-supported aarch64 handheld and confirm it boots + accepts input
- [ ] **Split model for PR** — in the port dir submitted to PortMaster-New, split the ~409MB model into `.part.NN` pieces (≤50MB each, see `tools/build_data.py` `DEFAULT_CHUNK_SIZE`). PortMaster's build pipeline reassembles at release time; no runtime assembly (removed in e988e6d). Our own CI still ships the full file.
- [ ] **Test on multiple CFWs** — ArkOS, ROCKNIX, muOS, AmberELEC (required for PR acceptance)
- [ ] **Test at multiple resolutions** — chat.py now auto-detects via `SDL_GetCurrentDisplayMode` when `SCREEN_WIDTH`/`HEIGHT` env vars aren't set. Confirm layout at 480×320, 640×480, 720×720, 1280×720+
- [ ] **Join PortMaster Discord** — post in `#testing-n-dev` to create a testing thread. PRs without testing docs are rejected
- [ ] **Submit PR** to [PortsMaster/PortMaster-New](https://github.com/PortsMaster/PortMaster-New)

### Target devices

The aarch64 universal build already covers many PortMaster-supported devices:
- Anbernic RG35XX Plus/H/SP (H700)
- Anbernic RG353 series (RK3566)
- TrimUI Smart Pro / Brick (A133Plus)
- Potentially Steam Deck (x86_64 — would need a separate build)

### Resources

- [PortMaster packaging guide](https://portmaster.games/packaging.html)
- [PortMaster porting guide](https://portmaster.games/porting.html)
- [PortMaster Discord](https://discord.com/invite/FDg86YtReQ)
- [port.json generator](https://portmaster.games/port-json.html)

## Other ideas

- [ ] Smaller/faster model options (SmolLM2-135M for snappier responses on slow devices)
- [ ] WiFi chat — llama-server already listens on `0.0.0.0:8086`, document using a browser from another device on the same network
- [ ] System prompt customization (let users edit personality via a config file)
