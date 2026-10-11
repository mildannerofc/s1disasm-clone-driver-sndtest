; ===========================================================================
; Sonic 1 / Sonic 2 Clone Driver Sound Test configuration
; ---------------------------------------------------------------------------
; Assembler selector requested for this module:
;   ASM68K = 1
;   AS     = 0 (default)
;
; IMPORTANT: this disassembly's main source, macros and build system are AS.
; The selector below selects the macro-argument syntax used by the Sound Test
; entry table. Setting it to ASM68K does NOT convert the rest of this AS-based
; disassembly into an ASM68K project.
; ===========================================================================

SoundTest_Assembler_AS      = 0
SoundTest_Assembler_ASM68K  = 1
SoundTest_Assembler         = SoundTest_Assembler_AS ; 0 = AS, 1 = ASM68K

; 1 = show music and SFX entries; 0 = show music only.
SoundTest_EnableSFX         = 1

; Clone Driver uses low IDs: music $01-$13, SFX $20-$4F.
; These boundaries are derived from the driver's Sound IDs definitions.
SoundTest_MusicID_First     = bgm__First
SoundTest_MusicID_Last      = bgm__End
SoundTest_InitialID         = bgm__First
SoundTest_ReturnMode        = $04 ; id_Title
SoundTest_SFXID_First       = sfx__First
SoundTest_SFXID_Last        = sfx__End

; A/B moves by this many table entries; Left/Right moves by one.
SoundTest_SelectionStride   = 16

; Entry record: ID byte, type byte, reserved word, name pointer long.
SoundTest_EntryRecordSize   = 8
SoundTest_EntryType_Music   = 0
SoundTest_EntryType_SFX     = 1
SoundTest_MusicCount        = (SoundTest_MusicTable_End-SoundTest_MusicTable)/SoundTest_EntryRecordSize
SoundTest_SFXCount          = (SoundTest_SFXTable_End-SoundTest_SFXTable)/SoundTest_EntryRecordSize
SoundTest_SelectionCount    = SoundTest_MusicCount+(SoundTest_EnableSFX*SoundTest_SFXCount)
SoundTest_SelectionLast     = SoundTest_SelectionCount-1

; Full MegaPCM DAC ID span. The runtime lookup uses the same conditional
; sample-set flags as MegaPCM_DAC_Table; disabled/missing slots show UNUSED.
SoundTest_DACSample_First   = $81
SoundTest_DACSample_Last    = $E0
SoundTest_DACSampleEntrySize = 8
SoundTest_ShowDACSampleRate = 0

; Graphics / layout.
SoundTest_ArtTile            = $200
SoundTest_TilesPerChar       = 2
SoundTest_FontCharCount      = 40
SoundTest_FontTileCount      = SoundTest_TilesPerChar*SoundTest_FontCharCount
SoundTest_IconTile           = SoundTest_ArtTile+SoundTest_FontTileCount
SoundTest_ArtTileCount       = SoundTest_FontTileCount+3
SoundTest_ArtDecompressedSize = SoundTest_ArtTileCount*tile_size

SoundTest_TitleX            = 4
SoundTest_TitleY            = 1
SoundTest_MusicLabelX       = 4
SoundTest_MusicLabelY       = 4
SoundTest_MusicID_X         = 10
SoundTest_MusicNameX        = 14
SoundTest_HelpX             = 4
SoundTest_HelpY             = 6
SoundTest_StartMenuX        = 27
SoundTest_StartMenuY        = 6
SoundTest_ChannelX           = 4
SoundTest_IconX              = 1
SoundTest_NoteX              = 18
SoundTest_FreqX              = 24
SoundTest_DACNameX           = SoundTest_NoteX
SoundTest_DACRateX           = 30
SoundTest_ChannelY           = 8
SoundTest_ChannelStepY       = 2
SoundTest_FM1Y               = SoundTest_ChannelY
SoundTest_FM2Y               = SoundTest_FM1Y+(SoundTest_ChannelStepY*1)
SoundTest_FM3Y               = SoundTest_FM1Y+(SoundTest_ChannelStepY*2)
SoundTest_FM4Y               = SoundTest_FM1Y+(SoundTest_ChannelStepY*3)
SoundTest_FM5Y               = SoundTest_FM1Y+(SoundTest_ChannelStepY*4)
SoundTest_FM6Y               = SoundTest_FM1Y+(SoundTest_ChannelStepY*5)
SoundTest_PSG1Y              = SoundTest_FM1Y+(SoundTest_ChannelStepY*6)
SoundTest_PSG2Y              = SoundTest_FM1Y+(SoundTest_ChannelStepY*7)
SoundTest_NoiseY             = SoundTest_FM1Y+(SoundTest_ChannelStepY*8)

; Clone Driver v2 frequency tables have 96 FM values and 84 PSG values.
; No *_End labels are emitted by this particular driver revision.
SoundTest_FMFrequencyCount  = 96
SoundTest_PSGFrequencyCount = 84
SoundTest_PaletteLine        = 0
SoundTest_FMOctaveBias        = 0
SoundTest_PSGOctaveBias       = 0
SoundTest_NoteWidth           = 3
SoundTest_FrequencyWidth      = 4
SoundTest_ShowFrequency       = 1
