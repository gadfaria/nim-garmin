# Nim for Garmin

Connect IQ apps with the visual identity of the Nim launcher. See [SPEC.md](SPEC.md).

## Layout

- `shared/source/NimStyle.mc`: colors, fonts and the centered stacked text layout, shared by every app
- `watchface/`: phase 1 watch face

Each app pulls in the shared module from its `monkey.jungle` (`base.sourcePath = source;../shared/source`).

## Running

1. Install the [Connect IQ SDK Manager](https://developer.garmin.com/connect-iq/sdk/), download the latest SDK and the devices listed in `watchface/manifest.xml`.
2. Install the Monkey C extension for VS Code and run `Monkey C: Generate a Developer Key`.
3. Open `watchface/` in VS Code and run `Monkey C: Build for Device` or start the simulator with `Run App`.

From the command line:

```bash
monkeyc -f watchface/monkey.jungle -d fr255 -o bin/watchface.prg -y ~/.Garmin/developer_key.der
```

```bash
connectiq && monkeydo bin/watchface.prg fr255
```
