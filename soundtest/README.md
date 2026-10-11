# Sonic 1 Clone Driver Sound Test

This module adds the Chaotix-inspired Sound Test to the AS-based Sonic 1 disassembly.

## Assembler selector

Edit `soundtest/config/Sound Test Config.asm`:

```asm
SoundTest_Assembler_AS      = 0
SoundTest_Assembler_ASM68K  = 1
SoundTest_Assembler         = SoundTest_Assembler_AS
```

The default is AS (`0`). The selector changes the macro-argument syntax of the entry table. The main disassembly, `MacroSetup.asm`, build scripts and many existing source files are AS-specific; setting this selector to `1` alone does not port the whole project to ASM68K.

## Clone Driver IDs

Music entries use the Clone Driver IDs from `Sound/Sound IDs.asm` (`$01-$13`), not the stock Sonic 1 `$81-$93` values. The SFX list likewise uses the driver's symbol IDs (`$20-$4F`). IDs are taken from the driver's symbols in the entry table, so they stay synchronized with its sound index.

The channel monitor reads `Clone_Driver_RAM` and `SMPS_Track` fields from Clone Driver v2. The DAC sample-name list reflects the enabled Sonic 1 sample set in `Sound/Settings.asm`; disabled sample-set slots display `UNUSED`.

## Controls

- A: advance 16 entries
- B: go back 16 entries
- Left / Right: previous / next entry (does not play)
- C: play selected entry
- Start: return to title menu
