# TODO

## PortMaster Distribution

SpruceChat could be listed on [PortMaster](https://portmaster.games/) — an app store for Linux handhelds with ~1,000 ports and 18k+ Discord members. Non-game apps are welcome (KOReader, music players, etc. are already on there).

### What needs to happen

- [ ] **Adapt launch script to PortMaster conventions** — source their `control.txt`, use `$GPTOKEYB` for input mapping, call `pm_finish` on exit, use `$GAMEDIR`/`$CONFDIR` instead of hardcoded paths
- [ ] **Solve Python runtime** — PortMaster doesn't ship Python. Either bundle a minimal Python 3.x runtime, or port the UI to C/SDL2. Bundling a runtime is precedented (KOReader bundles LuaJIT)
- [ ] **Split model for GitHub** — the 409MB model needs to be chunked into 50MB pieces using PortMaster's `tools/build_data.py`
- [ ] **Test on multiple CFWs** — ArkOS, ROCKNIX, muOS, AmberELEC (required for PR acceptance)
- [ ] **Test at multiple resolutions** — 640x480 (required), 480x320, 720x720, 1280x720 (optional)
- [ ] **Package** — create `port.json`, `gameinfo.xml`, screenshot (4:3, min 640x480), license files for all deps (llama.cpp MIT, Qwen Apache 2.0)
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
