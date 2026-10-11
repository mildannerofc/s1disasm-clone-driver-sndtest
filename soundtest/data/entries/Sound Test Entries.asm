; ===========================================================================
; Sonic 1 Sound Test - unified entry table
; ---------------------------------------------------------------------------
; Record format (8 bytes):
;   +0  sound ID
;   +1  entry type (music/SFX)
;   +2  reserved
;   +4  long pointer to display name
;
; ADDING MUSIC:
;   1) Add a SoundTest_MusicEntry line to the MUSIC section.
;   2) Define its SoundTest_Name_* string below.
;   3) Update SoundTest_MusicID_First/Last in soundtest/config/ if the
;      documented ID range changes.
;
; Counts are derived automatically from the table markers.
; ===========================================================================

; The project defaults to AS. The ASM68K form is kept available for
; migrating this module, but the surrounding disassembly is AS-specific.
	if SoundTest_Assembler=SoundTest_Assembler_AS
SoundTest_Entry: macro entryID,entryType,entryName
        dc.b entryID,entryType
        dc.w 0
        dc.l entryName
        endm
	else
SoundTest_Entry: macro entryID,entryType,entryName
        dc.b \entryID,\entryType
        dc.w 0
        dc.l \entryName
        endm
	endif

SoundTest_MusicEntry: macro entryID,entryName
        SoundTest_Entry entryID,SoundTest_EntryType_Music,entryName
        endm

SoundTest_SFXEntry: macro entryID,entryName
        SoundTest_Entry entryID,SoundTest_EntryType_SFX,entryName
        endm

SoundTest_SelectionTable:

SoundTest_MusicTable:
        SoundTest_MusicEntry bgm_GHZ,        SoundTest_Name_GHZ
        SoundTest_MusicEntry bgm_LZ,         SoundTest_Name_LZ
        SoundTest_MusicEntry bgm_MZ,         SoundTest_Name_MZ
        SoundTest_MusicEntry bgm_SLZ,        SoundTest_Name_SLZ
        SoundTest_MusicEntry bgm_SYZ,        SoundTest_Name_SYZ
        SoundTest_MusicEntry bgm_SBZ,        SoundTest_Name_SBZ
        SoundTest_MusicEntry bgm_Invincible, SoundTest_Name_INV
        SoundTest_MusicEntry bgm_ExtraLife,  SoundTest_Name_1UP
        SoundTest_MusicEntry bgm_SS,         SoundTest_Name_SS
        SoundTest_MusicEntry bgm_Title,      SoundTest_Name_TITLE
        SoundTest_MusicEntry bgm_Ending,     SoundTest_Name_END
        SoundTest_MusicEntry bgm_Boss,       SoundTest_Name_BOSS
        SoundTest_MusicEntry bgm_FZ,         SoundTest_Name_FZ
        SoundTest_MusicEntry bgm_GotThrough, SoundTest_Name_GOAL
        SoundTest_MusicEntry bgm_GameOver,   SoundTest_Name_GAMEOVER
        SoundTest_MusicEntry bgm_Continue,   SoundTest_Name_CONT
        SoundTest_MusicEntry bgm_Credits,    SoundTest_Name_CREDITS
        SoundTest_MusicEntry bgm_Drowning,   SoundTest_Name_DROWN
        SoundTest_MusicEntry bgm_Emerald,    SoundTest_Name_EMERALD
SoundTest_MusicTable_End:

SoundTest_SFXTable:
	if SoundTest_EnableSFX=1
        SoundTest_SFXEntry sfx_Jump,         SoundTest_SFX_A0
        SoundTest_SFXEntry sfx_Lamppost,     SoundTest_SFX_A1
        SoundTest_SFXEntry sfx_A2,           SoundTest_SFX_A2
        SoundTest_SFXEntry sfx_Death,        SoundTest_SFX_A3
        SoundTest_SFXEntry sfx_Skid,         SoundTest_SFX_A4
        SoundTest_SFXEntry sfx_A5,           SoundTest_SFX_A5
        SoundTest_SFXEntry sfx_HitSpikes,    SoundTest_SFX_A6
        SoundTest_SFXEntry sfx_Push,         SoundTest_SFX_A7
        SoundTest_SFXEntry sfx_SSGoal,       SoundTest_SFX_A8
        SoundTest_SFXEntry sfx_SSItem,       SoundTest_SFX_A9
        SoundTest_SFXEntry sfx_Splash,       SoundTest_SFX_AA
        SoundTest_SFXEntry sfx_AB,           SoundTest_SFX_AB
        SoundTest_SFXEntry sfx_HitBoss,      SoundTest_SFX_AC
        SoundTest_SFXEntry sfx_Bubble,       SoundTest_SFX_AD
        SoundTest_SFXEntry sfx_Fireball,     SoundTest_SFX_AE
        SoundTest_SFXEntry sfx_Shield,       SoundTest_SFX_AF
        SoundTest_SFXEntry sfx_Saw,          SoundTest_SFX_B0
        SoundTest_SFXEntry sfx_Electric,     SoundTest_SFX_B1
        SoundTest_SFXEntry sfx_Drown,        SoundTest_SFX_B2
        SoundTest_SFXEntry sfx_Flamethrower, SoundTest_SFX_B3
        SoundTest_SFXEntry sfx_Bumper,       SoundTest_SFX_B4
        SoundTest_SFXEntry sfx_Ring,         SoundTest_SFX_B5
        SoundTest_SFXEntry sfx_SpikesMove,   SoundTest_SFX_B6
        SoundTest_SFXEntry sfx_Rumbling,     SoundTest_SFX_B7
        SoundTest_SFXEntry sfx_B8,            SoundTest_SFX_B8
        SoundTest_SFXEntry sfx_Collapse,     SoundTest_SFX_B9
        SoundTest_SFXEntry sfx_SSGlass,       SoundTest_SFX_BA
        SoundTest_SFXEntry sfx_Door,          SoundTest_SFX_BB
        SoundTest_SFXEntry sfx_Teleport,      SoundTest_SFX_BC
        SoundTest_SFXEntry sfx_ChainStomp,    SoundTest_SFX_BD
        SoundTest_SFXEntry sfx_Roll,          SoundTest_SFX_BE
        SoundTest_SFXEntry sfx_Continue,      SoundTest_SFX_BF
        SoundTest_SFXEntry sfx_Basaran,       SoundTest_SFX_C0
        SoundTest_SFXEntry sfx_BreakItem,     SoundTest_SFX_C1
        SoundTest_SFXEntry sfx_Warning,       SoundTest_SFX_C2
        SoundTest_SFXEntry sfx_GiantRing,     SoundTest_SFX_C3
        SoundTest_SFXEntry sfx_Bomb,          SoundTest_SFX_C4
        SoundTest_SFXEntry sfx_Cash,          SoundTest_SFX_C5
        SoundTest_SFXEntry sfx_RingLoss,      SoundTest_SFX_C6
        SoundTest_SFXEntry sfx_ChainRise,     SoundTest_SFX_C7
        SoundTest_SFXEntry sfx_Burning,       SoundTest_SFX_C8
        SoundTest_SFXEntry sfx_Bonus,         SoundTest_SFX_C9
        SoundTest_SFXEntry sfx_EnterSS,       SoundTest_SFX_CA
        SoundTest_SFXEntry sfx_WallSmash,     SoundTest_SFX_CB
        SoundTest_SFXEntry sfx_Spring,        SoundTest_SFX_CC
        SoundTest_SFXEntry sfx_Switch,        SoundTest_SFX_CD
        SoundTest_SFXEntry sfx_RingLeft,      SoundTest_SFX_CE
        SoundTest_SFXEntry sfx_Signpost,      SoundTest_SFX_CF
	endif
SoundTest_SFXTable_End:

SoundTest_SelectionTable_End:

; ---------------------------------------------------------------------------
; Display names
; ---------------------------------------------------------------------------
SoundTest_Name_GHZ:      dc.b "GREEN HILL",0
SoundTest_Name_LZ:       dc.b "LABYRINTH",0
SoundTest_Name_MZ:       dc.b "MARBLE ZONE",0
SoundTest_Name_SLZ:      dc.b "STAR LIGHT",0
SoundTest_Name_SYZ:      dc.b "SPRING YARD",0
SoundTest_Name_SBZ:      dc.b "SCRAP BRAIN",0
SoundTest_Name_INV:      dc.b "INVINCIBLE",0
SoundTest_Name_1UP:      dc.b "EXTRA LIFE",0
SoundTest_Name_SS:       dc.b "SPECIAL STAGE",0
SoundTest_Name_TITLE:    dc.b "TITLE",0
SoundTest_Name_END:      dc.b "ENDING",0
SoundTest_Name_BOSS:     dc.b "BOSS",0
SoundTest_Name_FZ:       dc.b "FINAL ZONE",0
SoundTest_Name_GOAL:     dc.b "STAGE CLEAR",0
SoundTest_Name_GAMEOVER: dc.b "GAME OVER",0
SoundTest_Name_CONT:     dc.b "CONTINUE",0
SoundTest_Name_CREDITS:  dc.b "CREDITS",0
SoundTest_Name_DROWN:    dc.b "DROWNING",0
SoundTest_Name_EMERALD:  dc.b "EMERALD",0

; ---------------------------------------------------------------------------
; Sound effect display names (Clone Driver IDs $20-$4F)
; ---------------------------------------------------------------------------
SoundTest_SFX_A0: dc.b "JUMP",0
SoundTest_SFX_A1: dc.b "LAMPPOST",0
SoundTest_SFX_A2: dc.b "SFX A2",0
SoundTest_SFX_A3: dc.b "DEATH",0
SoundTest_SFX_A4: dc.b "SKID",0
SoundTest_SFX_A5: dc.b "SFX A5",0
SoundTest_SFX_A6: dc.b "HIT SPIKES",0
SoundTest_SFX_A7: dc.b "PUSH BLOCK",0
SoundTest_SFX_A8: dc.b "SS GOAL",0
SoundTest_SFX_A9: dc.b "SS ITEM",0
SoundTest_SFX_AA: dc.b "SPLASH",0
SoundTest_SFX_AB: dc.b "SFX AB",0
SoundTest_SFX_AC: dc.b "HIT BOSS",0
SoundTest_SFX_AD: dc.b "BUBBLE",0
SoundTest_SFX_AE: dc.b "FIREBALL",0
SoundTest_SFX_AF: dc.b "SHIELD",0
SoundTest_SFX_B0: dc.b "SAW",0
SoundTest_SFX_B1: dc.b "ELECTRIC",0
SoundTest_SFX_B2: dc.b "DROWN",0
SoundTest_SFX_B3: dc.b "FLAMETHROWER",0
SoundTest_SFX_B4: dc.b "BUMPER",0
SoundTest_SFX_B5: dc.b "RING",0
SoundTest_SFX_B6: dc.b "SPIKES MOVE",0
SoundTest_SFX_B7: dc.b "RUMBLING",0
SoundTest_SFX_B8: dc.b "SFX B8",0
SoundTest_SFX_B9: dc.b "COLLAPSE",0
SoundTest_SFX_BA: dc.b "SS GLASS",0
SoundTest_SFX_BB: dc.b "DOOR",0
SoundTest_SFX_BC: dc.b "TELEPORT",0
SoundTest_SFX_BD: dc.b "CHAIN STOMP",0
SoundTest_SFX_BE: dc.b "ROLL",0
SoundTest_SFX_BF: dc.b "CONTINUE",0
SoundTest_SFX_C0: dc.b "BASARAN",0
SoundTest_SFX_C1: dc.b "BREAK ITEM",0
SoundTest_SFX_C2: dc.b "WARNING",0
SoundTest_SFX_C3: dc.b "GIANT RING",0
SoundTest_SFX_C4: dc.b "BOMB",0
SoundTest_SFX_C5: dc.b "CASH REGISTER",0
SoundTest_SFX_C6: dc.b "RING LOSS",0
SoundTest_SFX_C7: dc.b "CHAIN RISE",0
SoundTest_SFX_C8: dc.b "BURNING",0
SoundTest_SFX_C9: dc.b "BONUS",0
SoundTest_SFX_CA: dc.b "ENTER SPECIAL STAGE",0
SoundTest_SFX_CB: dc.b "WALL SMASH",0
SoundTest_SFX_CC: dc.b "SPRING",0
SoundTest_SFX_CD: dc.b "SWITCH",0
SoundTest_SFX_CE: dc.b "RING LEFT",0
SoundTest_SFX_CF: dc.b "SIGNPOST",0
